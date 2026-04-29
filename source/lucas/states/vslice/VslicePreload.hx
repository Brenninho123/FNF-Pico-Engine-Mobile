package lucas.states.vslice;

// Pico Engine 
import lucas.funkin.stages.vslice.standard.*;
import lucas.funkin.stages.vslice.erect.*;
import lucas.funkin.stages.vslice.mods.*;
import lucas.funkin.stages.vslice.mods.reteke.*;
import lucas.funkin.stages.vslice.mods.extra.*;
import lucas.states.funkin.scripts.menus.MainMenuState;
import lucas.states.vslice.*;

import psychlua.FunkinLua;
import haxe.ds.List;

class VslicePreload extends BaseStage
{
    public static var currentStage:BaseStage = null;
    #if LUA_ALLOWED
    public static function implement(funk:FunkinLua)
    {
        var lua:State = funk.lua;
        funk.set('versionPS', MainMenuState.PicoVersion.trim());
    }
    #end
        public static function addstage(name:String)
        {
            currentStage = null;
            currentStage = switch (name)
            {
                case 'mainStage': new MainStage();                     //Week 1
                case 'mainStageErect': new MainStageErect();           //Week 1 - Erect
                case 'spookyMansion': new SpookyMansion();             //Week 2
                case 'philly': new Philly();			               //Week 3
                case 'limoRide': new LimoRide();					   //Week 4
                case 'mallXmas': new MallXmas();					   //Week 5 - Cocoa, Eggnog
                case 'mallEvil': new MallEvil();					   //Week 5 - Winter Horrorland
                case 'school': new School();						   //Week 6 - Senpai, Roses
                case 'schoolEvil': new SchoolEvil();				   //Week 6 - Thorns
                case 'tankmanBattlefield': new TankmanBattlefield();   //Week 7 - Ugh, Guns, Stress
                case 'tankReteke': new TankReteke();				   //Week 7 Retake - Ugh, Guns, Stress
                case 'phillyStreets': new PhillyStreets();             //Weekend 1 - Darnell, Lit Up, 2Hot
                case 'phillyStreetsErect': new PhillyStreetsErect();   //Weekend 1 Erect
                case 'phillyBlazin': new PhillyBlazin();               //weekend1 - blaisz
                case 'shiftDarkErect': new TheShiftDarkErect();        //Sky (Pico Mix)
                case 'stageSky': new StageSky();                       //Reteke Sky (Pico Mix)
                case 'whittyAlley': new WhittyAlley();                 //Vs Whitty (Pico Mix)
                case 'charSelector': new SelectCharacterStage();       //StayFunky
                default: null;
            }

            if(currentStage == null)
            {
                trace('[VslicePreload] Stage "' + name + '" not found! Using default BaseStage.');
                currentStage = new BaseStage();
            }
        }
}