class ADentistBossRevealPlatformFloodLights : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LightRoot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION()
	void Activate()
	{
		LightRoot.SetHiddenInGame(false, true);
		BP_Activate();
		UDentistBossFloodLightEventHandler::Trigger_OnFloodLightActivated(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}
};