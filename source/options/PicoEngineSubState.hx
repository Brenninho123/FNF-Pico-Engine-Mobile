package options;

class PicoEngineSubState extends BaseOptionsMenu
{
	public function new() {
    title = Language.getPhrase("pico_menu","Pico Engine Settings W.I.P");
    rpcTitle = "Pico Engine Settings Menu W.I.P";

{
		var option:Option = new Option('Characters Note Skins',
			"If checked, Enables (Character Specific) NoteSkins In Songs",
			'noteskinsCharacters',
			STRING,
			['Player','Opponent','Both']);
		addOption(option);
		
        var option:Option = new Option('Max Combo',
		'Enable/Disable Max Combo on the game screen.',
		'comboEnabled',
		BOOL);
	    addOption(option);

		var option:Option = new Option('V-Slice Hub',
		'If checked, using the HUD for V-Slice.',
		'hub',
		BOOL);
		addOption(option);

		var option:Option = new Option('Hold Note (W.I.P)',
		'Enable/Disable to prevent characters from performing hold animations during music.',
		'hold',
		BOOL);
		addOption(option);
		super();
		}
	}
}