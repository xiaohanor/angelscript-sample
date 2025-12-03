class UPirateShipMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	APirateShip PirateShip;
	UPirateShipMovementComponent MoveComp;
	UPirateWaterHeightComponent WaterHeightComp;
	UPirateShipDepenetrationComponent DepenetrationComp;
	float LastImpactTime = 0;
	bool bHasDispatchedStartSailing = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PirateShip = Cast<APirateShip>(Owner);
		MoveComp = UPirateShipMovementComponent::Get(Owner);
		WaterHeightComp = UPirateWaterHeightComponent::Get(Owner);
		DepenetrationComp = UPirateShipDepenetrationComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasAppliedThisFrame())
			return false;

		if(!PirateShip.CanShipMove())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasAppliedThisFrame())
			return true;

		if(!PirateShip.CanShipMove())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PirateShip.AccSailYaw.Value = PirateShip.MainMastBoomRoot.RelativeRotation.Yaw;

		if(!bHasDispatchedStartSailing)
		{
			PirateShip.OnStartSailing.Broadcast();
			bHasDispatchedStartSailing = true;
		}

		// if(PirateShip.Plank != nullptr)
		// {
		// 	PirateShip.Plank.Drop();
		// 	PirateShip.Plank = nullptr;
		// }
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PirateShip.AngleSails(DeltaTime);

		float HorizontalSpeed = MoveComp.HorizontalVelocity.Size();

		HorizontalSpeed = Math::FInterpConstantTo(HorizontalSpeed, Pirate::Ship::MoveSpeed, DeltaTime, Pirate::Ship::Acceleration);

		FVector HorizontalVelocityDirection = FQuat(FVector::UpVector, PirateShip.GetTurnAmount() * Pirate::Ship::TurnSpeed * 0.02) * PirateShip.ActorForwardVector.GetSafeNormal2D();

		FVector HorizontalVelocity = HorizontalVelocityDirection * HorizontalSpeed;

		FVector HorizontalDelta = HorizontalVelocity * DeltaTime;

		FVector UpVector = WaterHeightComp.GetWaterUpVector();
		FQuat WaterRotation = FQuat::MakeFromZX(UpVector, HorizontalVelocityDirection);

		MoveComp.AccWaterRotation.SpringTo(WaterRotation, Pirate::Ship::SpringStiffness, Pirate::Ship::SpringDamping, DeltaTime);

		FVector NewLocation = PirateShip.ActorLocation + HorizontalDelta;
		FVector DepenetrationDelta;
		TArray<AActor> HitActors;
		if(DepenetrationComp.Depenetrate(NewLocation, MoveComp.AccWaterRotation.Value, DepenetrationDelta, HitActors))
		{
			// For some reason it works better with Delta * DeltaTime than just delta...
			MoveComp.ApplyMoveDelta(DepenetrationDelta * DeltaTime, MoveComp.AccWaterRotation.Value);

			FVector Impulse = MoveComp.HorizontalVelocity - HorizontalVelocity;
			if(Impulse.Size() > Pirate::Ship::ImpulseNeededForImpact && Time::GetGameTimeSince(LastImpactTime) > Pirate::Ship::ImpactResetTime)
			{
				MoveComp.AddRotationalImpulse(Impulse);

				for(auto& HitActor : HitActors)
				{
					auto ResponseComp = UPirateShipImpactResponseComponent::Get(HitActor);
					if(ResponseComp != nullptr)
					{
						FPirateShipOnImpactData Data;
						Data.Impulse = Impulse;
						ResponseComp.OnImpact.Broadcast(Data);
					}
				}

				LastImpactTime = Time::GameTimeSeconds;
			}
		}
		else
		{
			MoveComp.ApplyMoveLocation(NewLocation, MoveComp.AccWaterRotation.Value);
		}
	}
};