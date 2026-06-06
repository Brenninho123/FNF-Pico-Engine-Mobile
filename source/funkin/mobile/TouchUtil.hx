package funkin.mobile;

#if mobile
import flixel.FlxG;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

class TouchUtil
{
	public static function getFirstTouch():FlxTouch
	{
		if (FlxG.touches.list.length > 0)
			return FlxG.touches.list[0];
		return null;
	}

	public static function anyJustPressed():Bool
	{
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
				return true;
		}
		return false;
	}

	public static function anyPressed():Bool
	{
		for (touch in FlxG.touches.list)
		{
			if (touch.pressed)
				return true;
		}
		return false;
	}

	public static function anyJustReleased():Bool
	{
		for (touch in FlxG.touches.list)
		{
			if (touch.justReleased)
				return true;
		}
		return false;
	}

	public static function touchOverlapsRect(rect:FlxRect):Bool
	{
		for (touch in FlxG.touches.list)
		{
			if (rect.containsPoint(FlxPoint.weak(touch.x, touch.y)))
				return true;
		}
		return false;
	}

	public static function justPressedInRect(rect:FlxRect):Bool
	{
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed && rect.containsPoint(FlxPoint.weak(touch.x, touch.y)))
				return true;
		}
		return false;
	}

	public static function getSwipeDirection():String
	{
		final touch = getFirstTouch();
		if (touch == null || !touch.justReleased)
			return "";

		final dx = touch.x - touch.screenPosition.x;
		final dy = touch.y - touch.screenPosition.y;

		if (Math.abs(dx) > Math.abs(dy))
			return dx > 0 ? "right" : "left";
		else
			return dy > 0 ? "down" : "up";
	}

	public static function backSwipe():Bool
	{
		final dir = getSwipeDirection();
		return dir == "right";
	}
}
#end
