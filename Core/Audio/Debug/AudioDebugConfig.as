UCLASS(Config = EditorPerProjectUserSettings)
class UHazeAudioDevMenuConfig
{
	UPROPERTY(Config)
	FAudioDebugFilter WorldFilter;

	UPROPERTY(Config)
	FAudioDebugFilter ViewFilter;

	UPROPERTY(Config)
	FAudioDebugMiscFlags MiscFlags;

	UPROPERTY()
	int InViewportOrMenuFlags = -1;

	UPROPERTY(Config)
	bool bEnableTTS = false;

	bool bInitialized = false;

	void Initialize()
	{
		if (bInitialized)
			return;

		bInitialized = true;
		WorldFilter.PostLoad();
		ViewFilter.PostLoad();
	}

	void Save()
	{
		#if EDITOR
		SaveConfig();
		#endif
	}

	void Reset()
	{
		WorldFilter.Reset();
		ViewFilter.Reset();
		MiscFlags.Reset();
		InViewportOrMenuFlags = 0;

		Save();
	}
}

UCLASS(Config = EditorPerProjectUserSettings)
class UHazeAudioDebugConfig
{
	UPROPERTY(Config)
	int WorldFlags = 0;

	UPROPERTY(Config)
	int ViewFlags = 0;

	void Save()
	{
		#if EDITOR
		SaveConfig();
		#endif
	}

	void Reset()
	{
		WorldFlags = 0;
		ViewFlags = 0;
		Save();
	}
}

namespace AudioDebug
{
	UHazeAudioDevMenuConfig GetMenuConfig()
	{
		auto Config = Cast<UHazeAudioDevMenuConfig>(UHazeAudioDevMenuConfig.DefaultObject);
		Config.Initialize();
		return Config;
	}

	UHazeAudioDebugConfig GetConfig()
	{
		return Cast<UHazeAudioDebugConfig>(UHazeAudioDebugConfig.DefaultObject);
	}
}