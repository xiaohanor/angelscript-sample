class USwarmDroneGroundMovementHijackCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDroneHijackCapability);

	// Move before player?
	default TickGroup = EHazeTickGroup::BeforeMovement;

	default DebugCategory = Drone::DebugCategory;


	ASwarmDroneGroundMovementHijackable HijackOwner;
	UHazeMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	AHazePlayerCharacter HijackPlayer = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HijackOwner = Cast<ASwarmDroneGroundMovementHijackable>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HijackPlayer = HijackOwner.HijackComponent.GetHijackPlayer();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HijackPlayer = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HijackOwner.MovementSettings.bShouldRotateWithVelocity)
		{
			if (!MovementComponent.HorizontalVelocity.IsNearlyZero())
				HijackOwner.SetMovementFacingDirection(MovementComponent.HorizontalVelocity.GetSafeNormal());
		}

		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
				FVector MovementInput = SwarmDroneHijack::GetMovementInput(HijackPlayer, RawInput, FVector::UpVector, true);

				float DecelerationInterpSpeed = Math::Pow(1.0 - RawInput.Size(), 3.0);
				float Acceleration = Math::Lerp(HijackOwner.MovementSettings.Acceleration, HijackOwner.MovementSettings.Deceleration, DecelerationInterpSpeed);

				FVector TargetVelocity = MovementInput * HijackOwner.MovementSettings.MaxSpeed;
				FVector HorizontalVelocity = Math::VInterpConstantTo(MovementComponent.HorizontalVelocity, TargetVelocity, DeltaTime, Acceleration);

				MoveData.AddGravityAcceleration();
				MoveData.AddHorizontalVelocity(HorizontalVelocity);

				if (HijackOwner.MovementSettings.bShouldRotateWithVelocity)
					MoveData.InterpRotationToTargetFacingRotation(HijackOwner.MovementSettings.RotationSpeed);
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}
	}
}