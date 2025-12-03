class AMeltdownWorldSpinLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LaserMeshComp;
	default LaserMeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;
	default LaserMeshComp.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere)
	float Length = 2000.0;
	UPROPERTY(EditAnywhere)
	float Width = 30.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		LaserMeshComp.RelativeScale3D = FVector(Length, Width, Width);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Check where the laser ends
		FHazeTraceSettings Trace;
		Trace.TraceWithProfile(n"BlockAllDynamic");
		Trace.UseLine();
		Trace.IgnorePlayers();

		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + ActorForwardVector * Length);
		float TracedLength = Length;

		if (Hit.bBlockingHit)
			TracedLength = Hit.Location.Distance(ActorLocation);

		LaserMeshComp.RelativeScale3D = FVector(TracedLength, Width, Width);

		// Check if any players are in the laser
		for (auto Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;

			FVector LocalPosition = ActorTransform.InverseTransformPosition(Player.ActorLocation);
			if (LocalPosition.Z < -Width)
				continue;
			if (LocalPosition.Z > Width)
				continue;
			if (LocalPosition.Y < -Width)
				continue;
			if (LocalPosition.Y > Width)
				continue;

			if (LocalPosition.X < 0.0)
				continue;
			if (LocalPosition.X > TracedLength)
				continue;

			Player.KillPlayer();
		}
	}
};