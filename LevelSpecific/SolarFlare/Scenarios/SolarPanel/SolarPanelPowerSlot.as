event void FOnSolarPowerSlotActivated();

class ASolarPanelPowerSlot : AHazeActor
{
	UPROPERTY()
	FOnSolarPowerSlotActivated OnSolarPowerSlotActivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PowerRoot;

	UPROPERTY(DefaultComponent, Attach = PowerRoot)
	USceneComponent ClampRoot;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ConsoleRoot;

	UPROPERTY(DefaultComponent, Attach = ConsoleRoot)
	UInteractionComponent OpenSlotInteraction;

	UPROPERTY(DefaultComponent, Attach = PowerRoot)
	UInteractionComponent PushSlotIn;
	default PushSlotIn.bIsImmediateTrigger = true;

	UPROPERTY(EditAnywhere)
	ASolarPanel SolarPanel;

	UPROPERTY()
	bool bIsActivated;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenSlotInteraction.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		OpenSlotInteraction.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		PushSlotIn.OnInteractionStarted.AddUFunction(this, n"OnPushInInteractionStarted");
		PushSlotIn.Disable(this);
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		if (!bIsActivated)
		{
			BP_OpenClamp();
			PushSlotIn.Enable(this);
		}
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		PushSlotIn.Disable(this);
		if (!bIsActivated)
			BP_CloseClamp();
	}

	UFUNCTION()
	private void OnPushInInteractionStarted(UInteractionComponent Interaction,
	                                        AHazePlayerCharacter Player)
	{
		bIsActivated = true;
		BP_PowerCorePushedIn();
		Interaction.Disable(this);
		SolarPanel.RunActivationCheck();
		OnSolarPowerSlotActivated.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_PowerCorePushedIn() {}
	UFUNCTION(BlueprintEvent)
	void BP_OpenClamp() {}
	UFUNCTION(BlueprintEvent)
	void BP_CloseClamp() {}
}