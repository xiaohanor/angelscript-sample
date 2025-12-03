class ABattlefieldSlowHighFiveEventManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	FSoundDefReference SoundDef;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(SoundDef.IsValid())
			SoundDef.SpawnSoundDefAttached(this);
	}
	
	UFUNCTION()
	void StartSlowMo()
	{
		UBattlefieldHighFiveSlowMoEventHandler::Trigger_OnStartSlowMo(this);
	}

	UFUNCTION()
	void StopSlowMo()
	{
		UBattlefieldHighFiveSlowMoEventHandler::Trigger_OnStopSlowMo(this);
	}
};