package lucas.funkin.stages.engine.mods.bonus.exe;

import substates.GameOverSubstate;

class HillZone extends BaseStage
{
    var bg:BGSprite;
    var TooSlowTrees:BGSprite;
    var TooSlowTreesFront:BGSprite;
    var TooSlowTreesLeft:BGSprite;
    var TooSlowTreesMid:BGSprite;
    var TooSlowTreesMidBack:BGSprite;
    var TooSlowTreesRight:BGSprite;
    var TooSlowGroundBG:BGSprite;
    var TooSlowGround:BGSprite;
    var TooSlowKnux:BGSprite;
    var TooSlowEgg:BGSprite;
    var TooSlowTopOverlay:BGSprite;
    var Tailshead:BGSprite;
    var tail1:BGSprite;
    var tail2:BGSprite;
    override function create()
    {
        PlayState.SONG.splashSkin = "noteSplashes/data/characters/noteSplashes-blood";

        bg = new BGSprite('exe/Hill/BGSky', -800, -550);
        bg.scrollFactor.set(0.9, 0.9);
        bg.scale.set(1.305, 1.305);
        add(bg);

        TooSlowTrees = new BGSprite('exe/Hill/BGSky', -800, -250);
        TooSlowTrees.scale.set(1.1, 1);
        add(TooSlowTrees);

        TooSlowTreesFront = new BGSprite('exe/Hill/BGSky', -650, -300);
        TooSlowTreesFront.scrollFactor.set(1.1, 1);
        add(TooSlowTreesFront);

        TooSlowTreesLeft = new BGSprite('exe/Hill/BGSky', -850, -350);
        TooSlowTreesLeft.scrollFactor.set(0.95, 0.95);
        TooSlowTreesLeft.scale.set(1.25, 1.25);
        add(TooSlowTreesLeft);

        TooSlowTreesMid = new BGSprite('exe/Hill/BGSky', -800, -550);
        TooSlowTreesMid.scrollFactor.set(0.9, 0.9);
        TooSlowTreesMid.scale.set(1.25, 1.25);
        add(TooSlowTreesMid);

        TooSlowTreesMidBack = new BGSprite('exe/Hill/BGSky', -800, -550);
        TooSlowTreesMidBack.scrollFactor.set(0.85, 0.95);
        TooSlowTreesMidBack.scale.set(1.25, 1.25);
        add(TooSlowTreesMidBack);

        TooSlowTreesRight= new BGSprite('exe/Hill/BGSky', -650, -350);
        TooSlowTreesRight.scrollFactor.set(0.95, 0.95);
        TooSlowTreesRight.scale.set(1.25, 1.25);
        add(TooSlowTreesRight);

        TooSlowGroundBG = new BGSprite('exe/Hill/BGSky', -1000, -400);
        TooSlowGroundBG.scale.set(1.45, 1.45);
        add(TooSlowGroundBG);

        TooSlowGround = new BGSprite('exe/Hill/BGSky', -1000, -350);
        TooSlowGround.scale.set(1.405, 1.405);
        add(TooSlowGround);

        TooSlowKnux = new BGSprite('exe/Hill/BGSky', -1050, -400);
        TooSlowKnux.scale.set(1.405, 1.405);
        add(TooSlowKnux);

        TooSlowEgg = new BGSprite('exe/Hill/BGSky', -950, -400);
        TooSlowEgg.scale.set(1.405, 1.405);
        add(TooSlowEgg);

        TooSlowTopOverlay = new BGSprite('exe/Hill/BGSky', -920, -400);
        TooSlowTopOverlay.scrollFactor.set(1.1, 1.1);
        TooSlowTopOverlay.scale.set(1.45, 1.45);
        add(TooSlowTopOverlay);

        Tailshead = new BGSprite('exe/Hill/BGSky', -1000, -300);
        Tailshead.scrollFactor.set(1, 1);
        Tailshead.scale.set(1.35, 1.35);
        add(Tailshead);
        
        tail1 = new BGSprite('exe/Hill/BGSky', -920, -400);
        tail1.scrollFactor.set(1, 1);
        tail1.scale.set(1.35, 1.35);
        add(tail1);
        
        tail2 = new BGSprite('exe/Hill/BGSky', -920, -600);
        tail2.scrollFactor.set(1, 1);
        tail2.scale.set(1.35, 1.35);
        add(tail2);
    }
}