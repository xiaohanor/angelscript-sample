class USkylineHighwayBossVehicleSplineMoveCapability : UHazeCapability
{
	USkylineHighwayBossVehicleGunComponent GunComp;

	ASkylineHighwayBossVehicle Vehicle;
	FHazeAcceleratedVector AccLocation;
	float InitialMoveSpeed = 35000;
	float MoveSpeed = 2000;
	float CurrentSplineDistance = 0;
	UHazeSplineComponent Spline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GunComp = USkylineHighwayBossVehicleGunComponent::GetOrCreate(Owner);
		Vehicle = Cast<ASkylineHighwayBossVehicle>(Owner);
		Spline = Vehicle.MoveSpline.Spline;
		AccLocation.SnapTo(Spline.GetWorldLocationAtSplineDistance(0));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Vehicle.CurrentMode == ESkylineHighwayBossVehicleMode::Move)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Vehicle.CurrentMode == ESkylineHighwayBossVehicleMode::Move)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccLocation.SnapTo(Owner.ActorLocation);
		GunComp.EnableVolley();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GunComp.DisableVolley();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ClosestLocation = FVector::ZeroVector;
		float ClosestPlayerDistance = BIG_NUMBER;
		for(AHazePlayerCharacter Player : Game::Players)
		{
			float Closest = Player.GetDistanceTo(Owner);
			if(Closest < ClosestPlayerDistance)
			{
				ClosestPlayerDistance = Closest;
				ClosestLocation = Player.ActorLocation;
			}
		}

		float ClosestSplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(ClosestLocation);
		float TargetSplineDistance = ClosestSplineDistance + 5000;

		float Direction = TargetSplineDistance > CurrentSplineDistance ? 1 : -1;
		float FinalSpeed = TargetSplineDistance > CurrentSplineDistance + 10000 ? InitialMoveSpeed : MoveSpeed;

		if(Math::Abs(CurrentSplineDistance - TargetSplineDistance) > 500)
			CurrentSplineDistance += DeltaTime * FinalSpeed * Direction;

		FVector SplineLocation = Spline.GetWorldLocationAtSplineDistance(CurrentSplineDistance);

		float Distance = Math::Clamp(Vehicle.Velocity.Size(), 350, BIG_NUMBER);
		FVector FinalLocation = SplineLocation + Owner.ActorRightVector * Math::Sin(ActiveDuration * 1.25) * Distance;

		AccLocation.SpringTo(FinalLocation, 25, 0.5, DeltaTime);
		Owner.ActorLocation = AccLocation.Value;
	}
}