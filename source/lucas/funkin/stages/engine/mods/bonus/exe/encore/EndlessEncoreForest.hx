package lucas.funkin.stages.engine.mods.bonus.exe.encore;

class EndlessEncoreForest extends BaseStage
{
    var majin:FlxSprite;
    var majin2:FlxSprite;
    var stageback:BGSprite; 
    override function create()
    {
        var stagefront = new BGSprite('exe/MajinForest/bluemajin', -300, -250);
        stagefront.scrollFactor.set(1.0, 1.0);
        add(stagefront);

        majin2 = new FlxSprite(300, 100);
        majin2.frames = Paths.getSparrowAtlas('exe/MajinForest/majin2');
        majin2.animation.addByPrefix('a', 'majinl', 24, true);
        majin2.animation.play('a');
        majin2.scale.set(1.9, 1.9);
        majin2.updateHitbox();
        majin2.scrollFactor.set(1.0, 1.0);
        add(majin2);

        var bg = new BGSprite('exe/MajinForest/bluetree', -310, -150);
        bg.scrollFactor.set(1.0, 1.0);
        add(bg);

        var stageGround = new BGSprite('exe/MajinForest/majinground', -200, -220);
        stageGround.scrollFactor.set(1.0, 1.0); 
        add(stageGround); 

        majin = new FlxSprite(-400, 600);
        majin.frames = Paths.getSparrowAtlas('exe/MajinForest/majin'); 
        majin.animation.addByPrefix('a', 'majinl', 24, true);
        majin.animation.play('a');
        majin.scale.set(1.9, 1.9);
        majin.updateHitbox();
        majin.scrollFactor.set(1.0, 1.0);
        add(majin);

        stageback = new BGSprite('exe/MajinForest/frontmajin', -270, -150);
        stageback.scrollFactor.set(1.0, 1.0);
    }

    override function createPost()
    {
        add(stageback); 
    }
}