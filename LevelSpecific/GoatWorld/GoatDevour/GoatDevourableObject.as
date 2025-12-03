class AGoatDevourableObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ObjectRoot;

	UPROPERTY(DefaultComponent)
	UGoatDevourResponseComponent DevourResponseComp;

	UPROPERTY(EditAnywhere)
	float SpitLength = 500.0;
	
	UPROPERTY(EditAnywhere)
	float SpitSpeed = 1200.0;

	UPROPERTY(EditAnywhere)
	float Gravity = 4000.0;

	UPROPERTY(EditAnywhere)
	float Height = 250.0;

	UPROPERTY(EditAnywhere)
	FRotator RotationRate = FRotator::ZeroRotator;

	UPROPERTY(EditAnywhere)
	bool bDestroyOnImpact = false;

	UPROPERTY(EditAnywhere)
	bool bRespawn = false;

	bool bSpitOut = false;

	bool bLanded = false;

	FVector SpitDirection;
	FVector Velocity;
	FVector TargetLocation;

	UGoatDevourPlacementComponent TargetPlacementComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DevourResponseComp.OnDevoured.AddUFunction(this, n"Devoured");
		DevourResponseComp.OnSpit.AddUFunction(this, n"Spit");
	}

	UFUNCTION()
	private void Devoured()
	{
		bSpitOut = false;
	}

	UFUNCTION()
	private void Spit(FGoatDevourSpitParams Params)
	{
		SetActorRotation(FQuat(Params.Direction.Rotation()));
		SpitDirection = Params.Direction;

		FVector TargetLoc = ActorLocation + (Params.Direction * SpitLength);
		if (Params.PlacementComp != nullptr)
		{
			TargetPlacementComp = Params.PlacementComp;
			TargetLoc = Params.PlacementComp.WorldLocation;
		}

		if (Params.TargetLocation != FVector::ZeroVector)
			TargetLoc = Params.TargetLocation;

		TargetLocation = TargetLoc;

		Velocity = Trajectory::CalculateVelocityForPathWithHeight(ActorLocation, TargetLoc, Gravity, Height);

		bSpitOut = true;

		SetActorEnableCollision(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bSpitOut)
		{
			Velocity -= FVector(0.0, 0.0, Gravity) * DeltaTime;
			FVector DeltaVelocity = Velocity * DeltaTime;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
			Trace.IgnorePlayers();
			Trace.IgnoreActor(this);
			Trace.UseSphereShape(25.0);
			
			FVector TraceLoc = ActorLocation + FVector(0.0, 0.0, 50.0);
			FHitResult HitResult = Trace.QueryTraceSingle(TraceLoc, TraceLoc + DeltaVelocity);
			if (HitResult.bBlockingHit || ActorLocation.Equals(TargetLocation))
			{
				if (HitResult.bBlockingHit)
					TeleportActor(HitResult.ImpactPoint, ActorRotation, this);
				
				bLanded = true;
				bSpitOut = false;
				TargetPlacementComp = nullptr;

				Impact(HitResult);

				return;
			}

			AddActorWorldOffset(DeltaVelocity);
			if (RotationRate != FRotator::ZeroRotator)
				AddActorLocalRotation(RotationRate * DeltaTime);
		}
	}

	void Impact(FHitResult Hit)
	{
		UGoatDevourSpitImpactResponseComponent ResponseComp = UGoatDevourSpitImpactResponseComponent::Get(Hit.Actor);
		if (ResponseComp != nullptr)
			ResponseComp.Impact(this, Hit);

		BP_Impact(Hit);

		if (bDestroyOnImpact)
			DestroyActor();

		if (bRespawn)
		{
			SetActorHiddenInGame(true);
			
			Timer::SetTimer(this, n"Respawn", 1.0);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_Impact(FHitResult Hit) {}

	UFUNCTION()
	void Respawn()
	{
		SetActorEnableCollision(true);
		DevourResponseComp.bDevoured = false;
		DevourResponseComp.bSpitOut = false;
		DevourResponseComp.bTravellingToMouth = false;
		bLanded = false;
		TeleportActor(DevourResponseComp.OriginalTransform.Location, DevourResponseComp.OriginalTransform.Rotation.Rotator(), this);

		BP_Respawn();

		SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Respawn() {}
}