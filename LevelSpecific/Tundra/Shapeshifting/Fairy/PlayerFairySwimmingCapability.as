class UTundraPlayerFairySwimmingCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerSwimmingComponent SwimmingComp;
	UTundraPlayerFairyComponent FairyComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UTundraPlayerFairySettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwimmingComp = UPlayerSwimmingComponent::Get(Player);
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!FairyComp.bIsActive)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(SwimmingComp.InstigatedSwimmingState.Get() == EPlayerSwimmingActiveState::Inactive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!FairyComp.bIsActive)
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		if(SwimmingComp.InstigatedSwimmingState.Get() == EPlayerSwimmingActiveState::Inactive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector Velocity = MoveComp.Velocity;
				Velocity += GetFrameRateIndependentDrag(Velocity, 8.0, DeltaTime);
				Movement.AddVelocity(Velocity);
				Movement.AddGravityAcceleration();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"UnderwaterSwimming");
		}
	}

	/* Takes in velocity and drag and delta time and returns the velocity to add. */
	FVector GetFrameRateIndependentDrag(FVector Velocity, float Drag, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		FVector TargetVelocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		return TargetVelocity - Velocity;
	}
}