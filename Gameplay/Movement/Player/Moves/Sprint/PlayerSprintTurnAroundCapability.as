class UPlayerSprintTurnAroundCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::FloorMotion);
	default CapabilityTags.Add(PlayerFloorMotionTags::FloorMotionTurnAround);
	default CapabilityTags.Add(PlayerMovementTags::Sprint);
	default CapabilityTags.Add(PlayerSprintTags::SprintTurnaround);
	
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 147;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerSprintSettings SprintSettings;
	UPlayerSprintComponent SprintComp;
	UPlayerFloorMotionComponent FloorMoveComp;

	float TimeSinceSprintDeactivation;

	FVector InitialVelocity;
	FVector PreviousMoveInput;
	FVector2D Local2DVelocity;
	FStickFlickTracker FlickTracker;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		SprintSettings = UPlayerSprintSettings::GetSettings(Player);
		SprintComp = UPlayerSprintComponent::Get(Player);

		FloorMoveComp = UPlayerFloorMotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		FVector MoveInput = MoveComp.MovementInput;

		FVector ActorLocalInput = Player.ActorRotation.UnrotateVector(MoveInput);
		FVector2D Flattened(ActorLocalInput.X, ActorLocalInput.Y);

		FlickTracker.AddStickDelta(FStickDelta(Flattened, DeltaTime), 0.2);

		FVector UnrotatedVelocity = Player.ActorRotation.UnrotateVector(MoveComp.HorizontalVelocity);
		Local2DVelocity = FVector2D(UnrotatedVelocity.X, UnrotatedVelocity.Y);

		//Verify if we are currently sprinting or recently exited
		if(SprintComp.IsSprinting())
			TimeSinceSprintDeactivation = 0;
		else
			TimeSinceSprintDeactivation += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;	

		if(!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return false;
		
		if(TimeSinceSprintDeactivation > 0.06)
			return false;

		if(MoveComp.HorizontalVelocity.Size() <= (FloorMoveComp.Settings.MaximumSpeed))
			return false;

		if (!TestFlick(-Local2DVelocity))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return true;

		if(ActiveDuration >= SprintSettings.TurnAroundSlowdownDuration + SprintSettings.TurnAroundSpeedupDuration)
			return true;

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		InitialVelocity = MoveComp.GetPreviousHorizontalVelocity();
		FloorMoveComp.ActivatedSprintTurnaround();
		FloorMoveComp.AnimData.bSprintTurnaroundTriggered = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FloorMoveComp.AnimData.bSprintTurnaroundTriggered = false;
		SprintComp.SetSprintToggled(true, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Velocity;
				FVector TargetDirection;

				if(MoveComp.MovementInput.Size() < KINDA_SMALL_NUMBER)
				{
					TargetDirection = PreviousMoveInput;
				}
				else
				{
					TargetDirection = MoveComp.MovementInput;
					PreviousMoveInput = TargetDirection;
				}

				if(ActiveDuration >= 0.0 && ActiveDuration <= SprintSettings.TurnAroundSlowdownDuration)
				{
					float SlowdownAlpha = 1 - (ActiveDuration / SprintSettings.TurnAroundSlowdownDuration);
					Velocity = InitialVelocity * Math::Pow(SlowdownAlpha, 1.2);
					Movement.SetRotation(TargetDirection.ToOrientationQuat());
				}
				else
				{
					FVector NewDirection = Player.ActorForwardVector.RotateVectorTowardsAroundAxis(TargetDirection, MoveComp.WorldUp, 180 * DeltaTime);
					
					float SpeedupAlpha = (ActiveDuration - SprintSettings.TurnAroundSlowdownDuration) / SprintSettings.TurnAroundSpeedupDuration;
					Velocity = NewDirection.GetSafeNormal() * SprintSettings.MaximumSpeed * (0.5 + 0.5 * (Math::Pow(SpeedupAlpha, 0.25)));

					Movement.SetRotation(NewDirection.GetSafeNormal().ToOrientationQuat());
				}

				Movement.AddHorizontalVelocity(Velocity);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
		}
	}

	bool TestFlick(FVector2D Direction) const
	{
		return FlickTracker.TestStickData(Direction);
	}
};