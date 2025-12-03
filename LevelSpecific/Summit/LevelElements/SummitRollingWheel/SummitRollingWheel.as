
event void FOnSummitRollingWheelRolled(float Amount);

class ASummitRollingWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent RotatingRoot;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor Camera;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractComp.InteractionCapability = n"TeenDragonSummitRollingWheelCapability";
	// Doing the teleport for the dragon manually, don't want to move the player
	default InteractComp.MovementSettings.Type = EMoveToType::NoMovement;

	UPROPERTY()
	FOnSummitRollingWheelRolled OnWheelRolled;

	// How fast the rotating root spins relative to the dragon's roll speed
	UPROPERTY(EditAnywhere)
	float WheelRotationSpeed = 1.0;

	// Whether to allow rolling in the opposite direction
	UPROPERTY(EditAnywhere)
	bool bAllowRollingBackward = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedCurrentRollPosition;
	// Overridden when interacting
	default SyncedCurrentRollPosition.SyncRate = EHazeCrumbSyncRate::Low;

	float CurrentRollPosition = 0.0;
	float SpinVelocity = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		if (Camera != nullptr)
			Camera.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		SyncedCurrentRollPosition.Value = 0.0;

		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(BlueprintPure)
	float GetSpinVelocity() const
	{
		return SpinVelocity;
	}

	void IncrementSyncedRollPosition(float RollIncrement)
	{
		SyncedCurrentRollPosition.SetValue(SyncedCurrentRollPosition.Value + RollIncrement * 0.07 * WheelRotationSpeed);
	}

	void ApplyRoll(float RollAmount)
	{
		OnWheelRolled.Broadcast(RollAmount);
		CurrentRollPosition += RollAmount * 0.07 * WheelRotationSpeed;
		RotatingRoot.SetRelativeRotation(FRotator(CurrentRollPosition, 0.0, 0.0));
		// PrintToScreen("" + RollAmount);
	}
}