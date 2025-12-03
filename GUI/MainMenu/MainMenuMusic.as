class AMainMenuMusic : AHazeActor
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<UHazeMusicSoundDef> MusicSoundDef;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (MusicSoundDef.IsValid())
			UHazeAudioMusicManager::GetActor().AttachDefaultSoundDef(GetSoundDefAsReference(MusicSoundDef));
	}

	private FSoundDefReference GetSoundDefAsReference(TSubclassOf<UHazeMusicSoundDef> MusicSoundDefClass)
	{
		FSoundDefReference Ref;
		if(MusicSoundDefClass == nullptr)
			return Ref;

		Ref.SoundDef = MusicSoundDefClass;
		return Ref;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (MusicSoundDef.IsValid())
			UHazeAudioMusicManager::GetActor().RemoveSoundDef(GetSoundDefAsReference(MusicSoundDef));
	}
};