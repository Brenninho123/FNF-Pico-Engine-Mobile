package funkin.data.characters;

import funkin.play.Song;
import funkin.stages.data.weeks.week7.objects.*;
import funkin.utils.engine.psych.PsychAnimationController;

import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;

import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	@:optional var assetPath:String;
	@:optional var image:String;
	var scale:Float;
	var sing_duration:Float;
	@:optional var healthicon:String;
	@:optional var HealthIcon:String;
	@:optional var AnimatedIcon:Bool;
	@:optional var animatedIcon:Bool;
	@:optional var animated_icon:Bool;

	@:optional var offsets:Array<Float>;
	@:optional var position:Array<Float>;
	@:optional var cameraOffsets:Array<Float>;
	@:optional var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;
	@:optional var characterType:String;
	@:optional var character_type:String;
	@:optional var _editor_isPlayer:Null<Bool>;
	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;
	@:optional var arrowSkin:String;
	@:optional var noteStyle:String;
}

typedef AnimArray = {
	@:optional var assetPath:String;
	var anim:String;
	var name:String;
	@:optional var prefix:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	@:optional var frameIndices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	/**
	 * In case a character is missing, it will use this on its place
	**/
	public static final PLAYER_DEFAULT_CHARACTER:String = 'bf';
	public static final DEFAULT_CHARACTER:String = 'bf-opponent';

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;
	public var PLAYERcurCharacter:String = PLAYER_DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animatedIcon:Bool = false;
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var missingCharacter:Bool = false;
	public var missingText:FlxText;
	public var hasMissAnimations:Bool = false;
	public var vocalsFile:String = '';
	public var gameOverChar:String = '';
	public var gameOverSound:String = '';
	public var gameOverLoop:String = '';
	public var gameOverEnd:String = '';
	public var noteStyle:String = '';

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;
	public var editorCharacterType:String = null;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		animation = new PsychAnimationController(this);

		animOffsets = new Map<String, Array<Dynamic>>();
		this.isPlayer = isPlayer;
		changeCharacter(character);
		
		switch(curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
			case 'pico-blazin', 'darnell-blazin':
				skipDance = true;
		}
	}

	public function changeCharacter(character:String)
	{
		animationsArray = [];
		animOffsets = [];
		curCharacter = character;
		var characterPath:String = 'data/characters/$character.json';

		var path:String = Paths.getPath(characterPath, TEXT);
		#if MODS_ALLOWED
		if (!FileSystem.exists(path))
		#else
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getSharedPath('data/characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
			missingCharacter = true;
			missingText = new FlxText(0, 0, 300, 'ERROR:\n$character.json', 16);
			missingText.alignment = CENTER;
		}

		try
		{
			#if MODS_ALLOWED
			loadCharacterFile(Json.parse(File.getContent(path)));
			#else
			loadCharacterFile(Json.parse(Assets.getText(path)));
			#end
		}
		catch(e:Dynamic)
		{
			trace('Error loading character file of "$character": $e');
		}

		skipDance = false;
		hasMissAnimations = hasAnimation('singLEFTmiss') || hasAnimation('singDOWNmiss') || hasAnimation('singUPmiss') || hasAnimation('singRIGHTmiss');
		recalculateDanceIdle();
		dance();
	}

	public function loadCharacterFile(json:Dynamic)
	{
		isAnimateAtlas = false;
		var assetPath:String = characterString(json.assetPath, characterString(json.image, ''));
		animationsArray = normalizeAnimations(json.animations);
		var fullAssetPath:String = collectAnimationAssetPaths(assetPath, animationsArray);

		#if flxanimate
		isAnimateAtlas = Paths.hasAnimateAtlas(fullAssetPath);
		#end

		scale.set(1, 1);
		updateHitbox();

		if(!isAnimateAtlas)
		{
			frames = Paths.getMultiAtlas(fullAssetPath.split(','));
		}
		#if flxanimate
		else
		{
			atlas = new FlxAnimate();
			atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(atlas, fullAssetPath);
			}
			catch(e:haxe.Exception)
			{
				FlxG.log.warn('Could not load atlas $fullAssetPath: $e');
				trace(e.stack);
			}
		}
		#end

		imageFile = assetPath;
		jsonScale = characterFloat(json.scale, 1);
		if(jsonScale != 1) {
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		// positioning
		positionArray = normalizePoint(json.offsets != null ? json.offsets : json.position, [0, 0]);
		cameraPosition = normalizePoint(json.cameraOffsets != null ? json.cameraOffsets : json.camera_position, [0, 0]);

		// data
		healthIcon = characterString(json.healthicon, characterString(json.HealthIcon, 'face'));
		animatedIcon = (json.animatedIcon == true || json.AnimatedIcon == true || json.animated_icon == true);
		singDuration = json.sing_duration;
		flipX = (json.flip_x != isPlayer);
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		vocalsFile = json.vocals_file != null ? json.vocals_file : '';
		gameOverChar = characterString(json.gameOverChar, characterString(json.gameOverCharacter, ''));
		gameOverSound = characterString(json.gameOverSound, '');
		gameOverLoop = characterString(json.gameOverLoop, '');
		gameOverEnd = characterString(json.gameOverEnd, '');
		noteStyle = characterString(json.noteStyle, characterString(json.arrowSkin, ''));
		originalFlipX = (json.flip_x == true);
		editorIsPlayer = json._editor_isPlayer;
		editorCharacterType = json.characterType != null ? json.characterType : json.character_type;

		// antialiasing
		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

		// animations
		if(animationsArray != null && animationsArray.length > 0) {
			for (anim in animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; //Bruh
				var animIndices:Array<Int> = anim.indices;

				if(!isAnimateAtlas)
				{
					if(animIndices != null && animIndices.length > 0)
						animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					else
						animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
				#if flxanimate
				else
				{
					if(animIndices != null && animIndices.length > 0)
						atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					else
						atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
				}
				#end

				if(anim.offsets != null && anim.offsets.length > 1) addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				else addOffset(anim.anim, 0, 0);
			}
		}
		#if flxanimate
		if(isAnimateAtlas) copyAtlasValues();
		#end
		//trace('Loaded file to character ' + curCharacter);
	}

	public static function collectAnimationAssetPaths(assetPath:String, animations:Array<AnimArray>):String
	{
		var paths:Array<String> = [];
		addUniqueAssetPath(paths, assetPath);

		if(animations != null)
			for (anim in animations)
				addUniqueAssetPath(paths, anim.assetPath);

		return paths.join(',');
	}

	static function addUniqueAssetPath(paths:Array<String>, path:String):Void
	{
		if(path == null) return;

		for (part in path.split(','))
		{
			var clean:String = Paths.normalizeAssetPath(part);
			if(clean.length > 0 && !paths.contains(clean))
				paths.push(clean);
		}
	}

	static function normalizeAnimations(value:Dynamic):Array<AnimArray>
	{
		var normalized:Array<AnimArray> = [];
		if(value == null) return normalized;

		var rawAnimations:Array<Dynamic> = cast value;
		for (raw in rawAnimations)
		{
			var legacyAnim:Dynamic = getDynamicField(raw, 'anim');
			var newName:Dynamic = getDynamicField(raw, 'name');
			var prefix:Dynamic = getDynamicField(raw, 'prefix');
			var assetPath:Dynamic = getDynamicField(raw, 'assetPath');
			var frameIndices:Dynamic = getDynamicField(raw, 'frameIndices');
			if(frameIndices == null) frameIndices = getDynamicField(raw, 'indices');

			var animName:String = legacyAnim != null ? Std.string(legacyAnim) : characterString(newName, '');
			var animPrefix:String = prefix != null ? Std.string(prefix) : (legacyAnim != null ? characterString(newName, animName) : animName);

			normalized.push({
				assetPath: assetPath != null ? Std.string(assetPath) : '',
				anim: animName,
				name: animPrefix,
				fps: Math.round(characterFloat(getDynamicField(raw, 'fps'), 24)),
				loop: getDynamicField(raw, 'loop') == true,
				indices: normalizeIntArray(frameIndices),
				offsets: normalizeIntPoint(getDynamicField(raw, 'offsets'), [0, 0])
			});
		}

		return normalized;
	}

	static function getDynamicField(value:Dynamic, field:String):Dynamic
	{
		return value != null && Reflect.hasField(value, field) ? Reflect.field(value, field) : null;
	}

	static function characterString(value:Dynamic, fallback:String):String
	{
		return value == null ? fallback : Std.string(value);
	}

	static function normalizePoint(value:Dynamic, fallback:Array<Float>):Array<Float>
	{
		if(value == null) return fallback.copy();

		if(Std.isOfType(value, Array))
		{
			var array:Array<Dynamic> = cast value;
			return [
				array.length > 0 ? characterFloat(array[0], fallback[0]) : fallback[0],
				array.length > 1 ? characterFloat(array[1], fallback[1]) : fallback[1]
			];
		}

		var text:String = Std.string(value).replace(';', ',').replace('|', ',');
		var split:Array<String> = text.contains(',') ? text.split(',') : text.split(' ');
		if(split.length > 1)
			return [characterFloat(split[0], fallback[0]), characterFloat(split[1], fallback[1])];

		return fallback.copy();
	}

	static function normalizeIntPoint(value:Dynamic, fallback:Array<Int>):Array<Int>
	{
		var point:Array<Float> = normalizePoint(value, [fallback[0], fallback[1]]);
		return [Math.round(point[0]), Math.round(point[1])];
	}

	static function normalizeIntArray(value:Dynamic):Array<Int>
	{
		var result:Array<Int> = [];
		if(value == null) return result;

		if(Std.isOfType(value, Array))
		{
			for (item in (cast value:Array<Dynamic>))
			{
				var parsed:Null<Int> = Std.parseInt(Std.string(item).trim());
				if(parsed != null) result.push(parsed);
			}
			return result;
		}

		for (item in Std.string(value).split(','))
		{
			var parsed:Null<Int> = Std.parseInt(item.trim());
			if(parsed != null) result.push(parsed);
		}
		return result;
	}

	static function characterFloat(value:Dynamic, fallback:Float):Float
	{
		if(value == null) return fallback;
		var parsed:Float = Std.parseFloat(Std.string(value).trim());
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	override function update(elapsed:Float)
	{
		if(isAnimateAtlas) atlas.update(elapsed);

		if(debugMode || (!isAnimateAtlas && animation.curAnim == null) || (isAnimateAtlas && (atlas.anim.curInstance == null || atlas.anim.curSymbol == null)))
		{
			super.update(elapsed);
			return;
		}

		if(heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if(heyTimer <= 0)
			{
				var anim:String = getAnimationName();
				if(specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if(specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
		}

		switch(curCharacter)
		{
			case 'pico-speaker':
				if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
				{
					var noteData:Int = 1;
					if(animationNotes[0][1] > 2) noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				if(isAnimationFinished()) playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
		}

		if (getAnimationName().startsWith('sing')) holdTimer += elapsed;
		else if(isPlayer) holdTimer = 0;

		if (!isPlayer && holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
		{
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if(isAnimationFinished() && hasAnimation('$name-loop'))
			playAnim('$name-loop');

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
	{
		return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curInstance == null || atlas.anim.curSymbol == null);
	}

	var _lastPlayedAnimation:String;
	inline public function getAnimationName():String
	{
		return _lastPlayedAnimation;
	}

	public function isAnimationFinished():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished;
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;

		if(!isAnimateAtlas) animation.curAnim.finish();
		else atlas.anim.curFrame = atlas.anim.length - 1;
	}

	public function hasAnimation(anim:String):Bool
	{
		return animOffsets.exists(anim);
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying;
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		if(!isAnimateAtlas) animation.curAnim.paused = value;
		else
		{
			if(value) atlas.pauseAnimation();
			else atlas.resumeAnimation();
		}

		return value;
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if(danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if(hasAnimation('idle' + idleSuffix))
				playAnim('idle' + idleSuffix);
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		if(!isAnimateAtlas)
		{
			animation.play(AnimName, Force, Reversed, Frame);
		}
		else
		{
			atlas.anim.play(AnimName, Force, Reversed, Frame);
			atlas.update(0);
		}
		_lastPlayedAnimation = AnimName;

		if (hasAnimation(AnimName))
		{
			var daOffset = animOffsets.get(AnimName);
			offset.set(daOffset[0], daOffset[1]);
		}
		//else offset.set(0, 0);

		if (curCharacter.startsWith('gf-') || curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
				danced = true;

			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	function loadMappedAnims():Void
	{
		try
		{
			var songData:SwagSong = Song.getChart('picospeaker', Paths.formatToSongPath(Song.loadedSongName));
			if(songData != null)
				for (section in songData.notes)
					for (songNotes in section.sectionNotes)
						animationNotes.push(songNotes);

			TankmenBG.animationNotes = animationNotes;
			animationNotes.sort(sortAnims);
		}
		catch(e:Dynamic) {}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (hasAnimation('danceLeft' + idleSuffix) && hasAnimation('danceRight' + idleSuffix));

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	// Atlas support
	// special thanks ne_eo for the references, you're the goat!!
	@:allow(funkin.data.editors.CharacterEditorState)
	public var isAnimateAtlas(default, null):Bool = false;
	#if flxanimate
	public var atlas:FlxAnimate;
	public override function draw()
	{
		var lastAlpha:Float = alpha;
		var lastColor:FlxColor = color;
		if(missingCharacter)
		{
			alpha *= 0.6;
			color = FlxColor.BLACK;
		}

		if(isAnimateAtlas)
		{
			if(atlas.anim.curInstance != null)
			{
				copyAtlasValues();
				atlas.draw();
				alpha = lastAlpha;
				color = lastColor;
				if(missingCharacter && visible)
				{
					missingText.x = getMidpoint().x - 150;
					missingText.y = getMidpoint().y - 10;
					missingText.draw();
				}
			}
			return;
		}
		super.draw();
		if(missingCharacter && visible)
		{
			alpha = lastAlpha;
			color = lastColor;
			missingText.x = getMidpoint().x - 150;
			missingText.y = getMidpoint().y - 10;
			missingText.draw();
		}
	}

	public function copyAtlasValues()
	{
		@:privateAccess
		{
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.colorTransform = colorTransform;
			atlas.color = color;
		}
	}

	public override function destroy()
	{
		atlas = FlxDestroyUtil.destroy(atlas);
		super.destroy();
	}
	#end
}
