class UDeliverySplineMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DeliverySplineMoveCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	ADeliveryMechanism Delivery;

	FSplinePosition SplinePos;

	float CurrentSpeed;
	float TargetSpeed = 800.0;

	//When it starts to scale
	float MinDistanceStartScaling = 1000.0;
	//Max distance it scales to in terms of the multiplier
	float MaxDistanceStartScaling = 3000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Delivery = Cast<ADeliveryMechanism>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Delivery.bStartSplineMove)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Delivery.bStartSplineMove)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplinePos = Delivery.SplineComp.GetSplinePositionAtSplineDistance(0.0);
		Delivery.ActorLocation = SplinePos.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//Scale movement
		float FurthestDistance = Game::Mio.GetDistanceTo(Delivery) > Game::Zoe.GetDistanceTo(Delivery) ? Game::Mio.GetDistanceTo(Delivery) : Game::Zoe.GetDistanceTo(Delivery);
		// float FurthestDistance = Game::Mio.GetDistanceTo(Delivery);
		float ScaleMovement = 1.0;

		if (FurthestDistance > MinDistanceStartScaling)
		{
			float AugmentedDistance = FurthestDistance - MinDistanceStartScaling;
			AugmentedDistance /= MaxDistanceStartScaling;
			ScaleMovement = 1.2 - AugmentedDistance;
			PrintToScreen("ScaleMovement: " + ScaleMovement);
		}

		CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, TargetSpeed * ScaleMovement, DeltaTime, TargetSpeed / 1.5);
		PrintToScreen("CurrentSpeed: " + CurrentSpeed);
		SplinePos.Move(CurrentSpeed * DeltaTime);
		Delivery.ActorLocation = SplinePos.WorldLocation;

	}
}
