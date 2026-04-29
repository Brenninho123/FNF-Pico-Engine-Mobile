package lucas.states.funkin.scripts.menus.extra;

#if PSYCH_ALLOWED
#if ACHIEVEMENTS_ALLOWED
import objects.HealthIcon;
import backend.Song;
import backend.WeekData;
import backend.Highscore;
import backend.Difficulty;
import options.GameplayChangersSubstate;
import states.editors.ChartingState;
import backend.Paths;
import backend.Achievements;
#end
#end
using StringTools;

#if PICO_ALLOWED
class ExtraSongsState extends MusicBeatState
{
    private var songs:Array<ExtraSongMetadata> = [];
    private static var curSelected:Int = 0;
    private static var curDiffSelected:Int = 0; // índice dentro das diffs da música atual

    var curDifficulty:Int = -1;
    var scoreBG:FlxSprite;
    var scoreText:FlxText;
    var diffText:FlxText;

    var lerpScore:Int = 0;
    var lerpRating:Float = 0;
    var intendedScore:Int = 0;
    var intendedRating:Float = 0;

    private var grpSongs:FlxTypedGroup<Alphabet>;
    private var iconArray:Array<HealthIcon> = [];

    var bg:FlxSprite;
    var intendedColor:Int;
    var colorTween:FlxTween;

    override function create()
    {
        Paths.clearStoredMemory();
        Paths.clearUnusedMemory();

        persistentUpdate = true;
        PlayState.isStoryMode = false;

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("In The Extra Songs Menu", "Selecting An Extra Song");
        #end

        // ── Carrega músicas do extraSonglist.txt ──────────
        // Formato: songName:character:week:colorHex:diff1,diff2,diff3
        // Exemplo: thunderstorm:extra/shaggy:7:B80000:Easy,Pico,Hard
        // Arquivo em: assets/funkin_assets/alltxts/extraSonglist.txt
        var songListPath:String = Paths.txt('extraSonglist');
        var songListExists:Bool = false;

        #if sys
        songListExists = sys.FileSystem.exists(songListPath);
        #else
        songListExists = openfl.Assets.exists(songListPath);
        #end

        if(songListExists)
        {
            var lines:Array<String> = CoolUtil.coolTextFile(songListPath);
            var weekNum:Int = 1;
            for(line in lines)
            {
                var trimmed:String = line.trim();
                if(trimmed.length == 0 || trimmed.startsWith('//')) continue;

                var parts:Array<String> = trimmed.split(':');
                if(parts.length < 2) continue;

                var songName:String  = parts[0].trim();
                var character:String = parts[1].trim();
                var week:Int         = parts.length > 2 ? (Std.parseInt(parts[2].trim()) ?? weekNum) : weekNum;
                var colorStr:String  = parts.length > 3 ? parts[3].trim() : '808080';
                var diffsRaw:String  = parts.length > 4 ? parts[4].trim() : 'Pico';
                var color:Int        = Std.parseInt('0xFF' + colorStr.replace('#','').replace('0x','').replace('0X','')) ?? 0xFF808080;

                // dificuldades separadas por vírgula: Easy,Pico,Hard
                var diffs:Array<String> = diffsRaw.split(',').map(d -> d.trim()).filter(d -> d.length > 0);
                if(diffs.length == 0) diffs = ['Pico'];

                songs.push(new ExtraSongMetadata(songName, week, character, color, diffs));
                weekNum++;
            }
        }
        else
        {
            // Fallback hardcoded
            songs.push(new ExtraSongMetadata('stay-funky',        1, 'bf',                    0xFF1C22DB, ['Hard']));
            songs.push(new ExtraSongMetadata('lo-fight',          2, 'extra/whitty',           0xFF1D1E35, ['Pico']));
            songs.push(new ExtraSongMetadata('endless',           3, 'extra/exe/majin-encore', 0xFF0000D7, ['Pico']));
            songs.push(new ExtraSongMetadata('sky',               4, 'face',                   0xFF132CBB, ['Pico']));
            songs.push(new ExtraSongMetadata('all-hail-the-king', 5, 'extra/bowser',           0xFFC28933, ['Pico']));
            songs.push(new ExtraSongMetadata('ruckus',            6, 'extra/matt',             0xE1E27E20, ['Pico']));
            songs.push(new ExtraSongMetadata('thunderstorm',      7, 'extra/shaggy',           0xFFB80000, ['Pico']));
        }

        bg = new FlxSprite().loadGraphic(Paths.image('menus/bg/menuDesat'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        add(bg);
        bg.screenCenter();

        grpSongs = new FlxTypedGroup<Alphabet>();
        add(grpSongs);

        for(i in 0...songs.length)
        {
            var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true);
            songText.isMenuItem = true;
            songText.targetY = i;
            grpSongs.add(songText);

            var maxWidth:Float = 980;
            if(songText.width > maxWidth)
                songText.scaleX = maxWidth / songText.width;

            Mods.currentModDirectory = songs[i].folder;
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

        changeSelection();
        super.create();
    }

    override function update(elapsed:Float)
    {
        lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
        lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));
        scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + Math.floor(lerpRating * 100) + '%)';
        positionHighscore();

        if(controls.UI_UP_P)    changeSelection(-1);
        if(controls.UI_DOWN_P)  changeSelection(1);
        if(controls.UI_LEFT_P)  changeDiff(-1);
        if(controls.UI_RIGHT_P) changeDiff(1);

        if(controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new lucas.states.funkin.scripts.menus.FreeplayMenuState());
        }

        if(controls.ACCEPT)
        {
            var song = songs[curSelected];
            var diff:String = song.diffs[curDiffSelected];

            // Tenta carregar o chart via extraSongsJson (assets/data/extra-songs/)
            // Formato do nome: "songname-Diff" ou "songname-diff" (fallback lowercase)
            var loaded:Bool = false;

            // Tentativa 1: diff com case original (ex: "thunderstorm-Pico")
            var chartKey:String = song.songName.toLowerCase() + '-' + diff;
            var chartPath:String = Paths.extraSongsJson(chartKey);

            #if sys
            if(sys.FileSystem.exists(chartPath))
            {
                PlayState.SONG = Song.parseJSON(sys.io.File.getContent(chartPath), chartKey);
                loaded = true;
            }
            #else
            if(openfl.Assets.exists(chartPath))
            {
                PlayState.SONG = Song.parseJSON(openfl.Assets.getText(chartPath), chartKey);
                loaded = true;
            }
            #end

            // Tentativa 2: diff em lowercase (ex: "thunderstorm-pico")
            if(!loaded)
            {
                chartKey  = song.songName.toLowerCase() + '-' + diff.toLowerCase();
                chartPath = Paths.extraSongsJson(chartKey);

                #if sys
                if(sys.FileSystem.exists(chartPath))
                {
                    PlayState.SONG = Song.parseJSON(sys.io.File.getContent(chartPath), chartKey);
                    loaded = true;
                }
                #else
                if(openfl.Assets.exists(chartPath))
                {
                    PlayState.SONG = Song.parseJSON(openfl.Assets.getText(chartPath), chartKey);
                    loaded = true;
                }
                #end
            }

            // Tentativa 3: só o nome da música sem diff (ex: "thunderstorm")
            if(!loaded)
            {
                chartKey  = song.songName.toLowerCase();
                chartPath = Paths.extraSongsJson(chartKey);

                #if sys
                if(sys.FileSystem.exists(chartPath))
                {
                    PlayState.SONG = Song.parseJSON(sys.io.File.getContent(chartPath), chartKey);
                    loaded = true;
                }
                #else
                if(openfl.Assets.exists(chartPath))
                {
                    PlayState.SONG = Song.parseJSON(openfl.Assets.getText(chartPath), chartKey);
                    loaded = true;
                }
                #end
            }

            // Guard: se chart não foi encontrado, avisa e NÃO muda de estado
            // Isso evita o crash "Null Object Reference" no Conductor.mapBPMChanges
            if(!loaded || PlayState.SONG == null)
            {
                FlxG.sound.play(Paths.sound('cancelMenu'));
                trace('[ExtraSongsState] Chart not found for: ${song.songName} (diff: $diff)');
                trace('[ExtraSongsState] Tried path: $chartPath');
                // Exibe aviso visual na tela
                var errTxt:FlxText = new FlxText(0, FlxG.height - 60, FlxG.width,
                    'Chart not found: ${song.songName} [$diff]\nExpected: assets/data/extra-songs/${song.songName.toLowerCase()}-${diff.toLowerCase()}.json', 16);
                errTxt.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.RED, CENTER);
                errTxt.scrollFactor.set();
                errTxt.borderStyle = OUTLINE;
                errTxt.borderColor = FlxColor.BLACK;
                add(errTxt);
                FlxTween.tween(errTxt, {alpha: 0}, 3, {startDelay: 2, onComplete: function(_) errTxt.destroy()});
                return;
            }

            PlayState.isStoryMode = false;
            PlayState.storyDifficulty = curDifficulty;

            FlxG.sound.music.volume = 0;

            if(FlxG.keys.pressed.SHIFT) LoadingState.loadAndSwitchState(new ChartingState());
            else LoadingState.loadAndSwitchState(new PlayState());

            #if ACHIEVEMENTS_ALLOWED
            if(!Achievements.isUnlocked('extra_explorer'))
                Achievements.unlock('extra_explorer');
            #end
        }
        super.update(elapsed);
    }

    function changeDiff(change:Int = 0)
    {
        var song = songs[curSelected];
        curDiffSelected = FlxMath.wrap(curDiffSelected + change, 0, song.diffs.length - 1);
        updateDiffText();
        updateScore();
    }

    function changeSelection(change:Int = 0)
    {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
        curDiffSelected = 0; // reseta diff ao trocar de música

        intendedColor = songs[curSelected].color;
        if(colorTween != null) colorTween.cancel();
        colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {onComplete: function(_) colorTween = null});

        for(i in 0...iconArray.length) iconArray[i].alpha = 0.6;
        iconArray[curSelected].alpha = 1;

        var bullShit:Int = 0;
        for(item in grpSongs.members)
        {
            item.targetY = bullShit - curSelected;
            bullShit++;
            item.alpha = 0.6;
            if(item.targetY == 0) item.alpha = 1;
        }
        Mods.currentModDirectory = songs[curSelected].folder;

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
        var diff:String = song.diffs[curDiffSelected];
        curDifficulty = Difficulty.list.indexOf(diff);
        if(curDifficulty == -1) curDifficulty = 0;
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
}

class ExtraSongMetadata
{
    public var songName:String = "";
    public var week:Int = 0;
    public var songCharacter:String = "";
    public var color:Int = -1;
    public var folder:String = "";
    public var diffs:Array<String> = ["Pico"]; // múltiplas dificuldades

    public function new(song:String, week:Int, songCharacter:String, color:Int, ?diffs:Array<String>)
    {
        this.songName = song;
        this.week = week;
        this.songCharacter = songCharacter;
        this.color = color;
        this.diffs = (diffs != null && diffs.length > 0) ? diffs : ['Pico'];
        this.folder = Mods.currentModDirectory ?? '';
    }
}
#end
