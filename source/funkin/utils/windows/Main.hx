package funkin.utils.windows;

#if android
import android.content.Context;
#end

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.FlxG;
import flixel.util.FlxColor;
import haxe.io.Path;

import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;

import funkin.play.Highscore;
import funkin.states.TitleState;
import funkin.utils.DebugDisplay as FPSCounter;
import funkin.utils.Native;

#if HSCRIPT_ALLOWED
import funkin.modding.scripting.HScript.HScriptInfos;
import crowplexus.iris.Iris;
#end

#if (linux || mac)
import lime.graphics.Image;
#end

#if desktop
import funkin.utils.ALSoftConfig;
#end

#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end

#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

class Main extends Sprite
{
	public static final game = {
		width: 1280,
		height: 720,
		initialState: TitleState,
		framerate: 60,
		skipSplash: true,
		startFullscreen: false
	};

	public static var fpsVar:FPSCounter;

	public static var storageDirectory(get, never):String;

	static function get_storageDirectory():String
	{
		#if android
		return getAndroidExternalStorage();
		#elseif ios
		return lime.system.System.documentsDirectory + "/";
		#else
		return "./";
		#end
	}

	#if android
	static function getAndroidExternalStorage():String
	{
		final extPath = haxe.JNI.callStaticMethod(
			"android/os/Environment",
			"getExternalStorageDirectory",
			"()Ljava/io/File;"
		);
		if (extPath != null)
		{
			final abs:String = haxe.JNI.callMember(extPath, "getAbsolutePath", "()Ljava/lang/String;");
			if (abs != null && abs.length > 0)
				return abs + "/PicoEngine/";
		}
		return Context.getExternalFilesDir() + "/";
	}
	#end

	static function ensureStorageDirectory(path:String):Void
	{
		#if (sys)
		if (!sys.FileSystem.exists(path))
			sys.FileSystem.createDirectory(path);
		#end
	}

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		#if (cpp && windows)
		Native.fixScaling();
		#end

		#if android
		final extDir = storageDirectory;
		ensureStorageDirectory(extDir);
		Sys.setCwd(extDir);
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0") ['--no-lua'] #end);
		#end

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		Highscore.load();

		#if HSCRIPT_ALLOWED
		setupIrisCallbacks();
		#end

		#if LUA_ALLOWED
		Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(funkin.modding.scripting.psychlua.CallbackHandler.call));
		#end

		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.load();
		#end

		addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		#if desktop
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null)
		{
			fpsVar.visible = (ClientPrefs.data.fpsDisplay != 'Disabled');
			fpsVar.updateBackgroundAlpha(ClientPrefs.data.debugDisplayBG);
		}
		#end

		#if (linux || mac)
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;

		#if desktop
		FlxG.keys.preventDefaultKeys = [TAB];
		#end

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		FlxG.signals.gameResized.add(function(w, h)
		{
			if (FlxG.cameras != null)
			{
				for (cam in FlxG.cameras.list)
				{
					if (cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}
			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	#if HSCRIPT_ALLOWED
	static function setupIrisCallbacks():Void
	{
		Iris.warn = function(x, ?pos:haxe.PosInfos)
		{
			Iris.logLevel(WARN, x, pos);
			final msg = buildIrisMessage(x, pos);
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('WARNING: $msg', FlxColor.YELLOW);
		};
		Iris.error = function(x, ?pos:haxe.PosInfos)
		{
			Iris.logLevel(ERROR, x, pos);
			final msg = buildIrisMessage(x, pos);
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('ERROR: $msg', FlxColor.RED);
		};
		Iris.fatal = function(x, ?pos:haxe.PosInfos)
		{
			Iris.logLevel(FATAL, x, pos);
			final msg = buildIrisMessage(x, pos);
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('FATAL: $msg', 0xFFBB0000);
		};
	}

	static function buildIrisMessage(x:Dynamic, pos:haxe.PosInfos):String
	{
		final newPos:HScriptInfos = cast pos;
		if (newPos.showLine == null)
			newPos.showLine = true;

		var info = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '') + '${newPos.fileName}:';

		#if LUA_ALLOWED
		if (newPos.isLua == true)
		{
			info += 'HScript:';
			newPos.showLine = false;
		}
		#end

		if (newPos.showLine == true)
			info += '${newPos.lineNumber}:';

		return '$info $x';
	}
	#end

	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopImmediatePropagation();

		final callStack:Array<StackItem> = CallStack.exceptionStack(true);
		final dateNow:String = Date.now().toString().replace(" ", "_").replace(":", "-");

		var errMsg = "";
		for (item in callStack)
		{
			switch (item)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
			}
		}
		errMsg += "\nUncaught Error: " + e.error;

		#if officialBuild
		errMsg += "\nPlease report this error: https://github.com/Brenninho123/FNF-Pico-Engine-Mobile/issues";
		#end

		errMsg += "\n\n> Crash Handler written by: sqirra-rng";

		saveCrashLog(dateNow, errMsg);
		showCrashOverlay(errMsg);
	}

	function saveCrashLog(dateNow:String, errMsg:String):Void
	{
		#if (sys)
		final logDir = storageDirectory + "content/logs/";
		ensureStorageDirectory(logDir);
		final path = logDir + "PicoCrashLog-" + dateNow + ".txt";
		try { File.saveContent(path, errMsg + "\n"); } catch (_) {}
		#end
	}

	function showCrashOverlay(errMsg:String):Void
	{
		final overlay = new CrashOverlay(errMsg);
		addChild(overlay);
	}
	#end
}

#if CRASH_HANDLER
class CrashOverlay extends Sprite
{
	var _label:openfl.text.TextField;
	var _bg:openfl.display.Shape;
	var _btnClose:openfl.display.Sprite;
	var _btnContinue:openfl.display.Sprite;

	public function new(message:String)
	{
		super();

		_bg = new openfl.display.Shape();
		_bg.graphics.beginFill(0x000000, 0.88);
		_bg.graphics.drawRect(0, 0, Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);
		_bg.graphics.endFill();
		addChild(_bg);

		_label = new openfl.text.TextField();
		_label.defaultTextFormat = new openfl.text.TextFormat("_sans", 18, 0xFF4444, true);
		_label.width  = Lib.current.stage.stageWidth - 80;
		_label.height = Lib.current.stage.stageHeight - 160;
		_label.x = 40;
		_label.y = 40;
		_label.multiline  = true;
		_label.wordWrap   = true;
		_label.selectable = false;
		_label.text = "A crash was caught and the game kept running.\n\n" + message;
		addChild(_label);

		_btnContinue = makeButton("Continue", 0x226622, 40, Lib.current.stage.stageHeight - 90);
		_btnContinue.addEventListener(openfl.events.MouseEvent.CLICK, function(_) { parent.removeChild(this); });
		addChild(_btnContinue);

		_btnClose = makeButton("Exit Game", 0x882222, 240, Lib.current.stage.stageHeight - 90);
		_btnClose.addEventListener(openfl.events.MouseEvent.CLICK, function(_)
		{
			#if DISCORD_ALLOWED
			DiscordClient.shutdown();
			#end
			Sys.exit(0);
		});
		addChild(_btnClose);
	}

	function makeButton(label:String, color:Int, x:Float, y:Float):openfl.display.Sprite
	{
		final s = new openfl.display.Sprite();
		s.graphics.beginFill(color);
		s.graphics.drawRoundRect(0, 0, 180, 50, 12, 12);
		s.graphics.endFill();

		final tf = new openfl.text.TextField();
		tf.defaultTextFormat = new openfl.text.TextFormat("_sans", 16, 0xFFFFFF, true);
		tf.width  = 180;
		tf.height = 50;
		tf.text   = label;
		tf.selectable = false;
		tf.mouseEnabled = false;
		s.addChild(tf);

		s.x = x;
		s.y = y;
		s.buttonMode  = true;
		s.useHandCursor = true;
		return s;
	}
}
#end
