package states.editors;

import haxe.Json;
import openfl.utils.Assets;
import flixel.graphics.frames.FlxAtlasFrames;
import backend.ui.PsychUIBox;
import backend.ui.PsychUIInputText;
import backend.ui.PsychUIButton;
import backend.ui.PsychUINumericStepper;
import backend.ui.PsychUICheckBox;
import backend.ui.PsychUIDropDownMenu;

import objects.Note;
import objects.StrumNote;

import states.editors.content.Prompt;

typedef NoteStyleData =
{
	var name:String;
	@:optional var author:String;
	@:optional var fallback:String;
	@:optional var assets:NoteStyleAssets;
}

typedef NoteStyleAssets =
{
	@:optional var note:NoteAssetData;
	@:optional var holdNote:NoteAssetData;
	@:optional var splash:NoteAssetData;
	@:optional var strumline:NoteAssetData;
}

typedef NoteAssetData =
{
	@:optional var assetPath:String;
	@:optional var atlasType:String;
	@:optional var scale:Float;
	@:optional var isPixel:Bool;
	@:optional var offsets:Array<Float>;
	@:optional var animations:Array<NoteStyleAnim>;
}

typedef NoteStyleAnim =
{
	var name:String;
	var prefix:String;
	@:optional var fps:Int;
	@:optional var loop:Bool;
	@:optional var indices:Array<Int>;
	@:optional var offsets:Array<Float>;
}

class NoteStyleEditorState extends MusicBeatState
{
	public var id:String;
	var _data:NoteStyleData;

	var UI_infoBox:PsychUIBox;
	var UI_mainbox:PsychUIBox;
	var idInput:PsychUIInputText;
	var nameInput:PsychUIInputText;
	var authorInput:PsychUIInputText;
	var animationPasteInput:PsychUIInputText;

	var _fallback(get, never):Null<NoteStyleEditorState>;
	function get__fallback():Null<NoteStyleEditorState>
	{
		if(_data?.fallback == null || _data.fallback.length < 1) return null;
		return NoteStyleEditorState.load(_data.fallback);
	}

	var previewNote:Note;
	var previewStrum:StrumNote;

	function new(id:String, data:NoteStyleData)
	{
		this.id = id;
		_data   = data;
		super();
	}

	override function create():Void
	{
		super.create();

		FlxG.mouse.visible = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Note Style Editor');
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/bg/menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF505050;
		add(bg);

		addEditorUI();

		var exitText:FlxText = new FlxText(20, FlxG.height - 40, 280, "Press ESC to return");
		exitText.setFormat(null, 12, FlxColor.YELLOW);
		add(exitText);

		var convertText:FlxText = new FlxText(20, FlxG.height - 70, 500, "Press C to convert from FNF Base | Press S to save | Press P for preview");
		convertText.setFormat(null, 10, FlxColor.LIME);
		add(convertText);

		createPreview();
	}

	function addEditorUI():Void
	{
		// Upper Box com File - Copiado do ChartingState
		var upperBox:PsychUIBox = new PsychUIBox(10, 10, 320, 200, ["File"]);
		upperBox.canMove = upperBox.canMinimize = true;
		add(upperBox);

		// Aba File - Funcionalidades de arquivo
		addFileTab(upperBox);

		// Main Box com abas adicionais - Copiado e adaptado do NoteSplashEditorState
		var mainBox:PsychUIBox = new PsychUIBox(350, 10, 500, 500, ["Animations", "Properties", "Shaders"]);
		mainBox.canMove = mainBox.canMinimize = true;
		add(mainBox);

		// Aba Animations - Copiada do NoteSplashEditorState
		addAnimTab(mainBox);

		// Aba Properties - Copiada do NoteSplashEditorState
		addPropertiesTab(mainBox);

		// Aba Shaders - Copiada do NoteSplashEditorState
		addShadersTab(mainBox);

		// Info Box (mantém a existente)
		UI_infoBox = new PsychUIBox(10, 230, 320, 200, ["Note Style Info"]);
		UI_infoBox.canMove = UI_infoBox.canMinimize = true;
		add(UI_infoBox);

		var tabInfo = UI_infoBox.getTab('Note Style Info').menu;
		var iy:Int = 10;

		tabInfo.add(new FlxText(10, iy, 0, 'ID:', 10));
		idInput = new PsychUIInputText(10, iy + 14, 250, id, 8);
		idInput.onChange = function(old, value) { id = value; };
		tabInfo.add(idInput);
		iy += 40;

		tabInfo.add(new FlxText(10, iy, 0, 'Name:', 10));
		nameInput = new PsychUIInputText(10, iy + 14, 250, getName(), 8);
		nameInput.onChange = function(old, value) { _data.name = value; };
		tabInfo.add(nameInput);
		iy += 40;

		tabInfo.add(new FlxText(10, iy, 0, 'Author:', 10));
		authorInput = new PsychUIInputText(10, iy + 14, 250, getAuthor(), 8);
		authorInput.onChange = function(old, value) { _data.author = value; };
		tabInfo.add(authorInput);

		// Functions Box (mantém a existente)
		UI_mainbox = new PsychUIBox(FlxG.width - 360, 10, 350, 260, ['Functions']);
		UI_mainbox.canMove = UI_mainbox.canMinimize = true;
		add(UI_mainbox);

		var funcTab = UI_mainbox.getTab('Functions').menu;
		funcTab.add(new FlxText(10, 10, 0, 'ID/Name/Author functions:', 10));
		funcTab.add(new FlxText(10, 28, 0, 'Use the left box to edit values.', 8));
		funcTab.add(new FlxText(10, 40, 0, 'C = convert from FNF base', 8));
		funcTab.add(new FlxText(10, 52, 0, 'S = save current style', 8));
		funcTab.add(new FlxText(10, 64, 0, 'P = refresh preview', 8));
	}

	// Função copiada e adaptada do ChartingState
	function addFileTab(upperBox:PsychUIBox):Void
	{
		var tab = upperBox.getTab('File');
		var tab_group = tab.menu;
		var btnX = tab.x - upperBox.x;
		var btnY = 1;
		var btnWid = Std.int(tab.width);

		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  New', function()
		{
			var func:Void->Void = function()
			{
				_data = {name: 'New Style', author: 'Unknown'};
				id = 'new-style';
				createPreview();
				showOutput('New note style created!');
			}

			openSubState(new Prompt('Create new note style?', func));
		}, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY++;
		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Open Style...', function()
		{
			// TODO: Implementar abertura de arquivo de estilo
			showOutput('Open Style functionality not implemented yet', true);
		}, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Save', function()
		{
			saveNoteStyle();
		}, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Save as...', function()
		{
			// TODO: Implementar save as
			showOutput('Save As functionality not implemented yet', true);
		},btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);
	}

	// Função copiada e adaptada do NoteSplashEditorState
	function addAnimTab(mainBox:PsychUIBox):Void
	{
		var UI = mainBox.getTab("Animations").menu;

		UI.add(new FlxText(20, 20, 0, "Animation Name:", 8));
		var name_input:PsychUIInputText = new PsychUIInputText(20, 37.5, 120, "", 8);
		UI.add(name_input);

		UI.add(new FlxText(name_input.x, name_input.y + 30, 0, "Animation Prefix:", 8));
		var prefix_input:PsychUIInputText = new PsychUIInputText(20, name_input.y + 47.5, 120, "", 8);
		UI.add(prefix_input);

		UI.add(new FlxText(160, 20, 0, "Note Data:"));
		var numericStepperData = new PsychUINumericStepper(160, 37.5, 1, 0, 0, 3, 0);
		UI.add(numericStepperData);

		UI.add(new FlxText(160, name_input.y + 30, 0, "Indices (OPTIONAL):"));
		var indices_input:PsychUIInputText = new PsychUIInputText(160, name_input.y + 47.5, 120, "", 8);
		UI.add(indices_input);

		UI.add(new FlxText(20, 110, 0, "Minimum FPS:"));
		var minFps:PsychUINumericStepper = new PsychUINumericStepper(20, 127.5, 1, 22, 1, 120);
		UI.add(minFps);

		UI.add(new FlxText(160, 110, 0, "Maximum FPS:"));
		var maxFps:PsychUINumericStepper = new PsychUINumericStepper(160, 127.5, 1, 26, 1, 120);
		UI.add(maxFps);

		var animDropDown = new PsychUIDropDownMenu(-155, 57, [""], function(id:Int, name:String)
		{
			if (name.length > 0)
			{
				var anims = getNoteAnimations();
				for (anim in anims)
				{
					if (anim.name == name)
					{
						name_input.text = name;
						prefix_input.text = anim.prefix;
						numericStepperData.value = 0; // Note data não é usado no NoteStyle
						minFps.value = anim.fps != null ? anim.fps : 24;
						maxFps.value = anim.fps != null ? anim.fps : 24;
						if (anim.indices != null && anim.indices.length > 0)
							indices_input.text = anim.indices.toString().substring(1, anim.indices.toString().length - 2);
						break;
					}
				}
			}
		});

		function setAnimDropDown()
		{
			var anims:Array<String> = [];
			var currentAnims = getNoteAnimations();
			for (anim in currentAnims)
			{
				anims.push(anim.name);
			}

			if (anims.length < 1)
				anims.push("");

			animDropDown.list = anims;
		}

		setAnimDropDown();
		UI.add(animDropDown);

		var addAnimBtn:PsychUIButton = new PsychUIButton(20, 170, 'Add Animation', function()
		{
			if (name_input.text.length > 0 && prefix_input.text.length > 0)
			{
				if (_data.assets == null) _data.assets = {};
				if (_data.assets.note == null) _data.assets.note = {assetPath: Note.defaultNoteSkin, atlasType: 'auto', scale: 1.0, isPixel: false};

				var indices:Array<Int> = null;
				if (indices_input.text.length > 0)
				{
					indices = [];
					var parts = indices_input.text.split(',');
					for (part in parts)
					{
						var num = Std.parseInt(part.trim());
						if (num != null) indices.push(num);
					}
				}

				var newAnim:NoteStyleAnim = {
					name: name_input.text,
					prefix: prefix_input.text,
					fps: Std.int(minFps.value),
					indices: indices
				};

				if (_data.assets.note.animations == null) _data.assets.note.animations = [];
				_data.assets.note.animations.push(newAnim);

				setAnimDropDown();
				createPreview();
				showOutput('Animation "${name_input.text}" added!');
			}
		});
		UI.add(addAnimBtn);

		var removeAnimBtn:PsychUIButton = new PsychUIButton(160, 170, 'Remove Animation', function()
		{
			if (animDropDown.selectedLabel.length > 0)
			{
				if (_data.assets?.note?.animations != null)
				{
					_data.assets.note.animations = _data.assets.note.animations.filter(function(anim) return anim.name != animDropDown.selectedLabel);
					setAnimDropDown();
					createPreview();
					showOutput('Animation "${animDropDown.selectedLabel}" removed!');
				}
			}
		});
		UI.add(removeAnimBtn);
	}

	// Função copiada e adaptada do NoteSplashEditorState
	function addPropertiesTab(mainBox:PsychUIBox):Void
	{
		var ui = mainBox.getTab("Properties").menu;

		ui.add(new FlxText(20, 10, 0, "Asset Path:"));
		var assetPathInput = new PsychUIInputText(20, 27.5, 200, getNoteAssetPath() ?? '', 8);
		assetPathInput.onChange = function(old, value) {
			if(_data.assets == null) _data.assets = {};
			if(_data.assets.note == null) _data.assets.note = {assetPath: value, atlasType: 'auto', scale: 1.0, isPixel: false};
			_data.assets.note.assetPath = value;
		};
		ui.add(assetPathInput);

		ui.add(new FlxText(240, 10, "Atlas Type:"));
		var atlasTypeInput = new PsychUIInputText(240, 27.5, 80, getNoteAtlasType(), 8);
		atlasTypeInput.onChange = function(old, value) {
			if(_data.assets?.note != null) _data.assets.note.atlasType = value;
		};
		ui.add(atlasTypeInput);

		ui.add(new FlxText(20, 60, "Scale:"));
		var scaleNumericStepper = new PsychUINumericStepper(20, 77.5, 0.1, getNoteScale(), 0, 4, 2, 80);
		scaleNumericStepper.onValueChange = function() {
			if(_data.assets?.note != null) _data.assets.note.scale = scaleNumericStepper.value;
		};
		ui.add(scaleNumericStepper);

		ui.add(new FlxText(140, 60, "Offsets X:"));
		var offsetXInput = new PsychUIInputText(140, 77.5, 60, Std.string(getNoteOffsets()[0]), 8);
		offsetXInput.onChange = function(old, value) {
			var offset = Std.parseFloat(value);
			if(!Math.isNaN(offset) && _data.assets?.note != null) {
				if (_data.assets.note.offsets == null) _data.assets.note.offsets = [0.0, 0.0];
				_data.assets.note.offsets[0] = offset;
			}
		};
		ui.add(offsetXInput);

		ui.add(new FlxText(220, 60, "Y:"));
		var offsetYInput = new PsychUIInputText(220, 77.5, 60, Std.string(getNoteOffsets()[1]), 8);
		offsetYInput.onChange = function(old, value) {
			var offset = Std.parseFloat(value);
			if(!Math.isNaN(offset) && _data.assets?.note != null) {
				if (_data.assets.note.offsets == null) _data.assets.note.offsets = [0.0, 0.0];
				_data.assets.note.offsets[1] = offset;
			}
		};
		ui.add(offsetYInput);

		var allowPixelCheck:PsychUICheckBox = new PsychUICheckBox(20, 110, "Is Pixel?", 80);
		allowPixelCheck.onClick = function() {
			if (_data.assets?.note != null)
				_data.assets.note.isPixel = allowPixelCheck.checked;
		};
		allowPixelCheck.checked = isNotePixel();
		ui.add(allowPixelCheck);

		var reloadButton:PsychUIButton = new PsychUIButton(20, 140, "Reload Preview", function()
		{
			createPreview();
		});
		ui.add(reloadButton);

		var saveButton:PsychUIButton = new PsychUIButton(140, 140, "Save Style", function()
		{
			saveNoteStyle();
		});
		ui.add(saveButton);
	}

	// Função copiada e adaptada do NoteSplashEditorState
	function addShadersTab(mainBox:PsychUIBox):Void
	{
		var tab = mainBox.getTab("Shaders").menu;

		tab.add(new FlxText(20, 10, 0, "RGB Shader Settings:", 10));
		tab.add(new FlxText(20, 30, 0, "Note: RGB shaders are not", 8));
		tab.add(new FlxText(20, 42, 0, "currently supported in", 8));
		tab.add(new FlxText(20, 54, 0, "NoteStyle system.", 8));

		// Placeholder para futuras implementações de shader
		var enableRGBCheck:PsychUICheckBox = new PsychUICheckBox(20, 80, "Enable RGB Shader", 120);
		enableRGBCheck.checked = false;
		enableRGBCheck.onClick = function() {
			showOutput('RGB Shader support coming soon!', true);
		};
		tab.add(enableRGBCheck);

		var rgbPresetDropDown = new PsychUIDropDownMenu(20, 110, ["Default", "Rainbow", "Neon", "Pastel"], function(id:Int, name:String)
		{
			showOutput('RGB preset "${name}" selected (not implemented yet)', true);
		});
		tab.add(rgbPresetDropDown);
	}

	// Função auxiliar para mostrar mensagens (copiada do ChartingState)
	function showOutput(text:String, isError:Bool = false):Void
	{
		trace('[NoteStyle] ${isError ? 'ERROR' : 'INFO'}: $text');
		// TODO: Implementar sistema de output visual
	}
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if(FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.sound.music.fadeOut(0.3, 0);
			MusicBeatState.switchState(new MasterEditorState());
		}

		if(FlxG.keys.justPressed.C)
		{
			convertFromFNFBase();
		}

		if(FlxG.keys.justPressed.S)
		{
			saveNoteStyle();
		}

		if(FlxG.keys.justPressed.P)
		{
			createPreview();
		}
	}

	/**
	 * Converte as notas padrão do FNF para o novo formato NoteStyle
	 */
	function convertFromFNFBase():Void
	{
		trace('[NoteStyle] Convertendo de NOTE_assets...');

		var newData:NoteStyleData = {
			name: id,
			author: 'Converted from FNF Base',
			assets: {
				note: {
					assetPath: 'noteSkins/NOTE_assets',
					atlasType: 'sparrow',
					scale: 0.7,
					isPixel: false,
					offsets: [0, 0],
					animations: [
						{name: 'greenScroll', prefix: 'green instance'},
						{name: 'redScroll', prefix: 'red instance'},
						{name: 'purpleScroll', prefix: 'purple instance'},
						{name: 'blueScroll', prefix: 'blue instance'},
						{name: 'greenPress', prefix: 'green confirm'},
						{name: 'redPress', prefix: 'red confirm'},
						{name: 'purplePress', prefix: 'purple confirm'},
						{name: 'bluePress', prefix: 'blue confirm'},
						{name: 'preslideBlueScroll', prefix: 'preslide blue instance'},
						{name: 'preslideGreenScroll', prefix: 'preslide green instance'},
						{name: 'preslidePurpleScroll', prefix: 'preslide purple instance'},
						{name: 'preslideRedScroll', prefix: 'preslide red instance'}
					]
				},
				holdNote: {
					assetPath: 'noteSkins/NOTE_assets',
					atlasType: 'sparrow',
					scale: 0.7,
					isPixel: false,
					offsets: [0, 0],
					animations: [
						{name: 'greenHold', prefix: 'green hold piece'},
						{name: 'greenEnd', prefix: 'green hold end'},
						{name: 'redHold', prefix: 'red hold piece'},
						{name: 'redEnd', prefix: 'red hold end'},
						{name: 'purpleHold', prefix: 'purple hold piece'},
						{name: 'purpleEnd', prefix: 'purple hold end'},
						{name: 'blueHold', prefix: 'blue hold piece'},
						{name: 'blueEnd', prefix: 'blue hold end'}
					]
				},
				strumline: {
					assetPath: 'noteSkins/NOTE_assets',
					atlasType: 'sparrow',
					scale: 0.7,
					isPixel: false,
					offsets: [0, 0],
					animations: [
						{name: 'greenStatic', prefix: 'green static'},
						{name: 'greenPress', prefix: 'green pressed'},
						{name: 'greenConfirm', prefix: 'green confirm'},
						{name: 'redStatic', prefix: 'red static'},
						{name: 'redPress', prefix: 'red pressed'},
						{name: 'redConfirm', prefix: 'red confirm'},
						{name: 'purpleStatic', prefix: 'purple static'},
						{name: 'purplePress', prefix: 'purple pressed'},
						{name: 'purpleConfirm', prefix: 'purple confirm'},
						{name: 'blueStatic', prefix: 'blue static'},
						{name: 'bluePress', prefix: 'blue pressed'},
						{name: 'blueConfirm', prefix: 'blue confirm'}
					]
				}
			}
		};

		// Atualizar os dados
		_data = newData;
		id = 'fnf-base-converted';

		trace('[NoteStyle] Conversão completa! Pressione S para salvar.');
		createPreview();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	/**
	 * Salva o NoteStyle atual em um arquivo JSON
	 */
	function saveNoteStyle():Void
	{
		try
		{
			var json:String = haxe.Json.stringify(_data, null, '\t');
			var path:String = 'data/notestyles/$id.json';

			#if MODS_ALLOWED
			if(!sys.FileSystem.exists('data/notestyles'))
				sys.FileSystem.createDirectory('data/notestyles');

			sys.io.File.saveContent(path, json);
			trace('[NoteStyle] Salvo em: $path');
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			#else
			trace('[NoteStyle] Salvar não é suportado nesta plataforma');
			#end
		}
		catch(e)
		{
			trace('[NoteStyle] Erro ao salvar: $e');
		}
	}

	public static function load(id:String):Null<NoteStyleEditorState>
	{
		var path:String = Paths.getPath('data/notestyles/$id.json', TEXT, null, true);
		var rawData:String = null;

		#if MODS_ALLOWED
		if(sys.FileSystem.exists(path))
			rawData = sys.io.File.getContent(path);
		else
		#end
		if(Assets.exists(path))
			rawData = Assets.getText(path);

		if(rawData == null)
		{
			trace('[NoteStyle] Not found: $id');
			return null;
		}

		try
		{
			var data:NoteStyleData = cast Json.parse(rawData);
			return new NoteStyleEditorState(id, data);
		}
		catch(e)
		{
			trace('[NoteStyle] Error parsing $id: $e');
			return null;
		}
	}

	public static function loadDefault():NoteStyleEditorState
		return load('default') ?? new NoteStyleEditorState('default', {name: 'funkin'});

	public function getName():String    return _data?.name   ?? _fallback?.getName()   ?? id;
	public function getAuthor():String  return _data?.author ?? _fallback?.getAuthor() ?? 'Unknown';
	public function getFallbackID():Null<String> return _data?.fallback;

	public function getNoteAssetPath():Null<String>       return _data?.assets?.note?.assetPath  ?? _fallback?.getNoteAssetPath();
	public function getNoteAtlasType():String             return _data?.assets?.note?.atlasType  ?? _fallback?.getNoteAtlasType() ?? 'auto';
	public function getNoteScale():Float                  return _data?.assets?.note?.scale      ?? _fallback?.getNoteScale()     ?? 1.0;
	public function isNotePixel():Bool                    return _data?.assets?.note?.isPixel    ?? _fallback?.isNotePixel()      ?? false;
	public function getNoteOffsets():Array<Float>         return _data?.assets?.note?.offsets    ?? _fallback?.getNoteOffsets()   ?? [0.0, 0.0];
	public function getNoteAnimations():Array<NoteStyleAnim> return _data?.assets?.note?.animations ?? _fallback?.getNoteAnimations() ?? [];

	public function getHoldNoteAssetPath():Null<String>   return _data?.assets?.holdNote?.assetPath ?? _fallback?.getHoldNoteAssetPath();
	public function getHoldNoteAtlasType():String         return _data?.assets?.holdNote?.atlasType ?? _fallback?.getHoldNoteAtlasType() ?? 'auto';
	public function getHoldNoteScale():Float              return _data?.assets?.holdNote?.scale     ?? _fallback?.getHoldNoteScale()     ?? 1.0;
	public function isHoldNotePixel():Bool                return _data?.assets?.holdNote?.isPixel   ?? _fallback?.isHoldNotePixel()      ?? false;

	public function getSplashAssetPath():Null<String>     return _data?.assets?.splash?.assetPath ?? _fallback?.getSplashAssetPath();
	public function getSplashAtlasType():String           return _data?.assets?.splash?.atlasType ?? _fallback?.getSplashAtlasType() ?? 'auto';
	public function getSplashScale():Float                return _data?.assets?.splash?.scale     ?? _fallback?.getSplashScale()     ?? 1.0;
	public function getSplashAnimations():Array<NoteStyleAnim> return _data?.assets?.splash?.animations ?? _fallback?.getSplashAnimations() ?? [];

	public function getStrumlineAssetPath():Null<String>  return _data?.assets?.strumline?.assetPath ?? _fallback?.getStrumlineAssetPath();
	public function getStrumlineAtlasType():String        return _data?.assets?.strumline?.atlasType ?? _fallback?.getStrumlineAtlasType() ?? 'auto';
	public function getStrumlineScale():Float             return _data?.assets?.strumline?.scale     ?? _fallback?.getStrumlineScale()     ?? 1.0;
	public function isStrumlinePixel():Bool               return _data?.assets?.strumline?.isPixel   ?? _fallback?.isStrumlinePixel()      ?? false;

	// ── Atlas Loader (suporta xml, txt e json) ───────────

	/**
	 * Carrega um NoteStyle a partir de um JSON string
	 */
	public static function convertFromJson(jsonString:String):Null<NoteStyleData>
	{
		try
		{
			return cast haxe.Json.parse(jsonString);
		}
		catch(e)
		{
			trace('[NoteStyle] Erro ao fazer parse do JSON: $e');
			return null;
		}
	}

	/**
	 * Cria uma preview das notas convertidas
	 */
	function createPreview():Void
	{
		if(previewNote != null) remove(previewNote);
		if(previewStrum != null) remove(previewStrum);

		try
		{
			previewNote = new Note(0, 0, null, false, true);
			previewNote.setPosition(FlxG.width / 2 - 100, 150);
			applyToNote(previewNote);
			add(previewNote);

			previewStrum = new StrumNote(FlxG.width / 2 + 100, 150, 0, 0);
			applyToStrumNote(previewStrum);
			add(previewStrum);

			trace('[NoteStyle] Preview criado com sucesso');
		}
		catch(e)
		{
			trace('[NoteStyle] Erro ao criar preview: $e');
		}
	}

	function applyAnimationPaste():Void
	{
		if(animationPasteInput == null || animationPasteInput.text == null) return;
		var raw:String = animationPasteInput.text.trim();
		if(raw.length == 0) return;

		var lines:Array<String> = raw.split(';');
		var animations:Array<NoteStyleAnim> = [];

		for(line in lines)
		{
			var value:String = line.trim();
			if(value.length == 0) continue;

			var parts:Array<String> = value.split(':');
			if(parts.length < 2) parts = value.split('|');
			if(parts.length < 2) parts = value.split(',');
			if(parts.length < 2) continue;

			var name:String = parts[0].trim();
			var prefix:String = parts[1].trim();
			animations.push({name: name, prefix: prefix});
		}

		if(_data.assets == null) _data.assets = {};
		if(_data.assets.note == null) _data.assets.note = {assetPath: Note.defaultNoteSkin, atlasType: 'sparrow', scale: 1.0, isPixel: false};
		_data.assets.note.animations = animations;

		trace('[NoteStyle] Applied ' + animations.length + ' animation(s) from paste.');
		createPreview();
	}
	/**
	 * Carrega o atlas de frames detectando automaticamente o formato:
	 * - .xml  → Sparrow (padrão do Psych Engine)
	 * - .txt  → Sprite Sheet Packer
	 * - .json → TexturePacker JSON (formato V-Slice)
	 * 
	 * O parâmetro atlasType pode ser 'sparrow', 'packer', 'json' ou 'auto'.
	 */
	public static function loadAtlas(assetPath:String, ?atlasType:String = 'auto'):Null<FlxAtlasFrames>
	{
		if(assetPath == null || assetPath.length < 1) return null;

		var type:String = atlasType ?? 'auto';

		// Detecção automática pelo arquivo existente
		if(type == 'auto')
		{
			if(Paths.fileExists('images/$assetPath.xml',  TEXT))  type = 'sparrow';
			else if(Paths.fileExists('images/$assetPath.json', TEXT))  type = 'json';
			else if(Paths.fileExists('images/$assetPath.txt',  TEXT))  type = 'packer';
			else type = 'sparrow';
		}

		return switch(type)
		{
			case 'json':
				Paths.getAsepriteAtlas(assetPath);
			case 'packer':
				Paths.getPackerAtlas(assetPath);
			default:
				Paths.getSparrowAtlas(assetPath);
		}
	}

	public function applyToNote(note:Note):Void
	{
		var assetPath = getNoteAssetPath();
		if(assetPath == null || assetPath.length < 1) return;

		var frames = loadAtlas(assetPath, getNoteAtlasType());
		if(frames == null)
		{
			trace('[NoteStyle] Could not load note atlas: $assetPath');
			return;
		}

		note.frames = frames;
		note.antialiasing = ClientPrefs.data.antialiasing && !isNotePixel();

		var scale = getNoteScale();
		note.scale.set(scale, scale);
		note.updateHitbox();

		var offsets = getNoteOffsets();
		note.offset.set(offsets[0], offsets[1]);

		for(anim in getNoteAnimations())
		{
			var fps:Int   = anim.fps  != null ? anim.fps  : 24;
			var loop:Bool = anim.loop != null ? anim.loop : false;
			if(anim.indices != null && anim.indices.length > 0)
				note.animation.addByIndices(anim.name, anim.prefix, anim.indices, '', fps, loop);
			else
				note.animation.addByPrefix(anim.name, anim.prefix, fps, loop);
		}
	}

	public function applyToStrumNote(strum:StrumNote):Void
	{
		var assetPath = getStrumlineAssetPath();
		if(assetPath == null || assetPath.length < 1) return;

		var frames = loadAtlas(assetPath, getStrumlineAtlasType());
		if(frames == null)
		{
			trace('[NoteStyle] Could not load strumline atlas: $assetPath');
			return;
		}

		strum.frames = frames;
		strum.antialiasing = ClientPrefs.data.antialiasing && !isStrumlinePixel();

		var scale = getStrumlineScale();
		strum.scale.set(scale, scale);
		strum.updateHitbox();
	}

	override public function toString():String return 'NoteStyle($id)';
}