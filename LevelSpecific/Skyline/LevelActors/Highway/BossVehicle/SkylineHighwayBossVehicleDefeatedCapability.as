class USkylineHighwayBossVehicleDefeatedCapability : UHazeCapability
{
	ASkylineHighwayBossVehicle Vehicle;
	FVector DefeatedLocation;
	FVector Direction;
	FHazeAcceleratedFloat AccSpeed;
	bool bCompleted;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Vehicle = Cast<ASkylineHighwayBossVehicle>(Owner);

		ASkylineHighwayBossVehicleDefeatedLocation Loc = TListedActors<ASkylineHighwayBossVehicleDefeatedLocation>().Single;
		DefeatedLocation = Loc.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Vehicle.CurrentMode == ESkylineHighwayBossVehicleMode::Defeated)
			return true;
		if(bCompleted)
			return false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > 2.5)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Vehicle.ConeRotateComp.ApplyImpulse(Vehicle.ActorLocation + Vehicle.ActorRightVector * 300, FVector::UpVector * 5300);

		for(AHazePlayerCharacter Player : Game::Players)
		{
			FHazePointOfInterestFocusTargetInfo Info = FHazePointOfInterestFocusTargetInfo();
			Info.SetFocusToActor(Owner);
			FApplyPointOfInterestSettings Settings = FApplyPointOfInterestSettings();
			Player.ApplyPointOfInterest(this, Info, Settings);
		}

		Direction = (DefeatedLocation - Owner.ActorLocation).GetSafeNormal();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bCompleted = true;
		Vehicle.OnDefeatedCompleted.Broadcast();
		Vehicle.AddActorVisualsBlock(this);
		TArray<AActor> Attached;
		Vehicle.GetAttachedActors(Attached);
		for(AActor Child : Attached)
		{
			if (!IsValid(Child))
				continue;
			if (!IsValid(Child.RootComponent))
				continue;

			if (Child.RootComponent.IsAttachedTo(Vehicle))
				Child.AddActorVisualsBlock(this);
		}

		for(AHazePlayerCharacter Player : Game::Players)
		{
			Player.ClearPointOfInterestByInstigator(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Owner.ActorLocation += Direction * DeltaTime * 1600;
		AccSpeed.AccelerateTo(250, 1, DeltaTime);
		Owner.AddActorWorldRotation(FRotator(0, 1, 0.25) * AccSpeed.Value * DeltaTime);
	}
}