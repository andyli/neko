import haxe.crypto.Sha256;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;
using StringTools;

class Build {
    static function win32Url(version:String)
        return 'https://github.com/HaxeFoundation/neko/releases/download/v${version.replace(".", "-")}/neko-$version-win.zip';
    static function win64Url(version:String)
        return 'https://github.com/HaxeFoundation/neko/releases/download/v${version.replace(".", "-")}/neko-$version-win64.zip';

    static function cmd(cmd:String, args:Array<String>):Void {
        switch (Sys.command(cmd, args)) {
            case 0:
                //pass
            case r:
                throw 'Command failed: $cmd ${args.join(" ")}';
        }
    }

    static function downloadBinaries(version:String):{
        path32:String,
        path64:String,
    } {
        final path32 = 'neko-$version-win.zip';
        final path64 = 'neko-$version-win64.zip';
        if (FileSystem.exists(path32)) {
            Sys.println('File $path32 exists, skipping download.');
        } else {
            cmd("curl", ["-fsSL", win32Url(version), "-o", path32]);
        }
        if (FileSystem.exists(path64)) {
            Sys.println('File $path64 exists, skipping download.');
        } else {
            cmd("curl", ["-fsSL", win64Url(version), "-o", path64]);
        }
        return {
            path32: path32,
            path64: path64,
        };
    }

    static function checksum(path:String):String {
        return Sha256.make(File.getBytes(path)).toHex();
    }

    static function writeInstallScript(version:String, checksum32:String, checksum64:String):Void {
        final tmpl = new Template(File.getContent("chocolateyInstall.ps1.template"));
        File.saveContent("chocolateyInstall.ps1", tmpl.execute({
            VERSION: version,
            CHECKSUM32: checksum32,
            CHECKSUM64: checksum64,
        }));
    }

    static function writeNuSpec(version:String):Void {
        final tmpl = new Template(File.getContent("neko.nuspec.template"));
        File.saveContent("neko.nuspec", tmpl.execute({
            VERSION: version,
        }));
    }

    static function extractLicense(zipPath:String):Void {
        final zip = new format.zip.Reader(File.read(zipPath, true));
        final entries = zip.read();
        for (entry in entries) {
            switch entry.fileName.split("/") {
                case [_, "LICENSE"]:
                    format.zip.Tools.uncompress(entry);
                    File.saveBytes("LICENSE", entry.data);
                    return;
                case _:
                    // pass
            }
        }
        throw 'LICENSE not found in $zipPath';
    }

    static function main():Void {
        switch (Sys.args()) {
            case []:
                throw "No version parameter was passed in.";
            case [version]:
                Sys.println('Downloading Neko $version');
                final bins = downloadBinaries(version);
                final checksum32 = checksum(bins.path32);
                Sys.println('Checksum ${bins.path32}: ${checksum32}');
                final checksum64 = checksum(bins.path64);
                Sys.println('Checksum ${bins.path64}: ${checksum64}');
                Sys.println('Extracting LICENSE');
                extractLicense(bins.path64);
                Sys.println('Writing chocolateyInstall.ps1');
                writeInstallScript(version, checksum32, checksum64);
                Sys.println('Writing neko.nuspec');
                writeNuSpec(version);
                Sys.println('Done. Run `choco pack --version $version` to create the package.');
        }
    }
}