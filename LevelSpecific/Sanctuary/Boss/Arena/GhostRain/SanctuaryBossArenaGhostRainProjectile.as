class ASanctuaryBossArenaGhostRainProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGodrayComponent GodrayComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ProjectileRoot;

	UPROPERTY(DefaultComponent, Attach = ProjectileRoot)
	USphereComponent TriggerComp;

	UPROPERTY()
	float FallSpeed;

	float ImpactHeight;
	
	ASanctuaryBossArenaFloatingPlatform FloatingPlatform;

	UPROPERTY()
	FHazeTimeLike FadeTimeLike;
	default FadeTimeLike.UseLinearCurveZeroToOne();
	default FadeTimeLike.Duration = 4.0;

	UPROPERTY()
	float TelegraphDuration = 2.0;

	float ZScale;

	bool bExploded = false;
	bool bProjectileSpawned = false;

	private USanctuaryCompanionAviationPlayerComponent AviationComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");
		FadeTimeLike.BindUpdate(this, n"FadeTimeLikeUpdate");
		FadeTimeLike.BindFinished(this, n"FadeTimeLikeFinished");

		//Find impact location
		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.UseSphereShape(TriggerComp.SphereRadius);

		auto HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation - FVector::UpVector * 10000.0);

		if (HitResult.bBlockingHit)
		{
			ImpactHeight = HitResult.ImpactPoint.Z;

			FloatingPlatform = Cast<ASanctuaryBossArenaFloatingPlatform>(HitResult.Actor);
		}
		else
			ImpactHeight = ActorLocation.Z - 10000.0;

		//Calculate godray size

		ZScale = Math::Clamp((ActorLocation.Z - ImpactHeight), 0.0, 4000.0) * 0.015;
		FadeTimeLike.Play();

		Timer::SetTimer(this, n"SpawnProjectile", TelegraphDuration + Math::RandRange(0.0, 1.0));
	}

	void SetAviationComp(USanctuaryCompanionAviationPlayerComponent PlayerAviationComp)
	{
		AviationComp = PlayerAviationComp;
		AviationComp.OnAviationStarted.AddUFunction(this, n"PlayerStartedAviating");
	}

	UFUNCTION()
	void PlayerStartedAviating(AHazePlayerCharacter Player)
	{
		if (!bProjectileSpawned)
			Timer::ClearTimer(this, n"SpawnProjectile");
		FadeTimeLike.SetPlayRate(3.0);
		FadeTimeLike.Reverse();
		bExploded = true;
		TriggerComp.SetGenerateOverlapEvents(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bExploded)
			return;

		if (!bProjectileSpawned)
			return;

		ProjectileRoot.AddWorldOffset(FVector::UpVector * -FallSpeed * DeltaSeconds);

		if (ProjectileRoot.WorldLocation.Z < ImpactHeight && !bExploded)
			Explode();
	}

	UFUNCTION()
	private void SpawnProjectile()
	{
		BP_SpawnProjectile();
		bProjectileSpawned = true;
	}

	UFUNCTION(BlueprintEvent)
	private void BP_SpawnProjectile(){}

	UFUNCTION()
	private void FadeTimeLikeUpdate(float CurrentValue)
	{
		GodrayComp.SetGodrayOpacity(CurrentValue * 0.2);
		GodrayComp.SetRelativeScale3D(FVector(12.0, 12.0, ZScale * 1));
	}

	UFUNCTION()
	private void FadeTimeLikeFinished()
	{
		if (FadeTimeLike.IsReversed())
			DestroyActor();
	}

	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		if (bExploded)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			Player.DamagePlayerHealth(0.5);
			Explode();
		}	
	}

	private void Explode()
	{
		bExploded = true;
		TriggerComp.SetGenerateOverlapEvents(false);
		BP_Explode();

		FVector ExplosionExtents = FVector(250.0, 230.0, 150.0);
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WeaponTraceEnemy);
		Trace.UseBoxShape(ExplosionExtents, ActorQuat);
		
		FVector Offset = FVector();
		Offset.Z = ExplosionExtents.Z * 0.5;
		FVector BoxLocation = ProjectileRoot.WorldLocation + Offset;
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(BoxLocation);
		for (auto Overlap : Overlaps)
		{
			if (Overlap.Actor != nullptr)
			{
				auto AsPlayer = Cast<AHazePlayerCharacter>(Overlap.Actor);
				if (AsPlayer != nullptr)
					AsPlayer.DamagePlayerHealth(0.5);
			}
		}
		 //Debug::DrawDebugBox(BoxLocation, ExplosionExtents, ActorRotation, ColorDebug::Ruby, 3.0, 1.0);

		if (FloatingPlatform != nullptr)
		{
			FauxPhysics::ApplyFauxImpulseToActorAt(FloatingPlatform, ActorLocation, FVector::DownVector * 500.0);
		}

		FadeTimeLike.SetPlayRate(3.0);
		FadeTimeLike.Reverse();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode()
	{
	}
};