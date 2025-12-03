class UAdultDragonTurnBackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"AdultDragonTurnBack");
	default CapabilityTags.Add(n"AdultDragonSteering");
	default CapabilityTags.Add(n"AdultDragonFlying");

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	UPlayerAdultDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	UAdultDragonTurnBackComponent TurnBackComp;

	USimpleMovementData Movement;
	UAdultDragonTurnBackSettings TurnBackSettings;

	FVector StartLocation;

	FQuat BackRotation;
	float TargetPitch;
	float TargetRoll;

	float SpeedAtActivation;

	bool bPitchDone = false;
	bool bTurnBackStarted = false;
	bool bTurnBackCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		TurnBackComp = UAdultDragonTurnBackComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();

		TurnBackSettings = UAdultDragonTurnBackSettings::GetSettings(Player);	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!WasActionStarted(ActionNames::MovementJump))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(bTurnBackCompleted)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"Steering", this);

		TurnBackComp.BlendToStoppedCamera(this, TurnBackSettings.StoppedCameraBlendDuration);

		SpeedAtActivation = MoveComp.GetVelocity().Size() + MoveComp.PendingImpulse.Size();

		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Flying, this, EInstigatePriority::Low);

		bTurnBackCompleted = false;
		bPitchDone = false;
		bTurnBackStarted = false;

		StartLocation = Player.ActorLocation;

		// FApplyPointOfInterestSettings Settings;
		// Settings.bMatchFocusDirection = true;
		// Player.ApplyPointOfInterest(this, FHazeFocusTarget(StartLocation + BackRotation.ForwardVector * 5000), Settings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"Steering", this);

		DragonComp.AnimationState.Clear(this);

		DragonComp.AccRotation.SnapTo(DragonComp.WantedRotation);
		TurnBackComp.BlendBackCamera(this, TurnBackSettings.NormalCameraBlendDuration);

		Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Velocity = Player.ActorForwardVector * DragonComp.Speed;

				if(!bTurnBackStarted && 
				ActiveDuration > TurnBackSettings.TurnBackDelay)
				{
					bTurnBackStarted = true;
					StartTurnBack();
				}
				else if (bTurnBackStarted)
				{
					RotateTowardsWantedRotation(DeltaTime);
				}
				// Player.CameraOffsetComponent.FreezeTransformAndLerpBackToParent(this, 0.5);
				Movement.AddDelta(Velocity * DeltaTime);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			// MoveComp.ApplyMove(Movement);
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AdultDragonFlying");
		}
	}

	void StartTurnBack()
	{
		FVector Backwards = -Player.ActorForwardVector;
		BackRotation = FQuat::MakeFromXZ(Backwards, Player.ActorUpVector);

		TargetPitch = DragonComp.AccRotation.Value.Pitch + 180;
		TargetRoll = DragonComp.AccRotation.Value.Roll + 180;

		DragonComp.WantedRotation = BackRotation.Rotator();
	}

	void RotateTowardsWantedRotation(float DeltaTime)
	{
		if(!Math::IsNearlyEqual(DragonComp.AccRotation.Value.Pitch, TargetPitch))
		{
			// AccPitch.AccelerateTo(TargetPitch, 1.0, DeltaTime);
			float NewPitch = Math::FInterpConstantTo(DragonComp.AccRotation.Value.Pitch, TargetPitch, DeltaTime, TurnBackSettings.PitchSpeed);
			FRotator NewRotation = DragonComp.AccRotation.Value;
			NewRotation.Pitch = NewPitch;
			DragonComp.AccRotation.SnapTo(NewRotation);
		}
		else if(!Math::IsNearlyEqual(DragonComp.AccRotation.Value.Roll, TargetRoll))
		{
			// AccRoll.AccelerateTo(TargetRoll, 1.0, DeltaTime);
			float NewRoll = Math::FInterpConstantTo(DragonComp.AccRotation.Value.Roll, TargetRoll, DeltaTime, TurnBackSettings.RollingSpeed);
			FRotator NewRotation = DragonComp.AccRotation.Value;
			NewRotation.Roll = NewRoll;
			DragonComp.AccRotation.SnapTo(NewRotation);
			
		}
		else
		{
			bTurnBackCompleted = true;
		}
		Movement.SetRotation(DragonComp.AccRotation.Value);
	}
}