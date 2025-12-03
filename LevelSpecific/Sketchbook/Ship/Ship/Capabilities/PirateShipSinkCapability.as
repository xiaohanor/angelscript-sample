class UPirateShipSinkCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	APirateShip PirateShip;
	UPirateShipMovementComponent MoveComp;
	UPirateWaterHeightComponent WaterHeightComp;

	FVector HorizontalForward;
	float VerticalSpeed = 0;
	FQuat SinkRotation = FQuat::Identity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PirateShip = Cast<APirateShip>(Owner);
		MoveComp = UPirateShipMovementComponent::Get(Owner);
		WaterHeightComp = UPirateWaterHeightComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasAppliedThisFrame())
			return false;

		if(!PirateShip.CanShipMove())
			return false;

		if(PirateShip.IsSinking())
			return true;

		// if(PirateShip.CurrentDamages.Num() < Pirate::Ship::SinkMaxDamages)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasAppliedThisFrame())
			return true;

		if(!PirateShip.CanShipMove())
			return true;

		if(!PirateShip.IsSinking())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HorizontalForward = PirateShip.ActorForwardVector.GetSafeNormal2D();
		PirateShip.StartSinking();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
		float HorizontalSpeed = HorizontalVelocity.Size();

		FVector HorizontalVelocityDirection;
		if(HorizontalSpeed < KINDA_SMALL_NUMBER)
			HorizontalVelocityDirection = PirateShip.ActorForwardVector.GetSafeNormal2D();
		else
			HorizontalVelocityDirection = HorizontalVelocity / HorizontalSpeed;

		HorizontalSpeed = Math::FInterpTo(HorizontalSpeed, 0, DeltaTime, Pirate::Ship::SinkDeceleration);

		HorizontalVelocityDirection = FQuat(FVector::UpVector, PirateShip.GetTurnAmount() * Pirate::Ship::TurnSpeed * 0.02) * HorizontalVelocityDirection;

		HorizontalVelocity = HorizontalVelocityDirection * HorizontalSpeed;

		FVector HorizontalDelta = HorizontalVelocity * DeltaTime;

		FVector UpVector = WaterHeightComp.GetWaterUpVector();
		FQuat WaterRotation = FQuat::MakeFromZX(UpVector, HorizontalForward);

		SinkRotation = Math::QInterpConstantTo(SinkRotation, Pirate::Ship::SinkTargetRotation.Quaternion(), DeltaTime, Pirate::Ship::SinkRotateSpeed);
		WaterRotation = SinkRotation * WaterRotation;

		MoveComp.AccWaterRotation.SpringTo(WaterRotation, Pirate::Ship::SpringStiffness, Pirate::Ship::SpringDamping, DeltaTime);

		VerticalSpeed = Math::FInterpConstantTo(VerticalSpeed, Pirate::Ship::SinkFallSpeed, DeltaTime, Pirate::Ship::SinkFallAcceleration);
		FVector VerticalDelta = FVector(0, 0, VerticalSpeed * DeltaTime);

		FVector NewLocation = PirateShip.ActorLocation + HorizontalDelta + VerticalDelta;
		MoveComp.ApplyMoveLocation(NewLocation, MoveComp.AccWaterRotation.Value, false);

		if(NewLocation.Z < Pirate::Ship::SinkDepthThreshold)
		{
			if(!PirateShip.HasSunk())
			{
				PirateShip.FinishSinking();
			}
		}
	}
};