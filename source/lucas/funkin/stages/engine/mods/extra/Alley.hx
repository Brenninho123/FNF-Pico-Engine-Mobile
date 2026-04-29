package lucas.funkin.stages.engine.mods;

class Alley extends BaseStage
{
    var bg:BGSprite;
    var bg2:BGSprite;
    var floor:BGSprite;
    var fg:BGSprite;
    override function create()
    {
        bg = new BGSprite('Alleys/Hypno/BACKGROUND', -300, -600);
        add(bg);

        bg2 = new BGSprite('Alleys/Hypno/Behind the clouds and fence', -300, -600);
        add(bg2);

        floor = new BGSprite('Alleys/Hypno/Behind the Fence', -300, -600);
        add(floor);

        fg = new BGSprite('Alleys/Hypno/Hypno bg foreground', -300, -600);
        add(fg);
    }
}