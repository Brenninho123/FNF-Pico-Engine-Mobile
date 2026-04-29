package lucas.funkin.stages.vslice.mods.extra;

import substates.GameOverSubstate;

class WhittyAlley extends BaseStage
{
    var bg:BGSprite;
    var bg2:BGSprite;
    override function create()
    {
        var bg:BGSprite = new BGSprite('Alleys/Whitty/whittyBack', -400, -130);
        bg.scrollFactor.set(1.0, 1.0);
        add(bg);

        var bg2:BGSprite = new BGSprite('Alleys/Whitty/whittyFront', -300, 670);
        bg2.scrollFactor.set(1.0, 1.0);
        add(bg2);
    }
}