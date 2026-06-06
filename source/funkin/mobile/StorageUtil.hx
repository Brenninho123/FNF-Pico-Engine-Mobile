package funkin.mobile;

import lime.system.System;

class StorageUtil
{
	public static function getStorageDirectory():String
	{
		#if android
		return getSafeAndroidPath();
		#elseif ios
		return System.documentsDirectory + "/";
		#else
		return "./";
		#end
	}

	public static function getSaveDirectory():String
	{
		#if android
		return getSafeAndroidPath() + "saves/";
		#elseif ios
		return System.documentsDirectory + "/saves/";
		#else
		return lime.system.System.applicationStorageDirectory;
		#end
	}

	#if android
	static function getSafeAndroidPath():String
	{
		final extStorage = lime.system.JNI.callStaticMethod(
			"android/os/Environment",
			"getExternalStorageDirectory",
			"()Ljava/io/File;"
		);

		if (extStorage != null)
		{
			final path:String = lime.system.JNI.callMember(extStorage, "getAbsolutePath", "()Ljava/lang/String;");
			if (path != null && path.length > 0)
				return path + "/Pico-Engine/";
		}

		return System.applicationStorageDirectory + "/";
	}
	#end

	public static function ensureDirectory(path:String):Void
	{
		if (!sys.FileSystem.exists(path))
			sys.FileSystem.createDirectory(path);
	}

	public static function readContent(path:String):String
	{
		final fullPath = getStorageDirectory() + path;
		if (sys.FileSystem.exists(fullPath))
			return sys.io.File.getContent(fullPath);
		return null;
	}

	public static function writeContent(path:String, data:String):Void
	{
		final dir  = getStorageDirectory();
		ensureDirectory(dir);
		sys.io.File.saveContent(dir + path, data);
	}
}
