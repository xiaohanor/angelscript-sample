class USkylineHighwayBossVehicleArenaMoveCapability : UHazeCapability
{
	USkylineHighwayBossVehicleGunComponent GunComp;
	
	ASkylineHighwayBossVehicle Vehicle;
	float SplineDistance;
	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedFloat AccMoveSpeed;
	float StartSpeed = 2000;
	float MoveSpeed = 900;
	bool bReverse;

	float StartDistance;
	FHazeRuntimeSpline StartSpline;
	bool bArrivedAtStart;

	float PauseInterval = 4;
	float PauseDuration = 0.25;
	float PauseIntervalTime;
	float PauseTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GunComp = USkylineHighwayBossVehicleGunComponent::GetOrCreate(Owner);
		Vehicle = Cast<ASkylineHighwayBossVehicle>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Vehicle.CurrentMode == ESkylineHighwayBossVehicleMode::Arena)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Vehicle.CurrentMode == ESkylineHighwayBossVehicleMode::Arena)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccLocation.SnapTo(Owner.ActorLocation);
		AccRotation.SnapTo(Owner.ActorRotation);
		PauseTime = Time::GameTimeSeconds;

		StartDistance = 0;
		StartSpline = FHazeRuntimeSpline();

		FVector SplineLoc = Vehicle.ArenaSpline.Spline.GetWorldLocationAtSplineDistance(SplineDistance);
		FVector MidPoint = (Owner.ActorLocation + SplineLoc) / 2;
		MidPoint.Z += 1000;
		StartSpline.AddPoint(Owner.ActorLocation);
		StartSpline.AddPoint(MidPoint);
		StartSpline.AddPoint(SplineLoc);

		bArrivedAtStart = StartSpline.Points[0].Distance(StartSpline.Points[2]) < 100;
		if(bArrivedAtStart)
			GunComp.EnableVolley();

		AccMoveSpeed.SnapTo(0);

		USkylineHighwayBossVehicleEffectHandler::Trigger_OnMoveToArenaSpline(Vehicle);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GunComp.DisableVolley();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccRotation.SpringTo(FRotator(0, 0, 0), 5, 0.5, DeltaTime);
		Owner.ActorRotation = AccRotation.Value;

		if(!bArrivedAtStart)
		{
			StartDistance += DeltaTime * StartSpeed;

			FVector SplineLocation = StartSpline.GetLocationAtDistance(StartDistance);
			FVector FinalLocation = SplineLocation + FVector::UpVector * Math::Sin(ActiveDuration * 2) * 200;
			Owner.ActorLocation = FinalLocation;

			if(StartDistance > StartSpline.Length)
			{
				bArrivedAtStart = true;
				GunComp.EnableVolley();
			}

			return;
		}

		if(Time::GetGameTimeSince(PauseTime) > PauseInterval + PauseDuration)
		{
			bReverse = !bReverse;
			AccMoveSpeed.SnapTo(0);
			PauseInterval = Math::RandRange(10, 15);
			PauseTime = Time::GameTimeSeconds;
		}

		int Dir = 1;
		if(bReverse)
			Dir = -1;

		if(SplineDistance >= Vehicle.ArenaSpline.Spline.SplineLength)
			SplineDistance = SplineDistance - Vehicle.ArenaSpline.Spline.SplineLength;
		if(SplineDistance < 0)
			SplineDistance = Vehicle.ArenaSpline.Spline.SplineLength + SplineDistance;

		if(Time::GetGameTimeSince(PauseTime) > PauseDuration)
		{
			AccMoveSpeed.AccelerateTo(MoveSpeed, 0.5, DeltaTime);
			SplineDistance += DeltaTime * AccMoveSpeed.Value * Dir;
		}

		FVector SplineLocation = Vehicle.ArenaSpline.Spline.GetWorldLocationAtSplineDistance(SplineDistance);
		FVector FinalLocation = SplineLocation + FVector::UpVector * Math::Sin(ActiveDuration * 2) * 200;
		Owner.ActorLocation = FinalLocation;
	}
}