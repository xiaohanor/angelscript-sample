class ASummitDarkCavePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default MeshComp.SetHiddenInGame(true);

	FHazeAcceleratedVector AccelVector;
	FVector TargetLocation;

	float LifeDuration = 2.15;
	float SpawnDuration = 3.25;
	float LifeTime;

	bool bCollisionOn;
	bool bDespawned;

	bool bIsActive = false;

	ASummitDarkCaveBell Bell;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccelVector.AccelerateTo(TargetLocation, 2.5, DeltaSeconds);
		ActorLocation = AccelVector.Value;

		if (LifeTime > 0.0)
			USummitDarkCavePlatformEffectHandler::Trigger_PlatformUpdateVelocity(this, FSummitDarkCavePlatformVelocityParams(AccelVector.Value.Size()));

		LifeTime -= DeltaSeconds;
		SpawnDuration -= DeltaSeconds;

		if (LifeTime <= 0.0 && !bDespawned)
		{
			bDespawned = true;
			USummitDarkCavePlatformEffectHandler::Trigger_OnPlatformDespawned(this);
		}

		if (LifeTime < -0.2 && bCollisionOn)
		{
			bCollisionOn = false;
			MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);		
		}

		if (SpawnDuration <= 0.0 && bIsActive)
		{
			DeactivatePlatform();
		}

		if (!bIsActive)
			return;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseBoxShape(FVector(500.0, 500.0, 40.0));
		TraceSettings.IgnoreActor(Game::Mio);
		TraceSettings.IgnoreActor(Game::Zoe);
		TraceSettings.IgnoreActor(Bell);
		TraceSettings.IgnoreActor(this);

		FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + FVector::UpVector);

		if (Hit.bBlockingHit)
		{
			PlatformImpact();
		}
	
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbActivatePlatform(FVector StartLocation, FVector NewTargetLocation, ASummitDarkCaveBell InBell)
	{
		AccelVector.SnapTo(StartLocation);
		ActorLocation = StartLocation;
		TargetLocation = NewTargetLocation;
		LifeTime = LifeDuration;
		Bell = InBell;
		bIsActive = true;
		bCollisionOn = true;
		bDespawned = false;
		MeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);		
		USummitDarkCavePlatformEffectHandler::Trigger_OnPlatformSpawned(this);
	}

	void DeactivatePlatform()
	{
		bIsActive = false;
		Bell.SpawnPoolComp.UnSpawn(this);
	}

	void PlatformImpact()
	{
		bIsActive = false;		
		USummitDarkCavePlatformEffectHandler::Trigger_OnPlatformImpactObject(this);
		
		bCollisionOn = false;
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);	

		if(Bell != nullptr)
			Bell.SpawnPoolComp.UnSpawn(this);
	}
};
