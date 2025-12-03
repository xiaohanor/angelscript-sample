class ASanctuaryBelowAudioLevelScriptActor : AHazeLevelScriptActor
{	
	UPROPERTY()
	TPerPlayer<bool> bHasOverlappedWith_JumpOffDebris_Sweetener_05;
	UPROPERTY()
	TPerPlayer<bool> bHasOverlappedWith_JumpOffDebris_Sweetener_06;
	UPROPERTY()
	TPerPlayer<bool> bHasOverlappedWith_JumpOffDebris_Sweetener_07;
	UPROPERTY()
	TPerPlayer<bool> bHasOverlappedWith_LandDebris_Sweetener_01;

	private bool bWormSoftReferenceLoaded = false;

	UPROPERTY()
	FSoundDefReference AntiGravitySwimmingSoundDef;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (AntiGravitySwimmingSoundDef.IsValid())
		{
			for (auto Player: Game::GetPlayers())
			{
				AntiGravitySwimmingSoundDef.SpawnSoundDefAttached(Player);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (AntiGravitySwimmingSoundDef.IsValid())
		{
			for (auto Player: Game::GetPlayers())
			{
				AntiGravitySwimmingSoundDef.RemoveFromActor(Player);
			}
		}
	}

	UFUNCTION(BlueprintPure)
	bool HasOverlappedVolume(TPerPlayer<bool>& BoolArray, AHazePlayerCharacter Player)
	{
		return BoolArray[Player];
	}

	UFUNCTION()
	void SetOverlappedVolume(TPerPlayer<bool>& BoolArray, AHazePlayerCharacter Player)
	{
		BoolArray[Player] = true;
	}

	UFUNCTION()
	void CheckWaterfallLightWormIsLoaded(const TSoftObjectPtr<ALightSeeker>&in SoftObjectReference)
	{
		if (bWormSoftReferenceLoaded)
			return;

		if (SoftObjectReference.IsNull())
			return;
		
		auto ObjectPtr = SoftObjectReference.Get();
		if (ObjectPtr == nullptr || !ObjectPtr.HasActorBegunPlay())
			return;

		bWormSoftReferenceLoaded = true;
		OnLightSwingWormLoaded();
	}

	UFUNCTION(BlueprintEvent)
	void OnLightSwingWormLoaded()
	{

	}
}