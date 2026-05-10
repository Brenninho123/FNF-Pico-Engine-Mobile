package lucas.states.funkin.scripts.backend.pslice;

import haxe.Json;


class FreeplayMetaJSON {
    public function new() {}
    public var artist:String = "unknown";

    public function mergeWithJson(data:Dynamic):FreeplayMetaJSON {
        if(data == null) return this;
        if(Reflect.hasField(data, 'artist') && data.artist != null)
            artist = Std.string(data.artist);
        return this;
    }
}

class FreeplayMeta {
    public static function getMeta(songId:String):FreeplayMetaJSON {
        var meta_file = Paths.getTextFromFile('data/songs/${Paths.formatToSongPath(songId)}/meta.json');
        if(meta_file != null){
            return getMetaFile(meta_file);
        }
        else {
            return new FreeplayMetaJSON();
        }
    }
    private static function getMetaFile(rawJson:String):FreeplayMetaJSON {

        try {
            if(rawJson != null && rawJson.length > 0) {
                return new FreeplayMetaJSON().mergeWithJson(Json.parse(rawJson));
            }
        }
        catch(x){
            trace("Malfolded json? tf did you do to it?");
            trace(x.message);
        }
		
		return new FreeplayMetaJSON();
	}
}