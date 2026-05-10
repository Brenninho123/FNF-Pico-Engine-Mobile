package funkin.stages;

import funkin.data.characters.Character;
import funkin.play.songs.Song;
import funkin.modding.scripting.psychlua.ModchartSprite;

import openfl.utils.Assets;
import haxe.Json;

typedef StageFile =
{
	var directory:String;
	var defaultZoom:Float;
	@:optional var isPixelStage:Null<Bool>;
	var stageUI:String;

	var boyfriend:Array<Float>;
	var girlfriend:Array<Float>;
	var opponent:Array<Float>;
	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;

	@:optional var preload:Dynamic;
	@:optional var objects:Array<Dynamic>;
	@:optional var _editorMeta:Dynamic;
}

enum abstract LoadFilters(Int) from Int from UInt to Int to UInt
{
	var LOW_QUALITY:Int = (1 << 0);
	var HIGH_QUALITY:Int = (1 << 1);

	var STORY_MODE:Int = (1 << 2);
	var FREEPLAY:Int = (1 << 3);
}

class StageData
{
	public static function dummy():StageFile
	{
		return {
			directory: "",
			defaultZoom: 0.9,
			stageUI: "normal",

			boyfriend: [770, 100],
			girlfriend: [400, 130],
			opponent: [100, 100],
			hide_girlfriend: false,

			camera_boyfriend: [0, 0],
			camera_opponent: [0, 0],
			camera_girlfriend: [0, 0],
			camera_speed: 1,

			_editorMeta: {
				boyfriend: "bf",
				gf: "gf",
				dad: "dad"
			}
		};
	}

	public static var forceNextDirectory:String = null;
	public static function loadDirectory(SONG:SwagSong) {
		var stage:String = '';
		if(SONG.stage != null)
			stage = SONG.stage;
		else if(Song.loadedSongName != null)
			stage = vanillaSongStage(Paths.formatToSongPath(Song.loadedSongName));
		else
			stage = 'stage';

		var stageFile:StageFile = getStageFile(stage);
		forceNextDirectory = (stageFile != null) ? stageFile.directory : ''; //preventing crashes
	}

	public static function getStageFile(stage:String):StageFile {
		try
		{
			var path:String = Paths.getPath('stages/' + stage + '.json', TEXT, null, true);
			#if MODS_ALLOWED
			if(FileSystem.exists(path))
				return normalizeStageFile(cast tjson.TJSON.parse(File.getContent(path)));
			#else
			if(Assets.exists(path))
				return normalizeStageFile(cast tjson.TJSON.parse(Assets.getText(path)));
			#end
		}
		return dummy();
	}

	static function normalizeStageFile(stage:StageFile):StageFile
	{
		if(stage == null) return dummy();

		stage.defaultZoom = floatField(stage.defaultZoom, 0.9);
		stage.camera_speed = stage.camera_speed != null ? floatField(stage.camera_speed, 1) : 1;

		stage.boyfriend = normalizePoint(stage.boyfriend, [770, 100]);
		stage.girlfriend = normalizePoint(stage.girlfriend, [400, 130]);
		stage.opponent = normalizePoint(stage.opponent, [100, 100]);
		stage.camera_boyfriend = normalizePoint(stage.camera_boyfriend, [0, 0]);
		stage.camera_opponent = normalizePoint(stage.camera_opponent, [0, 0]);
		stage.camera_girlfriend = normalizePoint(stage.camera_girlfriend, [0, 0]);

		if(stage.objects != null)
		{
			for(object in stage.objects)
				normalizeStageObject(object);
		}
		return stage;
	}

	static function normalizeStageObject(object:Dynamic):Void
	{
		if(object == null) return;

		for(field in ['x', 'y', 'alpha', 'angle'])
		{
			var value:Dynamic = Reflect.field(object, field);
			if(value != null)
				Reflect.setField(object, field, floatField(value, field == 'alpha' ? 1 : 0));
		}

		var scale:Dynamic = Reflect.field(object, 'scale');
		Reflect.setField(object, 'scale', normalizePoint(scale, [1, 1]));

		var scroll:Dynamic = Reflect.field(object, 'scroll');
		Reflect.setField(object, 'scroll', normalizePoint(scroll, [1, 1]));

		var filters:Dynamic = Reflect.field(object, 'filters');
		if(filters != null)
		{
			var parsed:Float = floatField(filters, LOW_QUALITY | HIGH_QUALITY);
			Reflect.setField(object, 'filters', Std.int(parsed));
		}
	}

	static function normalizePoint(value:Dynamic, fallback:Array<Float>):Array<Float>
	{
		if(value == null) return fallback.copy();

		if(Std.isOfType(value, Array))
		{
			var array:Array<Dynamic> = cast value;
			return [
				array.length > 0 ? floatField(array[0], fallback[0]) : fallback[0],
				array.length > 1 ? floatField(array[1], fallback[1]) : fallback[1]
			];
		}

		var text:String = Std.string(value).replace(';', ',').replace('|', ',');
		var split:Array<String> = text.contains(',') ? text.split(',') : text.split(' ');
		if(split.length > 1)
			return [floatField(split[0], fallback[0]), floatField(split[1], fallback[1])];

		return fallback.copy();
	}

	static function floatField(value:Dynamic, fallback:Float):Float
	{
		if(value == null) return fallback;
		var parsed:Float = Std.parseFloat(Std.string(value).trim());
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	public static function vanillaSongStage(songName):String
	{
		switch (songName)
		{
			case 'spookeez' | 'south' | 'monster':
				return 'spooky';
			case 'pico' | 'blammed' | 'philly' | 'philly-nice':
				return 'philly';
			case 'milf' | 'satin-panties' | 'high':
				return 'limo';
			case 'cocoa' | 'eggnog':
				return 'mall';
			case 'winter-horrorland':
				return 'mallEvil';
			case 'senpai' | 'roses':
				return 'school';
			case 'thorns':
				return 'schoolEvil';
			case 'ugh' | 'guns' | 'stress':
				return 'tank';
			case 'darnell' | 'lit-up' | '2hot':
				return 'phillyStreets';
		}
		return 'stage';
	}

	public static function vanillaerectpico(songName):String
	{
		switch (songName)
		{
			case 'spookeez' | 'south' | 'monster':
				return 'spooky';
			case 'pico' | 'blammed' | 'philly' | 'philly-nice':
				return 'philly';
			case 'satin-panties' | 'milf' | 'high':
				return 'limo';
			case 'cocoa' | 'eggnog':
				return 'mall';
			case 'winter-horrorland':
				return 'mallEvil';
			case 'senpai' | 'roses':
				return 'school';
			case 'thorns':
				return 'schoolEvil';
			case 'ugh' | 'guns' | 'stress':
				return 'tank';
			case 'darnell' | 'lit-up' | '2hot':
				return 'phillyStreets';
		}
		return 'stageErect';
	}

	public static var reservedNames:Array<String> = ['gf', 'gfGroup', 'dad', 'dadGroup', 'boyfriend', 'boyfriendGroup']; //blocks these names from being used on stage editor's name input text
	public static function addObjectsToState(objectList:Array<Dynamic>, gf:FlxSprite, dad:FlxSprite, boyfriend:FlxSprite, ?group:Dynamic = null, ?ignoreFilters:Bool = false)
	{
		var addedObjects:Map<String, FlxSprite> = [];
		for (num => data in objectList)
		{
			if (addedObjects.exists(data)) continue;

			switch(data.type)
			{
				case 'gf', 'gfGroup':
					if(gf != null)
					{
						gf.ID = num; 
						if (group != null) group.add(gf);
						addedObjects.set('gf', gf);
					}
				case 'dad', 'dadGroup':
					if(dad != null)
					{
						dad.ID = num;
						if (group != null) group.add(dad);
						addedObjects.set('dad', dad);
					}
				case 'boyfriend', 'boyfriendGroup':
					if(boyfriend != null)
					{
						boyfriend.ID = num;
						if (group != null) group.add(boyfriend);
						addedObjects.set('boyfriend', boyfriend);
					}

				case 'square', 'sprite', 'animatedSprite':
					if(!ignoreFilters && !validateVisibility(data.filters)) continue;

					var spr:ModchartSprite = new ModchartSprite(data.x, data.y);
					spr.ID = num;
					if(data.type != 'square')
					{
						if(data.type == 'sprite')
							spr.loadGraphic(Paths.image(data.image));
						else
							spr.frames = Paths.getAtlas(data.image);
						
						if(data.type == 'animatedSprite' && data.animations != null)
						{
							var anims:Array<funkin.data.characters.Character.AnimArray> = cast data.animations;
							for (key => anim in anims)
							{
								if(anim.indices == null || anim.indices.length < 1)
									spr.animation.addByPrefix(anim.anim, anim.name, anim.fps, anim.loop);
								else
									spr.animation.addByIndices(anim.anim, anim.name, anim.indices, '', anim.fps, anim.loop);
	
								if(anim.offsets != null)
									spr.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
	
								if(spr.animation.curAnim == null || data.firstAnimation == anim.anim)
									spr.playAnim(anim.anim, true);
							}
						}
						for (varName in ['antialiasing', 'flipX', 'flipY'])
						{
							var dat:Dynamic = Reflect.getProperty(data, varName);
							if(dat != null) Reflect.setProperty(spr, varName, dat);
						}
						if(!ClientPrefs.data.antialiasing) spr.antialiasing = false;
					}
					else
					{
						spr.makeGraphic(1, 1, FlxColor.WHITE);
						spr.antialiasing = false;
					}

					if(data.scale != null && (data.scale[0] != 1.0 || data.scale[1] != 1.0))
					{
						spr.scale.set(data.scale[0], data.scale[1]);
						spr.updateHitbox();
					}
					spr.scrollFactor.set(data.scroll[0], data.scroll[1]);
					spr.color = CoolUtil.colorFromString(data.color);
					
					for (varName in ['alpha', 'angle'])
					{
						var dat:Dynamic = Reflect.getProperty(data, varName);
						if(dat != null) Reflect.setProperty(spr, varName, dat);
					}

					if (group != null) group.add(spr);
					addedObjects.set(data.name, spr);

				default:
					var err = '[Stage .JSON file] Unknown sprite type detected: ${data.type}';
					trace(err);
					FlxG.log.error(err);
			}
		}
		return addedObjects;
	}

	public static function validateVisibility(filters:LoadFilters)
	{
		if((filters & STORY_MODE) == STORY_MODE)
			if(!PlayState.isStoryMode) return false;
		else if((filters & FREEPLAY) == FREEPLAY)
			if(PlayState.isStoryMode) return false;

		return ((ClientPrefs.isLowQuality && (filters & LOW_QUALITY) == LOW_QUALITY) ||
			(!ClientPrefs.isLowQuality && (filters & HIGH_QUALITY) == HIGH_QUALITY));
	}
}
