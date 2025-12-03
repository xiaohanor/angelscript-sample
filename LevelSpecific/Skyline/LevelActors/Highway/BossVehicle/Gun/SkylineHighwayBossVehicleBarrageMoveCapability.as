class USkylineHighwayBossVehicleBarrageMoveCapability : UHazeCapability
{
	ASkylineHighwayBossVehicle Vehicle;
	ASkylineHighwayBossVehicleArenaCenter Center;
	USkylineHighwayBossVehicleGunComponent GunComp;

	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedRotator AccRotation;
	float StartMoveSpeed = 2000;
	float BarrageMoveSpeed = 400;

	int SplineIndex;
	TArray<UHazeSplineComponent> Splines;
	UHazeSplineComponent MoveSpline;
	FVector MoveSplineOffset;
	float MoveDistance;

	FHazeRuntimeSpline StartSpline;
	float StartDistance;
	FVector StartLocation;
	FRotator StartRotation;
	FVector MoveDirection;

	bool bArrivedAtStart;
	bool bReverse;

	float ActivateInterval = 8;
	float ActivateTimer;

	float FireLaunchSpeed = 5000;
	float FireInterval = 0.01;
	float FireTime;

	float AlternateFireInterval = 0.1;
	float AlternateFireTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Vehicle = Cast<ASkylineHighwayBossVehicle>(Owner);
		Center = TListedActors<ASkylineHighwayBossVehicleArenaCenter>().Single;
		GunComp = USkylineHighwayBossVehicleGunComponent::GetOrCreate(Owner);

		for(AHazeActor Spline : Vehicle.BlasterSplines)
		{
			Splines.Add(UHazeSplineComponent::Get(Spline));
		}

		Owner.BlockCapabilities(n"Barrage", this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(Vehicle.CurrentMode != ESkylineHighwayBossVehicleMode::Arena)
			return;

		ActivateTimer += DeltaTime;
		if(ActivateTimer < ActivateInterval)
			return;

		if(GunComp.bInUse)
			return;

		Vehicle.StartBlasterMode();
		ActivateTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Vehicle.CurrentMode == ESkylineHighwayBossVehicleMode::Barrage)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Vehicle.CurrentMode != ESkylineHighwayBossVehicleMode::Barrage)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccLocation.SnapTo(Owner.ActorLocation);
		AccRotation.SnapTo(Owner.ActorRotation);
		MoveSpline = Splines[SplineIndex];

		if(bReverse)
			MoveDistance = MoveSpline.SplineLength;
		else
			MoveDistance = 0;

		if(bReverse)
			MoveDirection = (MoveSpline.GetWorldLocationAtSplineDistance(MoveDistance - 10) - MoveSpline.GetWorldLocationAtSplineDistance(MoveDistance)).GetSafeNormal2D();
		else
			MoveDirection = (MoveSpline.GetWorldLocationAtSplineDistance(MoveDistance + 10) - MoveSpline.GetWorldLocationAtSplineDistance(MoveDistance)).GetSafeNormal2D();

		StartRotation = (Center.ActorLocation - MoveSpline.WorldLocation).ConstrainToPlane(FVector::UpVector).ConstrainToPlane(MoveSpline.RightVector).Rotation();
		MoveSplineOffset = StartRotation.ForwardVector * -2100 + FVector::UpVector * 300;
		StartLocation = MoveSpline.GetWorldLocationAtSplineDistance(MoveDistance) + MoveSplineOffset;

		StartDistance = 0;
		StartSpline = FHazeRuntimeSpline();
		StartSpline.AddPoint(Owner.ActorLocation);
		FVector MidPoint = (Owner.ActorLocation + StartLocation) / 2;
		MidPoint.Z += 1000;
		StartSpline.AddPoint(MidPoint);
		StartSpline.AddPoint(StartLocation);

		bArrivedAtStart = false;
		FireTime = 0;

		USkylineHighwayBossVehicleEffectHandler::Trigger_OnMoveToBarrage(Vehicle);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Vehicle.StartArenaMode();

		SplineIndex++;
		if(SplineIndex >= Splines.Num())
		{
			bReverse = !bReverse;
			SplineIndex = 0;
		}

		if(!Owner.IsCapabilityTagBlocked(n"Barrage"))
			Owner.BlockCapabilities(n"Barrage", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccRotation.SpringTo(StartRotation, 25, 0.5, DeltaTime);
		Owner.ActorRotation = AccRotation.Value;

		if(!bArrivedAtStart)
		{
			StartDistance += StartMoveSpeed * DeltaTime;
			Owner.ActorLocation = StartSpline.GetLocationAtDistance(StartDistance);

			if(StartDistance > StartSpline.Length)
			{
				bArrivedAtStart = true;
				Owner.UnblockCapabilities(n"Barrage", this);
			}

			return;
		}

		if(bReverse)
		{
			MoveDistance -= BarrageMoveSpeed * DeltaTime;
			Owner.ActorLocation = MoveSpline.GetWorldLocationAtSplineDistance(MoveDistance) + MoveSplineOffset;
			if(MoveDistance < 0)
				Vehicle.StartArenaMode();
		}
		else
		{
			MoveDistance += BarrageMoveSpeed * DeltaTime;
			Owner.ActorLocation = MoveSpline.GetWorldLocationAtSplineDistance(MoveDistance) + MoveSplineOffset;
			if(MoveDistance > MoveSpline.SplineLength)
				Vehicle.StartArenaMode();
		}

		bool bPassedPlayers = true;
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(MoveDirection.DotProduct((Player.ActorLocation + MoveDirection * 750) - Owner.ActorLocation) > 0)
				bPassedPlayers = false;
		}
		if(bPassedPlayers)
			Vehicle.StartArenaMode();
	}
}