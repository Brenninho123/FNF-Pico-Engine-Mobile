package funkin.utils.engine.preloads;

import funkin.stages.BaseStage;
import funkin.stages.data.weeks.week1.MainStage;
import funkin.stages.data.weeks.week1.variation.erect.MainStageErect;
import funkin.stages.data.weeks.week2.SpookyMansion;
import funkin.stages.data.weeks.week3.Philly;
import funkin.stages.data.weeks.week3.PhillyRemix;
import funkin.stages.data.weeks.week4.LimoRide;
import funkin.stages.data.weeks.week5.MallEvil;
import funkin.stages.data.weeks.week5.MallXmas;
import funkin.stages.data.weeks.week6.School;
import funkin.stages.data.weeks.week6.SchoolEvil;
import funkin.stages.data.weeks.week7.TankmanBattlefield;
import funkin.stages.data.weeks.weekend1.PhillyBlazin;
import funkin.stages.data.weeks.weekend1.PhillyStreets;
import funkin.stages.data.weeks.weekend1.variation.erect.PhillyStreetsErect;
import funkin.stages.data.weeks.weekspecial.mods.engine.SelectCharacterStage;
import funkin.stages.data.weeks.weekspecial.mods.engine.StageSky;
import funkin.stages.data.weeks.weekspecial.mods.engine.TankReteke;
import funkin.stages.data.weeks.weekspecial.mods.engine.WhittyAlley;
import funkin.stages.data.weeks.weekspecial.mods.vslice.TheShiftDarkErect;
import funkin.modding.scripting.FunkinLua;

import haxe.ds.List;

class StagesVslicePreload extends BaseStage
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
                case 'philly': new Philly();                           //Week 3
                case 'phillyTrainRemix': new PhillyRemix();             //Week 3 Remix
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
