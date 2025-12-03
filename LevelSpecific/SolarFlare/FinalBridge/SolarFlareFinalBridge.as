event void FOnSolarFlareBridgeActivated();

asset CameraPOISolarFlareClearOnInput of UCameraPointOfInterestClearOnInputSettings
{
	InputClearAngleThreshold = 1.0;
	bClearDurationOverridesBlendIn = true;
}


class ASolarFlareFinalBridge : AHazeActor
{
	UPROPERTY()
	FOnSolarFlareBridgeActivated OnSolarFlareBridgeActivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	float ForwardOffset = 3500.0;

	UPROPERTY(EditAnywhere)
	AActor POIActor;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;

	FVector TargetLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetLoc = ActorLocation + (ActorForwardVector * ForwardOffset);
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		DoubleInteract.OnPlayerStartedInteracting.AddUFunction(this, n"OnPlayerStartedInteracting");
		DoubleInteract.OnPlayerStoppedInteracting.AddUFunction(this, n"OnPlayerStoppedInteracting");
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		FSolarFlareFinalBridgeEffectParams Params;
		Params.Location = ActorLocation;
		USolarFlareFinalBridgeEffectHandler::Trigger_OnFinalBridgeStartMove(this, Params);
		SetActorTickEnabled(true);
		DoubleInteract.AddActorDisable(this);

		FHazePointOfInterestFocusTargetInfo FocusTargetInfo;
		FocusTargetInfo.SetFocusToActor(POIActor);
		FApplyPointOfInterestSettings PoiSettings;
		PoiSettings.Duration = 0.0;
		PoiSettings.ClearOnInput = CameraPOISolarFlareClearOnInput;

		// UCameraPointOfInterestClearOnInputSettings

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ApplyPointOfInterest(this, FocusTargetInfo, PoiSettings, 2.0);
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		}

		OnSolarFlareBridgeActivated.Broadcast();
	}

	UFUNCTION()
	private void OnPlayerStartedInteracting(AHazePlayerCharacter Player,
	                                        ADoubleInteractionActor Interaction,
	                                        UInteractionComponent InteractionComponent)
	{
		USolarFlareTriggerShieldComponent::Get(Player).RemovePrompt(Player);
	}

	UFUNCTION()
	private void OnPlayerStoppedInteracting(AHazePlayerCharacter Player,
	                                        ADoubleInteractionActor Interaction,
	                                        UInteractionComponent InteractionComponent)
	{
		USolarFlareTriggerShieldComponent::Get(Player).AddPrompt(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLoc, DeltaSeconds, ForwardOffset * 0.4);
		
		if (ActorLocation == TargetLoc)
		{
			FSolarFlareFinalBridgeEffectParams Params;
			Params.Location = ActorLocation;
			USolarFlareFinalBridgeEffectHandler::Trigger_OnFinalBridgeStopMove(this, Params);
			for (AHazePlayerCharacter Player : Game::Players)
				Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	void SetFinalLocations()
	{
		ActorLocation = TargetLoc + FVector(0, 0, 0.001);
		Timer::SetTimer(this, n"WorkaroundForChaosForgettingCollision", 0.001);
		DoubleInteract.AddActorDisable(this);
	}

	UFUNCTION()
	private void WorkaroundForChaosForgettingCollision()
	{
		ActorLocation = TargetLoc;
	}
};