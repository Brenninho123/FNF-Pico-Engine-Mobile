package lucas.funkin.stages.engine.standard;

import objects.Character;
import substates.GameOverSubstate;

class Arenanew extends BaseStage
{
    var sky:BGSprite;
    var stands:BGSprite;
    var railingnew:BGSprite;
    var ground:BGSprite;
    var crowdGroup:Array<BGSprite> = [];

    override function create()
    {
        sky = new BGSprite('matt/Arena/skyBG', -450, -175);
        add(sky);

        stands = new BGSprite('matt/Arena/standsBG', -450, -225);
        add(stands);

        for (i in 1...7) {
            setupCrowd(i, -450, -200); 
        }

        railingnew = new BGSprite('matt/Arena/railingBG', -450, -200);
        add(railingnew);

        ground = new BGSprite('matt/Arena/groundBG', -450, -100);
        add(ground);
    }

    function setupCrowd(num:Int, x:Float, y:Float)
    {
        var crowdMember:BGSprite = new BGSprite('matt/Arena/crowd', x, y, 0.47, 0.47, ['crowd ' + num]);
        crowdMember.scale.set(0.9, 0.9);
        crowdMember.updateHitbox();
        add(crowdMember);
        crowdGroup.push(crowdMember);
    }

    // Equivalente ao onBeatHit e onCountdownTick
    override function beatHit()
    {
        super.beatHit();

        // Se o beat for par, todos os membros da plateia "dançam"
        if (curBeat % 2 == 0) {
            for (member in crowdGroup) {
                member.dance(true);
            }
        }
    }

    override function countdownTick(count:Countdown, counter:Int)
    {
        super.countdownTick(count, counter);
        
        // Se o contador for menor que 2 (swagCounter < 2 no Lua)
        if (counter < 2) {
            for (member in crowdGroup) {
                member.dance(true);
            }
        }
    }
}