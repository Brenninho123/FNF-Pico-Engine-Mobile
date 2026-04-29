package lucas.states.funkin.util.funkin.stages;

// Pico Engine stages and Menus
import lucas.funkin.stages.engine.standard.*;
import lucas.funkin.stages.engine.erect.*;
import lucas.funkin.stages.engine.mods.*;
import lucas.funkin.stages.engine.mods.extra.*;
import lucas.funkin.stages.engine.mods.bonus.*;
import lucas.funkin.stages.engine.mods.bonus.funkadelix.week3.*; // (This section here is exclusively for the music from Funkadelix and the stages.)
import lucas.funkin.stages.engine.mods.bonus.exe.*; // (This section here is exclusively for the music from Sonic.exe and the stages.)
import lucas.funkin.stages.engine.mods.bonus.exe.encore.*; // (sonic.exe mod encore stages)
import lucas.funkin.stages.engine.mods.bonus.exe.tails.*; // (Exclusive stages for the music from the tails.exe mod.)
import lucas.funkin.stages.engine.mods.bonus.kapi.*; // (This section here is exclusively for the music from Kapi mod and the stages.)
import lucas.funkin.stages.engine.mods.bonus.nevada.hank.*; // (This section here is exclusively for the music from Nevada mod and the stages.)
import lucas.funkin.stages.engine.mods.bonus.nevada.tricky.*; // (This section here is exclusively for the music from  mod and the stages.)
import lucas.states.funkin.scripts.menus.*;

import haxe.ds.List;
import psychlua.FunkinLua;

class StagesPreload extends BaseStage
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