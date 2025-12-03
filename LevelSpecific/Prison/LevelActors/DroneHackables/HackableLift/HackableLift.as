event void EventHackableLiftRemoveTutorial();

class AHackableLift : ASwarmDroneSimpleMovementHijackable
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraVolume CameraVolume;

	bool bWasMovingPreviousFrame = false;
	int DirectionPreviousFrame = 0;

	UPROPERTY()
	EventHackableLiftRemoveTutorial OnRemoveTutorial;
	bool bRemoveTutorial = false;

	int PlayersInCameraVolume = 0;

	FVector MovementVelocity;
	FVector LastPosition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		CameraVolume.OnEntered.AddUFunction(this, n"PlayerEnteredCameraVolume");
		CameraVolume.OnExited.AddUFunction(this, n"PlayerExitedCameraVolume");
		LastPosition = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Check local movements instead of reading actor velocity since it's not networked.
		MovementVelocity = (ActorLocation - LastPosition) / DeltaSeconds;
		LastPosition = ActorLocation;

		bool bIsMovingThisFrame = IsMoving();
		int DirectionThisFrame = GetDirection();

		if(bWasMovingPreviousFrame && bIsMovingThisFrame)
		{
			if(DirectionThisFrame != DirectionPreviousFrame)
				UHackableLiftEventHandler::Trigger_ChangeDirection(this);
		}
		else if(bIsMovingThisFrame && !bWasMovingPreviousFrame)
		{
			UHackableLiftEventHandler::Trigger_StartMoving(this);
		}
		else if(!bIsMovingThisFrame && bWasMovingPreviousFrame)
		{
			UHackableLiftEventHandler::Trigger_StopMoving(this);
		}
		if(IsMoving())
		{
			Drone::GetSwarmDronePlayer().SetFrameForceFeedback(0.01, 0.01, 0.0, 0.0);
			if(!bRemoveTutorial)
			{
				OnRemoveTutorial.Broadcast();
				bRemoveTutorial = true;
			}
		}

		bWasMovingPreviousFrame = bIsMovingThisFrame;
		DirectionPreviousFrame = DirectionThisFrame;
	}

	void OnHijackStart(FSwarmDroneHijackParams HijackParams) override
	{
		Super::OnHijackStart(HijackParams);

		UHackableLiftEventHandler::Trigger_Activated(this);
		bRemoveTutorial = false;

		SetActorTickEnabled(true);
	}

	void OnHijackStop() override
	{
		Super::OnHijackStop();

		if(bWasMovingPreviousFrame)
		{
			UHackableLiftEventHandler::Trigger_StopMoving(this);
			bWasMovingPreviousFrame = false;
		}

		UHackableLiftEventHandler::Trigger_Deactivated(this);

		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void PlayerEnteredCameraVolume(UHazeCameraUserComponent User)
	{
		PlayersInCameraVolume = Math::Min(PlayersInCameraVolume + 1, 2);

		if(PlayersInCameraVolume == 1)
			UHackableLiftEventHandler::Trigger_EnteredCameraVolume(this);
	}

	UFUNCTION()
	private void PlayerExitedCameraVolume(UHazeCameraUserComponent User)
	{
		PlayersInCameraVolume = Math::Max(PlayersInCameraVolume - 1, 0);

		if(PlayersInCameraVolume == 0)
			UHackableLiftEventHandler::Trigger_ExitedCameraVolume(this);
	}

	UFUNCTION(BlueprintPure)
	bool IsMoving() const
	{	
		return MovementVelocity.Size() > 1;
	}

	UFUNCTION(BlueprintPure)
	float GetSpeedNormalized() const
	{
		return Math::Saturate(MovementVelocity.Size() / MovementSettings.MaxSpeed);
	}

	UFUNCTION(BlueprintPure)
	int GetDirection() const
	{
		if(!IsMoving())
			return 0;

		const FVector UpVector = GetWorldAxisConstraint();
		const float Dot = MovementVelocity.DotProduct(UpVector);
		
		if(Dot > 0)
			return 1;
		else
			return -1;
	}
};