package lucas.states.funkin.scripts.menus.extra;

import flixel.text.FlxText.FlxTextBorderStyle;
import funkin.data.Difficulty;
import funkin.data.Paths;
import funkin.data.achievements.Achievements;
import funkin.data.editors.ChartingState;
import funkin.data.objects.HealthIcon;
import funkin.play.Highscore;
import funkin.play.songs.Song;
import funkin.stages.StageData;
import haxe.Json;

using StringTools;

#if PICO_ALLOWED
private typedef ExtraSongsRoot =
{
	var path:String;
	var folder:Null<String>;
}

class ExtraSongsState extends MusicBeatState
{
	private var songs:Array<ExtraSongMetadata> = [];
	private static var curSelected:Int = 0;
	private static var curDiffSelected:Int = 0;

	var curDifficulty:Int = -1;
	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var noSongsText:FlxText;

	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int = 0xFF808080;
	var colorTween:FlxTween;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		PlayState.storyWeek = 0;
		loadExtraSongs();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In The Extra Songs Menu", "Selecting An Extra Song");
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menus/bg/menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		if(songs.length < 1)
		{
			noSongsText = new FlxText(60, 0, FlxG.width - 120,
				'NO EXTRA SONGS FOUND\n\nPut charts inside data/extras-songs/<song>/<song>-<diff>.json\nPress BACK to return to Freeplay.',
				24);
			noSongsText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noSongsText.screenCenter(Y);
			add(noSongsText);
			super.create();
			return;
		}

		for(i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var maxWidth:Float = 980;
			if(songText.width > maxWidth)
				songText.scaleX = maxWidth / songText.width;

			Mods.currentModDirectory = songs[i].folder ?? '';
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;
			iconArray.push(icon);
			add(icon);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);
		add(scoreText);

		if(curSelected >= songs.length) curSelected = songs.length - 1;
		if(curSelected < 0) curSelected = 0;
		changeSelection(0, false);
		super.create();
	}

	override function update(elapsed:Float)
	{
		if(songs.length < 1)
		{
			if(controls.BACK)
				returnToFreeplay();
			super.update(elapsed);
			return;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));
		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + Math.floor(lerpRating * 100) + '%)';
		positionHighscore();

		if(controls.UI_UP_P)    changeSelection(-1);
		if(controls.UI_DOWN_P)  changeSelection(1);
		if(controls.UI_LEFT_P)  changeDiff(-1);
		if(controls.UI_RIGHT_P) changeDiff(1);

		if(controls.BACK)
			returnToFreeplay();

		if(controls.ACCEPT)
			acceptSong();

		super.update(elapsed);
	}

	function loadExtraSongs():Void
	{
		songs = [];
		loadExtraSongList();
		loadExtraSongsFromFolders();

		if(songs.length < 1)
			loadHardcodedFallback();
	}

	function loadExtraSongList():Void
	{
		var songListPath:String = Paths.txt('extraSonglist');
		var songListExists:Bool = false;

		#if sys
		songListExists = FileSystem.exists(songListPath);
		#else
		songListExists = openfl.utils.Assets.exists(songListPath);
		#end

		if(!songListExists)
			return;

		var lines:Array<String> = CoolUtil.coolTextFile(songListPath);
		var weekNum:Int = 1;
		for(line in lines)
		{
			var trimmed:String = line.trim();
			if(trimmed.length == 0 || trimmed.startsWith('//') || trimmed.startsWith('#'))
				continue;

			var parts:Array<String> = trimmed.split(':');
			if(parts.length < 1)
				continue;

			var songId:String = Paths.formatToSongPath(parts[0].trim());
			if(songId.length < 1 || hasSong(songId))
				continue;

			var character:String = parts.length > 1 ? parts[1].trim() : 'face';
			var week:Int = parts.length > 2 ? parseIntOr(parts[2].trim(), weekNum) : weekNum;
			var colorStr:String = parts.length > 3 ? parts[3].trim() : '808080';
			var diffsRaw:String = parts.length > 4 ? parts[4].trim() : 'Pico';
			var color:Int = parseColor(colorStr, colorFromSongId(songId));
			var diffs:Array<String> = normalizeDiffs(diffsRaw.split(','));

			var song = new ExtraSongMetadata(parts[0].trim(), week, character, color, diffs, songId);
			fillChartKeysFromFolders(song);
			songs.push(song);
			weekNum++;
		}
	}

	function loadExtraSongsFromFolders():Void
	{
		#if sys
		var roots:Array<ExtraSongsRoot> = getExtraSongRoots();
		for(root in roots)
		{
			if(!FileSystem.exists(root.path) || !FileSystem.isDirectory(root.path))
				continue;

			var folders:Array<String> = FileSystem.readDirectory(root.path);
			folders.sort(function(a:String, b:String) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));

			for(folderName in folders)
			{
				var songFolder:String = haxe.io.Path.join([root.path, folderName]);
				if(!FileSystem.isDirectory(songFolder))
					continue;

				var songId:String = Paths.formatToSongPath(folderName);
				if(songId.length < 1 || hasSong(songId))
					continue;

				var song:ExtraSongMetadata = scanExtraSongFolder(songFolder, songId, root.folder);
				if(song != null)
					songs.push(song);
			}
		}
		#end
	}

	function getExtraSongRoots():Array<ExtraSongsRoot>
	{
		var roots:Array<ExtraSongsRoot> = [];
		#if sys
		#if MODS_ALLOWED
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			addExtraSongRoot(roots, Paths.mods(Mods.currentModDirectory + '/data/extras-songs'), Mods.currentModDirectory);

		for(mod in Mods.getGlobalMods())
			addExtraSongRoot(roots, Paths.mods(mod + '/data/extras-songs'), mod);

		addExtraSongRoot(roots, Paths.mods('data/extras-songs'), null);
		#end

		addExtraSongRoot(roots, Paths.getSharedPath('data/extras-songs'), null);
		addExtraSongRoot(roots, Paths.getFolderPath('data/extras-songs', 'base_game/shared'), 'base_game/shared');
		#end
		return roots;
	}

	function addExtraSongRoot(roots:Array<ExtraSongsRoot>, path:String, folder:Null<String>):Void
	{
		for(root in roots)
			if(root.path == path)
				return;
		roots.push({path: path, folder: folder});
	}

	function scanExtraSongFolder(songFolder:String, songId:String, folder:Null<String>):ExtraSongMetadata
	{
		#if sys
		var files:Array<String> = FileSystem.readDirectory(songFolder);
		files.sort(function(a:String, b:String) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));

		var diffs:Array<String> = [];
		var chartKeys:Map<String, String> = [];
		var displayName:String = readableSongName(songId);
		var character:String = 'face';
		var color:Int = colorFromSongId(songId);

		for(file in files)
		{
			if(!file.toLowerCase().endsWith('.json'))
				continue;

			var baseName:String = file.substr(0, file.length - 5);
			var diff:String = diffFromChartName(songId, baseName);
			if(diff == null)
				continue;

			var chartKey:String = songId + '/' + baseName;
			var path:String = haxe.io.Path.join([songFolder, file]);
			var raw:String = readText(path);
			if(raw != null)
			{
				var meta:Dynamic = readChartMetadata(raw);
				var chartSongName:String = getStringField(meta, 'song');
				var chartCharacter:String = getStringField(meta, 'player2');
				if(chartSongName != null && chartSongName.length > 0 && displayName == readableSongName(songId))
					displayName = chartSongName;
				if(chartCharacter != null && chartCharacter.length > 0 && character == 'face')
					character = chartCharacter;
			}

			diffs.push(diff);
			chartKeys.set(diff, chartKey);
		}

		if(diffs.length < 1)
			return null;

		var song = new ExtraSongMetadata(displayName, songs.length + 1, character, color, diffs, songId, folder);
		song.chartKeys = chartKeys;
		return song;
		#else
		return null;
		#end
	}

	function fillChartKeysFromFolders(song:ExtraSongMetadata):Void
	{
		#if sys
		var roots:Array<ExtraSongsRoot> = getExtraSongRoots();
		for(root in roots)
		{
			var songFolder:String = haxe.io.Path.join([root.path, song.songId]);
			if(!FileSystem.exists(songFolder) || !FileSystem.isDirectory(songFolder))
				continue;

			var scanned:ExtraSongMetadata = scanExtraSongFolder(songFolder, song.songId, root.folder);
			if(scanned == null)
				continue;

			if(song.folder == null || song.folder.length < 1)
				song.folder = scanned.folder ?? '';

			for(diff in scanned.diffs)
			{
				var matchingDiff:String = findMatchingDiff(song.diffs, diff);
				if(matchingDiff != null)
					song.chartKeys.set(matchingDiff, scanned.chartKeys.get(diff));
			}

			if(song.songCharacter == 'face')
				song.songCharacter = scanned.songCharacter;
			return;
		}
		#end

		for(diff in song.diffs)
			if(!song.chartKeys.exists(diff))
				song.chartKeys.set(diff, song.songId + '/' + song.songId + Difficulty.getSuffixFilePath(diff));
	}

	function loadHardcodedFallback():Void
	{
		var fallback:Array<ExtraSongMetadata> = [
			new ExtraSongMetadata('stay-funky',        1, 'bf',                    0xFF1C22DB, ['hard'], 'stay-funky'),
			new ExtraSongMetadata('lo-fight',          2, 'extra/whitty',           0xFF1D1E35, ['pico'], 'lo-fight'),
			new ExtraSongMetadata('endless',           3, 'extra/exe/majin-encore', 0xFF0000D7, ['pico'], 'endless'),
			new ExtraSongMetadata('sky',               4, 'face',                   0xFF132CBB, ['pico'], 'sky'),
			new ExtraSongMetadata('all-hail-the-king', 5, 'extra/bowser',           0xFFC28933, ['pico'], 'all-hail-the-king'),
			new ExtraSongMetadata('ruckus',            6, 'extra/matt',             0xFFE27E20, ['pico'], 'ruckus'),
			new ExtraSongMetadata('thunderstorm',      7, 'extra/shaggy',           0xFFB80000, ['pico'], 'thunderstorm')
		];

		for(song in fallback)
		{
			fillChartKeysFromFolders(song);
			songs.push(song);
		}
	}

	function acceptSong():Void
	{
		var song:ExtraSongMetadata = songs[curSelected];
		var diff:String = song.diffs[curDiffSelected];
		var chartKey:String = song.getChartKey(diff);
		var chartPath:String = Paths.extraSongsJson(chartKey, normalizeFolder(song.folder));
		var raw:String = readText(chartPath);

		if(raw == null)
		{
			chartKey = song.songId + '/' + song.songId + Difficulty.getSuffixFilePath(diff);
			chartPath = Paths.extraSongsJson(chartKey, normalizeFolder(song.folder));
			raw = readText(chartPath);
		}

		if(raw == null)
		{
			showChartError(song, diff, chartPath);
			return;
		}

		try
		{
			PlayState.SONG = Song.parseJSON(raw, chartKey);
			Song.loadedSongName = song.songId;
			Song.chartPath = chartPath;
			StageData.loadDirectory(PlayState.SONG);
		}
		catch(e:haxe.Exception)
		{
			showChartError(song, diff, e.message);
			return;
		}

		if(PlayState.SONG == null)
		{
			showChartError(song, diff, chartPath);
			return;
		}

		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = curDiffSelected;
		Difficulty.copyFrom(song.diffs);
		Mods.currentModDirectory = song.folder ?? '';

		FlxG.sound.music.volume = 0;
		LoadingState.prepareToSong();

		if(FlxG.keys.pressed.SHIFT)
			LoadingState.loadAndSwitchState(new ChartingState());
		else
			LoadingState.loadAndSwitchState(new PlayState());

		#if ACHIEVEMENTS_ALLOWED
		if(!Achievements.isUnlocked('extra_explorer'))
			Achievements.unlock('extra_explorer');
		#end
	}

	function changeDiff(change:Int = 0)
	{
		var song = songs[curSelected];
		curDiffSelected = FlxMath.wrap(curDiffSelected + change, 0, song.diffs.length - 1);
		updateDiffText();
		updateScore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(songs.length < 1)
			return;

		if(playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		curDiffSelected = 0;
		var song = songs[curSelected];
		Difficulty.copyFrom(song.diffs);

		intendedColor = song.color;
		if(bg != null)
		{
			if(colorTween != null) colorTween.cancel();
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {onComplete: function(_) colorTween = null});
		}

		for(i in 0...iconArray.length)
			if(iconArray[i] != null)
				iconArray[i].alpha = 0.6;
		if(iconArray[curSelected] != null)
			iconArray[curSelected].alpha = 1;

		var bullShit:Int = 0;
		for(item in grpSongs.members)
		{
			if(item == null)
				continue;
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = item.targetY == 0 ? 1 : 0.6;
		}
		Mods.currentModDirectory = song.folder ?? '';

		updateDiffText();
		updateScore();
	}

	function updateDiffText()
	{
		var song = songs[curSelected];
		var diff:String = song.diffs[curDiffSelected];
		if(song.diffs.length > 1)
			diffText.text = '< ' + diff.toUpperCase() + ' >';
		else
			diffText.text = diff.toUpperCase();
	}

	function updateScore()
	{
		var song = songs[curSelected];
		curDifficulty = curDiffSelected;
		intendedScore  = Highscore.getScore(song.songName, curDifficulty);
		intendedRating = Highscore.getRating(song.songName, curDifficulty);
	}

	private function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	function returnToFreeplay():Void
	{
		Difficulty.resetList();
		FlxG.sound.play(Paths.sound('cancelMenu'));
		MusicBeatState.switchState(new funkin.states.data.menus.freeplay.FreeplayState());
	}

	function showChartError(song:ExtraSongMetadata, diff:String, expected:String):Void
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));
		trace('[ExtraSongsState] Chart not found for: ${song.songName} (diff: $diff)');
		trace('[ExtraSongsState] Tried path: $expected');

		var errTxt:FlxText = new FlxText(0, FlxG.height - 66, FlxG.width,
			'Chart not found: ${song.songName} [$diff]\n$expected', 16);
		errTxt.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		errTxt.scrollFactor.set();
		add(errTxt);
		FlxTween.tween(errTxt, {alpha: 0}, 3, {startDelay: 2, onComplete: function(_) errTxt.destroy()});
	}

	static function readText(path:String):Null<String>
	{
		#if sys
		return FileSystem.exists(path) ? File.getContent(path) : null;
		#else
		return openfl.utils.Assets.exists(path) ? openfl.utils.Assets.getText(path) : null;
		#end
	}

	static function readChartMetadata(raw:String):Dynamic
	{
		try
		{
			var data:Dynamic = Json.parse(raw);
			if(Reflect.hasField(data, 'song'))
			{
				var subSong:Dynamic = Reflect.field(data, 'song');
				if(subSong != null && Type.typeof(subSong) == TObject)
					data = subSong;
			}
			return data;
		}
		catch(e:Dynamic) {}
		return null;
	}

	static function getStringField(data:Dynamic, field:String):String
	{
		if(data == null || !Reflect.hasField(data, field))
			return null;

		var value:Dynamic = Reflect.field(data, field);
		return value == null ? null : Std.string(value);
	}

	static function diffFromChartName(songId:String, baseName:String):String
	{
		var lowerBase:String = baseName.toLowerCase();
		if(lowerBase == 'events' || lowerBase.startsWith('events-') || lowerBase == 'eventsb')
			return null;
		if(lowerBase == 'metadata' || lowerBase == 'preload' || lowerBase == 'notetypes')
			return null;

		var lowerSong:String = songId.toLowerCase();
		if(!lowerBase.startsWith(lowerSong))
			return null;

		var suffix:String = baseName.substr(songId.length);
		while(suffix.startsWith('-') || suffix.startsWith('_') || suffix.startsWith(' '))
			suffix = suffix.substr(1);

		if(suffix.length < 1)
			return Difficulty.getDefault();

		var cleanSuffix:String = Paths.formatToSongPath(suffix);
		if(cleanSuffix == 'dialogue' || cleanSuffix == 'events' || cleanSuffix == 'metadata')
			return null;

		return suffix;
	}

	static function normalizeDiffs(raw:Array<String>):Array<String>
	{
		var diffs:Array<String> = [];
		for(diff in raw)
		{
			var clean:String = diff.trim();
			if(clean.length > 0 && !containsDiff(diffs, clean))
				diffs.push(clean);
		}
		if(diffs.length < 1)
			diffs.push('pico');
		return diffs;
	}

	static function containsDiff(diffs:Array<String>, diff:String):Bool
	{
		return findMatchingDiff(diffs, diff) != null;
	}

	static function findMatchingDiff(diffs:Array<String>, diff:String):String
	{
		var clean:String = Paths.formatToSongPath(diff);
		for(existing in diffs)
			if(Paths.formatToSongPath(existing) == clean)
				return existing;
		return null;
	}

	static function readableSongName(songId:String):String
	{
		var words:Array<String> = [];
		for(part in songId.split('-'))
		{
			if(part.length < 1)
				continue;
			words.push(part.substr(0, 1).toUpperCase() + part.substr(1));
		}
		return words.length > 0 ? words.join(' ') : songId;
	}

	function hasSong(songId:String):Bool
	{
		var clean:String = Paths.formatToSongPath(songId);
		for(song in songs)
			if(Paths.formatToSongPath(song.songId) == clean)
				return true;
		return false;
	}

	static function parseIntOr(value:String, fallback:Int):Int
	{
		var parsed:Null<Int> = Std.parseInt(value);
		return parsed == null ? fallback : parsed;
	}

	static function parseColor(value:String, fallback:Int):Int
	{
		var clean:String = value.replace('#', '').replace('0x', '').replace('0X', '').trim();
		if(clean.length == 6)
			clean = 'FF' + clean;

		var parsed:Null<Int> = Std.parseInt('0x' + clean);
		return parsed == null ? fallback : parsed;
	}

	static function colorFromSongId(songId:String):Int
	{
		var hue:Float = 0;
		for(i in 0...songId.length)
		{
			hue = hue * 31 + songId.charCodeAt(i);
			hue -= Math.floor(hue / 360) * 360;
		}

		return FlxColor.fromHSB(hue, 0.65, 0.75);
	}

	static function normalizeFolder(folder:Null<String>):Null<String>
	{
		return (folder == null || folder.length < 1) ? null : folder;
	}
}

class ExtraSongMetadata
{
	public var songName:String = "";
	public var songId:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -1;
	public var folder:String = "";
	public var diffs:Array<String> = ["pico"];
	public var chartKeys:Map<String, String> = [];

	public function new(song:String, week:Int, songCharacter:String, color:Int, ?diffs:Array<String>, ?songId:String, ?folder:String)
	{
		this.songName = song;
		this.songId = (songId != null && songId.length > 0) ? songId : Paths.formatToSongPath(song);
		this.week = week;
		this.songCharacter = (songCharacter != null && songCharacter.length > 0) ? songCharacter : 'face';
		this.color = color;
		this.diffs = (diffs != null && diffs.length > 0) ? diffs : ['pico'];
		this.folder = folder ?? (Mods.currentModDirectory ?? '');

		for(diff in this.diffs)
			if(!chartKeys.exists(diff))
				chartKeys.set(diff, this.songId + '/' + this.songId + Difficulty.getSuffixFilePath(diff));
	}

	public function getChartKey(diff:String):String
	{
		if(chartKeys.exists(diff))
			return chartKeys.get(diff);

		var clean:String = Paths.formatToSongPath(diff);
		for(key in chartKeys.keys())
			if(Paths.formatToSongPath(key) == clean)
				return chartKeys.get(key);

		return songId + '/' + songId + Difficulty.getSuffixFilePath(diff);
	}
}
#end
