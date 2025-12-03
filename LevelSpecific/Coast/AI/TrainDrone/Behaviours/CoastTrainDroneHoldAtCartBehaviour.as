class UCoastTrainDroneHoldAtCartBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UCoastTrainDroneSettings Settings;

	ACoastTrainCart TrainCart;
	FVector TrainCartBounds;
	float DistAlongCart = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastTrainDroneSettings::GetSettings(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
		OnRespawn(); // In case owner is not spawned by spawner
	}

	UFUNCTION()
	private void OnRespawn()
	{
		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr && RespawnComp.Spawner != nullptr && RespawnComp.Spawner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(RespawnComp.Spawner.AttachParentActor);
		else if (Owner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(Owner.AttachParentActor);
		else
			TrainCart = nullptr;

		if (TrainCart != nullptr)
		{
			// Get dimensions of cart
			FVector Dummy;
			TrainCart.GetActorLocalBounds(true, Dummy, TrainCartBounds);
		}			
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (TrainCart == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	
		FVector FromCart = Owner.ActorCenterLocation - TrainCart.ActorCenterLocation;
		DistAlongCart = Math::Clamp(TrainCart.ActorForwardVector.DotProduct(FromCart), -TrainCartBounds.X, TrainCartBounds.X);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector TrainCartLoc = TrainCart.ActorCenterLocation;
		FVector Destination = TrainCartLoc + TrainCart.ActorForwardVector * DistAlongCart;
		float DistToCenter = Math::Abs(TrainCart.ActorRightVector.DotProduct(OwnLoc - TrainCartLoc));
		float SpeedFactor = 1.0;
		if ((OwnLoc.Z < TrainCartLoc.Z) && (DistToCenter < TrainCartBounds.Y))
		{
			// Below cart, move out from under it			
			Destination += TrainCart.ActorRightVector * TrainCartBounds.Y * 2.0;
		}
		else if (Owner.ActorLocation.Z < TrainCartLoc.Z + Settings.HoldAtCartHeight * 0.5)
		{
			// Low down, move up
			Destination = Owner.ActorLocation + FVector::UpVector * 1000.0;
		}
		else
		{
			// Move to above center of cart, then keep station while looking backwards in train direction
			Destination += FVector::UpVector * Settings.HoldAtCartHeight;
			DestinationComp.RotateInDirection(-TrainCart.ActorForwardVector);
			SpeedFactor = Math::GetMappedRangeValueClamped(FVector2D(TrainCartBounds.Y * 2.0, TrainCartBounds.Y * 0.25), FVector2D(1.0, 0.0), DistToCenter);
		}

		DestinationComp.MoveTowards(Destination, Settings.HoldAtCartSpeed * SpeedFactor);
	}
}