package lucas.funkin.stages.engine.mods.bonus.nevada.hank;

class NevadaErect extends BaseStage
{
    override function create()
    {
        var sky:BGSprite = new BGSprite('nevada/hank/erect/', -600, -500);
        add(sky);

        var buildings:BGSprite = new BGSprite('nevada/hank/erect/ground', -600, -500);
        add(buildings);

        var mountains:BGSprite = new BGSprite('nevada/hank/erect/ground', -600, -500);
        add(mountains);

        var topBar:BGSprite = new BGSprite('nevada/hank/erect/ground', -600, -500);
        add(topBar);

        var ground:BGSprite = new BGSprite('nevada/hank/erect/ground', -600, -500);
        add(ground);

        var overlay:BGSprite = new BGSprite('nevada/hank/erect/overlay', -500, -300, 1, 1);
        overlay.scale.set(1.35, 1.35);
        overlay.updateHitbox();
        overlay.alpha = 0.3;
        overlay.blend = openfl.display.BlendMode.ADD;
        add(overlay);

        var foreground_gruntR:BGSprite = new BGSprite('nevada/hank/erect/grunt', 2000, 400, 1.1, 1.1, ['foreground grunts']);
        foreground_gruntR.scale.set(2, 2);
        foreground_gruntR.updateHitbox();
        add(foreground_gruntR);

        var foreground_gruntL:BGSprite = new BGSprite('nevada/hank/erect/grunt', -800, 400, 1.1, 1.1, ['foreground grunts']);
        foreground_gruntL.scale.set(2, 2);
        foreground_gruntL.flipX = true;
        foreground_gruntL.updateHitbox();
        add(foreground_gruntL);

        var fatass:BGSprite = new BGSprite('nevada/hank/erect/fatfuck', 1500, -50, 1, 1, ['hotdoggrunt']);
        fatass.scale.set(2, 2);
        fatass.updateHitbox();
        add(fatass);

        var lightning:BGSprite = new BGSprite('nevada/hank/erect/lightning', 300, -500, 0.7, 1, ['lightning0']);
        lightning.animation.addByPrefix('strike', 'lightning0', 24, false);
        lightning.scale.set(3, 3);
        lightning.updateHitbox(); // Essencial após mudar o scale
        lightning.visible = false;
        add(lightning);

        var agent:BGSprite = new BGSprite('nevada/hank/erect/agent', -100, 300, 1, 1, ['agent']);
        agent.scale.set(2, 2);
        agent.updateHitbox(); // Necessário para recalcular o tamanho após o scale
        add(agent);
    }
}