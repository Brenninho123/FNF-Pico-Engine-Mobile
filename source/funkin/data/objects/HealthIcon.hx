package funkin.data.objects;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	private var char:String = '';
	public var animatedIcon:Bool = false;

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true, ?animatedIcon:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		this.animatedIcon = animatedIcon;
		changeIcon(char, allowGPU, animatedIcon);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true, ?animatedIcon:Null<Bool> = null)
	{
		var newAnimatedIcon:Bool = animatedIcon != null ? animatedIcon : this.animatedIcon;
		if(this.char != char || this.animatedIcon != newAnimatedIcon)
		{
			this.animatedIcon = newAnimatedIcon;
			var name:String = 'icons/' + char;
			var name:String = 'icons/baseGame/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/baseGame/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			
			var graphic = Paths.image(name, allowGPU);
			if (graphic == null) 
			{
				// Create a placeholder graphic if file cannot be loaded
				var placeholder:BitmapData = new BitmapData(150, 150, true, 0xFF000000);
				graphic = FlxGraphic.fromBitmapData(placeholder, false, 'icon-face');
			}
			var iSize:Float = Math.round(graphic.width / graphic.height);
			loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
			iconOffsets[0] = (width - 150) / iSize;
			iconOffsets[1] = (height - 150) / iSize;
			updateHitbox();

			animation.add(char, [for(i in 0...frames.frames.length) i], this.animatedIcon ? 24 : 0, this.animatedIcon, isPlayer);
			animation.play(char);
			this.char = char;

			if(char.endsWith('-pixel'))
				antialiasing = false;
			else
				antialiasing = ClientPrefs.data.antialiasing;
		}
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		super.updateHitbox();
		if(autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}

	public function getCharacter():String {
		return char;
	}
}
