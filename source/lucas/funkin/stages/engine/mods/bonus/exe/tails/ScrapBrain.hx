package lucas.funkin.stages.engine.mods.bonus.exe.tails;

class ScrapBrain extends BaseStage
{
	var scrapPlatform:FlxSprite;
	var scrapWall:FlxSprite;
	var scrapGround:BGSprite;
	override function create()
	{
		var scrapSky:BGSprite = new BGSprite('exe/Tails/Scrap/Sky', -600, -250, 0.7, 0.7);
		add(scrapSky);

		var scrapBG:BGSprite = new BGSprite('exe/Tails/Scrap/Bg', -600, -250, 0.7, 0.7);
		add(scrapBG);

		var scrapGround:BGSprite = new BGSprite('exe/Tails/Scrap/Scrap-Ground', -410, -150, 1.0, 1.0);
		add(scrapGround);

		scrapPlatform = new FlxSprite(400, -300);
		scrapPlatform.frames = Paths.getSparrowAtlas('exe/Tails/Scrap/Scrap Platform');
		scrapPlatform.animation.addByPrefix('a', 'Animated BG', 24, true);
		scrapPlatform.animation.play('a');
		scrapPlatform.scale.set(0.6, 0.6);
		scrapPlatform.updateHitbox();
		scrapPlatform.scrollFactor.set(0.7, 0.7);
		add(scrapPlatform);

		scrapWall = new FlxSprite(2000, -100);
		scrapWall.frames = Paths.getSparrowAtlas('exe/Tails/Scrap/Scrap-Wall');
		scrapWall.animation.addByPrefix('a', 'uyo', 24, true);
		scrapWall.animation.play('a');
		scrapWall.scale.set(0.6, 0.6);
		scrapWall.updateHitbox();
		scrapWall.scrollFactor.set(0.7, 0.7);
		add(scrapWall);
	}
	
    override function createPost()
    {
        add(scrapGround); 
    }
}