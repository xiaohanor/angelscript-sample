UCLASS(Abstract)
class APrisonBossVolleyProjectile : AHazeActor
{
	default ActorHiddenInGame = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent VolleyRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface DecalMaterial;
	UDecalComponent DecalComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SpawnTimeLike;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ImpactCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ImpactFF;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	FHazeRuntimeSpline RuntimeSpline;
	float SplineDist = 0.0;

	bool bActive = false;

	float Speed = 2200.0;

	FVector TargetLocation;

	FVector StartSpawnLocation;
	FVector TargetSpawnLocation;

	APrisonBoss Boss;

	UPROPERTY(BlueprintReadOnly)
	bool bPlayerControlled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnTimeLike.BindUpdate(this, n"UpdateSpawn");
		SpawnTimeLike.BindFinished(this, n"FinishSpawn");
	}

	void Prime(FVector TargetLoc, float Delay, bool bControlled)
	{
		StartSpawnLocation = ActorRelativeLocation;
		TargetSpawnLocation = TargetLoc;

		bPlayerControlled = bControlled;

		if (Delay == 0)
			Spawn();
		else
			Timer::SetTimer(this, n"Spawn", Delay);
	}

	UFUNCTION()
	private void Spawn()
	{
		SpawnTimeLike.PlayFromStart();
		SetActorHiddenInGame(false);

		UPrisonBossVolleyEffectEventHandler::Trigger_Primed(this);

		BP_Spawn();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Spawn() {}

	UFUNCTION()
	private void UpdateSpawn(float CurValue)
	{
		FVector Loc = Math::Lerp(StartSpawnLocation, TargetSpawnLocation, CurValue);
		SetActorRelativeLocation(Loc);
	}

	UFUNCTION()
	private void FinishSpawn()
	{
	}

	void Shoot(FVector TargetLoc, FVector TargetNormal)
	{
		RuntimeSpline.AddPoint(ActorLocation);

		bool bValidHit = !TargetLoc.Equals(FVector::ZeroVector);
		if (!bValidHit)
		{
			TargetLocation = ActorLocation + (FVector::UpVector * 6000.0);
		}
		else
		{
			TargetLocation = TargetLoc;
			FVector DirToTarget = (TargetLoc - ActorLocation).GetSafeNormal();
			FVector MidPoint = ActorLocation + (DirToTarget * 400.0);
			MidPoint.Z = ActorLocation.Z + 800.0;
			RuntimeSpline.AddPoint(MidPoint);

			FVector DirToOrigin = (ActorLocation - TargetLoc).GetSafeNormal();
			FVector MidPoint2 = TargetLoc + (DirToOrigin * 800.0);
			MidPoint2.Z = TargetLocation.Z + 1400.0;
			RuntimeSpline.AddPoint(MidPoint2);
		}

		RuntimeSpline.AddPoint(TargetLocation);

		if (bValidHit)
			RuntimeSpline.SetCustomExitTangentPoint(TargetLocation - (FVector::UpVector * 50.0));

		DecalComp = Decal::SpawnDecalAtLocation(DecalMaterial, FVector(20.0, 120.0, 120.0), TargetLoc);
		DecalComp.SetWorldRotation(FRotator::MakeFromX(TargetNormal));
		DecalComp.AddRelativeRotation(FRotator(0.0, 0.0, Math::RandRange(0.0, 360.0)));

		bActive = true;

		BP_Shoot();

		UPrisonBossVolleyEffectEventHandler::Trigger_Launched(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Shoot() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		SplineDist += Speed * DeltaTime;
		FVector Loc = RuntimeSpline.GetLocationAtDistance(SplineDist);
		SetActorLocation(Loc);
		
		if (Loc.Equals(TargetLocation, 5.0))
			Destroy();
	}

	void Dissipate()
	{
		bActive = false;

		if (DecalComp != nullptr)
			DecalComp.DestroyComponent(this);

		BP_Dissipate();

		UPrisonBossVolleyEffectEventHandler::Trigger_DissipateMidair(this);
		
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Dissipate() {}

	void Destroy()
	{
		bActive = false;

		if (DecalComp != nullptr)
			DecalComp.DestroyComponent(this);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (GetDistanceTo(Player) <= 80.0)
				Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(FVector::UpVector), DamageEffect, DeathEffect);
		}

		ForceFeedback::PlayWorldForceFeedback(ImpactFF, ActorLocation, true, this, 1.0, 200.0, 200.0);
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(ImpactCamShake, this, ActorLocation, 200.0, 400.0);

		UPrisonBossVolleyEffectEventHandler::Trigger_Impact(this);
		UPrisonBossEffectEventHandler::Trigger_VolleyProjectileImpact(Boss, FPrisonBossVolleyImpactData(ActorLocation));

		BP_Destroy();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Destroy() {}
}