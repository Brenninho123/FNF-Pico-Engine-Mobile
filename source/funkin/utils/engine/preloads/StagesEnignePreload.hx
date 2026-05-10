package funkin.utils.engine.preloads;

import funkin.stages.data.weeks.weekspecial.*;
import funkin.modding.scripting.FunkinLua;
import haxe.ds.List;
import lucas.funkin.stages.engine.mods.bonus.exe.HillZone;
import lucas.funkin.stages.engine.mods.bonus.exe.encore.EndlessEncoreForest;
import lucas.funkin.stages.engine.mods.bonus.exe.tails.ScrapBrain;
import lucas.funkin.stages.engine.standard.Arenanew;
import lucas.funkin.stages.engine.standard.CastleBowser;
import lucas.funkin.stages.engine.standard.Shaggy;

class StagesEnignePreload extends BaseStage
{
    #if LUA_ALLOWED
    public static function implement(funk:FunkinLua)
    {
        var lua:State = funk.lua;
        funk.set('versionPS', MainMenuState.PicoVersion.trim());
    }
    #end

    public static function addstage(name:String) 
    {
        switch (name)
        {
            case "endlessEncore": new EndlessEncoreForest();   //Sonic.exe Vs Sonic Majin
            case "hillZone": new HillZone();                   //Sonic.exe Mod
            case 'castleBowser': new CastleBowser();           //Vs Bowser (Pico Mix)
            case 'matt-arena': new Arenanew();                 //Vs Matt (Pico Mix)
            case 'shaggyHill': new Shaggy();                   //Vs Shaggy (Pico Mix)
            case 'SBStage': new ScrapBrain();                  //Vs knuxs (Sonic.exe Mod)
        }
    }
}
