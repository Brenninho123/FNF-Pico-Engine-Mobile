package substates;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxStringUtil;

import states.TitleState;

// Pico Engine
import lucas.states.funkin.scripts.menus.MainMenuState;

class OutdatedSubState extends MusicBeatSubstate
{
	public static var updateVersion:String = '';

	var leftState:Bool = false;
	var bg:FlxSprite;
	var warnText:FlxText;

	var changelogBg:FlxSprite;
	var changelogText:FlxText;
	var changelogScrollY:Float = 0;
	var changelogMaxScroll:Float = 0;
	var scrollBar:FlxSprite;
	var scrollBarBg:FlxSprite;
	static final CHANGELOG_SCROLL_SPEED:Float = 120; // px/s

	override function create()
	{
		super.create();

		// Busca versão mais recente com fallback seguro
		var fetched:String = CoolUtil.checkForUpdates();
		updateVersion = (fetched != null && fetched.length > 0) ? fetched : 'unknown';

		// ── Fundo escuro ─────────────────────────────────────
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.0;
		add(bg);

		// ── Texto de aviso (topo) ─────────────────────────────
		var versionLine:String = updateVersion != 'unknown'
			? 'Press ENTER to update to version $updateVersion'
			: 'Press ENTER to go to the releases page';

		warnText = new FlxText(0, 10, FlxG.width,
			'Looks like you\'re running an outdated version of Pico Engine (${MainMenuState.PicoVersion})\n'
			+ '$versionLine  |  Press ESCAPE to proceed anyway\n'
			+ 'You can disable this warning in Options > "Check for Updates"',
			20);
		warnText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER);
		warnText.scrollFactor.set();
		warnText.alpha = 0.0;
		add(warnText);

		// ── Área do changelog ────────────────────────────────
		var clY:Float    = warnText.y + warnText.height + 14;
		var clHeight:Float = FlxG.height - clY - 14;
		var clWidth:Float  = FlxG.width - 40;

		// Fundo da caixa do changelog
		changelogBg = new FlxSprite(20, clY).makeGraphic(Std.int(clWidth), Std.int(clHeight), 0xFF111111);
		changelogBg.scrollFactor.set();
		changelogBg.alpha = 0.0;
		add(changelogBg);

		// Lê o arquivo Changelog da pasta do jogo
		var clContent:String = loadChangelog();

		changelogText = new FlxText(28, clY + 6, clWidth - 30, clContent, 14);
		changelogText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFDDDDDD, LEFT);
		changelogText.scrollFactor.set();
		changelogText.alpha = 0.0;
		// clipRect limita a área visível ao box do changelog
		changelogText.clipRect = new flixel.math.FlxRect(0, 0, clWidth - 20, clHeight - 6);
		add(changelogText);

		// Barra de scroll (trilho + thumb)
		var barX:Float = 20 + clWidth - 10;
		scrollBarBg = new FlxSprite(barX, clY).makeGraphic(6, Std.int(clHeight), 0xFF333333);
		scrollBarBg.scrollFactor.set();
		scrollBarBg.alpha = 0.0;
		add(scrollBarBg);

		scrollBar = new FlxSprite(barX, clY).makeGraphic(6, 30, FlxColor.WHITE);
		scrollBar.scrollFactor.set();
		scrollBar.alpha = 0.0;
		add(scrollBar);

		// Calcula o máximo de scroll depois do texto ser criado
		changelogMaxScroll = Math.max(0, changelogText.height - clHeight + 12);

		// ── Fade-in ───────────────────────────────────────────
		FlxG.sound.play(Paths.sound('scrollMenu'));
		FlxTween.tween(bg,           { alpha: 0.8 }, 0.6, { ease: FlxEase.sineIn });
		FlxTween.tween(warnText,     { alpha: 1.0 }, 0.6, { ease: FlxEase.sineIn });
		FlxTween.tween(changelogBg,  { alpha: 1.0 }, 0.7, { ease: FlxEase.sineIn });
		FlxTween.tween(changelogText,{ alpha: 1.0 }, 0.7, { ease: FlxEase.sineIn });
		FlxTween.tween(scrollBarBg,  { alpha: 0.8 }, 0.7, { ease: FlxEase.sineIn });
		FlxTween.tween(scrollBar,    { alpha: 0.9 }, 0.7, { ease: FlxEase.sineIn });
	}

	// ── Lê Changelog da pasta raiz do jogo ───────────────────
	function loadChangelog():String
	{
		// Tenta os caminhos mais comuns: sem extensão, .txt, .md
		var candidates:Array<String> = [
			'Changelog',
			'Changelog.txt',
			'Changelog.md',
			'changelog',
			'changelog.txt'
		];

		#if sys
		for (path in candidates)
		{
			if (sys.FileSystem.exists(path))
			{
				try
				{
					var content:String = sys.io.File.getContent(path);
					if (content != null && content.length > 0)
						return content;
				}
				catch (e:haxe.Exception)
				{
					FlxG.log.warn('[OutdatedSubState] Failed to read $path: ${e.message}');
				}
			}
		}
		#end

		// Fallback: avisa que não encontrou
		return '[ Changelog not found ]\n\nPlace a "Changelog" or "Changelog.txt" file\nin the game\'s root folder to display it here.';
	}

	override function update(elapsed:Float)
	{
		if (!leftState)
		{
			// ── Navegação: ENTER abre link, ESC fecha ─────────
			if (controls.ACCEPT && FlxG.keys.justPressed.ENTER)
			{
				leftState = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
				CoolUtil.browserLoad("https://github.com/Pico-Engine-Team/FNF-Pico-Funkin/releases");
				startCloseTween();
			}
			else if (controls.BACK)
			{
				leftState = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				startCloseTween();
			}

			// ── Scroll do changelog (UP/DOWN ou mouse wheel) ──
			if (changelogMaxScroll > 0)
			{
				var scrollDelta:Float = 0;

				if (FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S)
					scrollDelta += CHANGELOG_SCROLL_SPEED * elapsed;
				if (FlxG.keys.pressed.UP || FlxG.keys.pressed.W)
					scrollDelta -= CHANGELOG_SCROLL_SPEED * elapsed;

				// Shift = scroll 4x mais rápido
				if (FlxG.keys.pressed.SHIFT) scrollDelta *= 4;

				// Mouse wheel
				if (FlxG.mouse.wheel != 0)
					scrollDelta -= FlxG.mouse.wheel * 30;

				if (scrollDelta != 0)
				{
					changelogScrollY = FlxMath.bound(changelogScrollY + scrollDelta, 0, changelogMaxScroll);
					updateChangelogScroll();
				}
			}
		}

		super.update(elapsed);
	}

	// Aplica o scroll no clipRect e na scrollbar
	function updateChangelogScroll()
	{
		// Move o texto via clipRect offset (sem mover o sprite)
		var rect = changelogText.clipRect;
		if (rect != null)
		{
			changelogText.clipRect = new flixel.math.FlxRect(
				0,
				changelogScrollY,
				rect.width,
				rect.height
			);
		}

		// Atualiza posição da scrollbar thumb
		if (changelogMaxScroll > 0 && scrollBarBg != null && scrollBar != null)
		{
			var ratio:Float      	= changelogScrollY / changelogMaxScroll;
			var trackHeight:Float 	= scrollBarBg.height - scrollBar.height;
			scrollBar.y          	= scrollBarBg.y + ratio * trackHeight;
		}
	}

	// Fecha com fade-out — persistentUpdate restaurado imediatamente
	function startCloseTween()
	{
		FlxG.state.persistentUpdate = true;

		FlxTween.tween(bg,           { alpha: 0.0 }, 0.9, { ease: FlxEase.sineOut });
		FlxTween.tween(changelogBg,  { alpha: 0.0 }, 0.9, { ease: FlxEase.sineOut });
		FlxTween.tween(scrollBarBg,  { alpha: 0.0 }, 0.9, { ease: FlxEase.sineOut });
		FlxTween.tween(scrollBar,    { alpha: 0.0 }, 0.9, { ease: FlxEase.sineOut });
		FlxTween.tween(changelogText,{ alpha: 0.0 }, 0.9, { ease: FlxEase.sineOut });
		FlxTween.tween(warnText,     { alpha: 0.0 }, 0.9, {
			ease: FlxEase.sineOut,
			onComplete: function(_) { close(); }
		});
	}
}