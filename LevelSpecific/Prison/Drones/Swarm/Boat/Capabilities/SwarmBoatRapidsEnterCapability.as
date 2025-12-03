struct FSwarmBoatRapidsEnterCapabilityDeactivationParams
{
	bool bReachedTarget = false;
}

class USwarmBoatRapidsEnterCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::BoatRapidsMovementCapability);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	default DebugCategory = Drone::DebugCategory;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmBoatComponent SwarmBoatComponent;
	UPlayerMovementComponent MovementComponent;
	USweepingMovementData MoveData;

	USwarmBoatSettings BoatSettings;
	USwarmBoatRapidsSettings RapidsSettings;

	UHazeSplineComponent SplineComponent;

	FVector Target;

	bool bReachedTarget;
	bool bMovingTowardsTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		SwarmBoatComponent = UPlayerSwarmBoatComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSweepingMovementData();

		BoatSettings = USwarmBoatSettings::GetSettings(Player);
		RapidsSettings = USwarmBoatRapidsSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwarmBoatComponent.IsBoatActive())
			return false;

		if (!SwarmBoatComponent.IsEnteringRapids())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSwarmBoatRapidsEnterCapabilityDeactivationParams& DeactivationParams) const
	{
		if (!SwarmBoatComponent.IsBoatActive())
			return true;

		if (!SwarmBoatComponent.IsEnteringRapids())
			return true;

		if (bReachedTarget)
		{
			DeactivationParams.bReachedTarget = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bReachedTarget = false;
		bMovingTowardsTarget = false;

		Target = SwarmBoatComponent.GetRapidsSpline().GetWorldLocationAtSplineDistance(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(const FSwarmBoatRapidsEnterCapabilityDeactivationParams& DeactivationParams)
	{
		SwarmBoatComponent.bEnteringRapids = false;
		SwarmBoatComponent.bInRapids = true;

		Player.ClearMovementInput(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			float TimeMultiplier = Math::Min(1.0 + ActiveDuration * 5.0, 6.0);
			float Speed = RapidsSettings.MaxSpeed * TimeMultiplier;

			FVector PlayerToTarget = (Target - Player.ActorLocation).ConstrainToPlane(MovementComponent.WorldUp);
			float DistanceToTarget = PlayerToTarget.Size();
			PlayerToTarget.Normalize();

			// Accelerate towards entry
			FVector Impulse = PlayerToTarget * Speed * DeltaTime;
			MovementComponent.AddPendingImpulse(Impulse, n"RapidsEnterCapability");

			// Tone down move input
			float InputVoider = Math::Max(0.3, 1.0 - Math::Square(Math::Saturate(ActiveDuration / 1.0)));
			FVector MoveInput = GetMoveInput();
			Player.ApplyMovementInput(MoveInput * InputVoider, this, EInstigatePriority::Normal);

			// Check if we are moving towards target now
			if (!bMovingTowardsTarget && MovementComponent.Velocity.GetSafeNormal().DotProduct(PlayerToTarget) > 0)
				bMovingTowardsTarget = true;

			if (bMovingTowardsTarget)
			{
				FVector NextLocation = Player.ActorLocation + MovementComponent.Velocity;
				FVector PlayerToNextLocation = (NextLocation - Player.ActorLocation).ConstrainToPlane(MovementComponent.WorldUp).GetSafeNormal();

				// Check if we reached or are moving passed target
				if (PlayerToNextLocation.DotProduct(PlayerToTarget) <= 0 || DistanceToTarget < 10.0)
					bReachedTarget = true;
			}
		}
	}

	FVector GetMoveInput() const
	{
		const FVector2D MovementRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		FVector MoveInput = FVector(MovementRaw.X, MovementRaw.Y, 0.0);

		const FVector WorldUp = MovementComponent.WorldUp;

		const float MoveInputSize = MoveInput.Size();
		MoveInput = Player.ViewTransform.Rotation.RotateVector(MoveInput).VectorPlaneProject(WorldUp).GetSafeNormal();
		MoveInput *= MoveInputSize;

		return MoveInput;
	}
}