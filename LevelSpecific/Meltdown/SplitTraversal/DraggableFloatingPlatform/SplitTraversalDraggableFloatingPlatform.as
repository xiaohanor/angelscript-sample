UCLASS(Abstract)
class ASplitTraversalDraggableFloatingPlatform : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UFauxPhysicsTranslateComponent FantasyTranslateComp;

	UPROPERTY(DefaultComponent, Attach = FantasyTranslateComp)
	UHazeRawVelocityTrackerComponent FantasyTranslateVelocityTrackerComp;

	UPROPERTY(DefaultComponent, Attach = FantasyTranslateComp)
	UFauxPhysicsConeRotateComponent FantasyRotateComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRotateComp)
	UThreeShotInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRotateComp)
	USceneComponent FantasyRopeAttachment;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent SciFiTranslateRoot;

	UPROPERTY(DefaultComponent, Attach = SciFiTranslateRoot)
	USceneComponent SciFiRopeAttachment;

	UPROPERTY(DefaultComponent)
	USplitTraversalTransferFauxWeightComponent TransferWeightComp;
	default TransferWeightComp.TransferToActor = this;

	UPROPERTY(EditAnywhere)
	float PushForce = 100.0;

	UPROPERTY(EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint RespawnPoint;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalBranchLever Lever;

	ASplitTraversalWaterBase WaterBase;
	ASplitTraversalConveyorWaterfall ConveyorWaterfall;
	ASplitTraversalWaterTop WaterTop;

	FTransform StartRelativeTransform;

	bool bLandedBroadcasted = false;
	bool bBlockedMovement = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		WaterBase = Cast<ASplitTraversalWaterBase>(AttachParentActor);

		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandleGroundImpact");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"HandaleCanceled");

		Lever.OnActivated.AddUFunction(this, n"HandleLeverPulled");
	}


	UFUNCTION()
	private void HandaleCanceled(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		InteractionComp.Disable(this);
		Timer::SetTimer(this, n"ReactivateInteraction", 0.5);
	}
	

	UFUNCTION()
	private void HandleLeverPulled()
	{
		bBlockedMovement = true;
		WaterBase.SplineTranslateComp.Friction = 1000.0;
		Timer::SetTimer(this, n"DelayedUnblockMovement", 2.0);
	}

	UFUNCTION()
	private void DelayedUnblockMovement()
	{
		WaterBase.SplineTranslateComp.Friction = 1.0;
		bBlockedMovement = false;
	}

	UFUNCTION()
	private void ReactivateInteraction()
	{
		InteractionComp.Enable(this);
	}

	UFUNCTION()
	private void HandleGroundImpact(AHazePlayerCharacter Player)
	{
		if (Player == Game::Mio && !bLandedBroadcasted)
		{
			bLandedBroadcasted = true;

			TListedActors<ASplitTraversalFloatingPlatformLaser> Lasers;
			for (auto Laser : Lasers)
			{
				Laser.Activate();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ReplicateMovement();
	}

	private void ReplicateMovement()
	{
		SciFiTranslateRoot.SetRelativeLocation(FantasyTranslateComp.RelativeLocation);
		SciFiTranslateRoot.SetWorldRotation(FantasyRotateComp.WorldRotation);
	}

	UFUNCTION()
	void ActivateBigThrusters()
	{
		BP_ActivateBigThrusters();
		USplitTraversalDraggableFloatingPlatformEventHandler::Trigger_OnActivateBigThrusters(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateBigThrusters(){}

	UFUNCTION()
	void DeactivateBigThrusters()
	{
		BP_DeactivateBigThrusters();
		USplitTraversalDraggableFloatingPlatformEventHandler::Trigger_OnDeactivateBigThrusters(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateBigThrusters(){}
};