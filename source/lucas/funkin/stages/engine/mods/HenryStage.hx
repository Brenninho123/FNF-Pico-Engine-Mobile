package lucas.funkin.stages.engine.mods;

class HerryStage extends BaseStage
{
     override function create()
     {
        var bg = new BGSprite('henry/bg', -1600, -300);
        add(bg);
     }
}