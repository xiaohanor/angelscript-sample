class AMedallionHydraMachineGunAttackActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	UGodrayComponent TelegraphGodRayComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent AttackQueueComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent TargetQueueComp;

	UPROPERTY()
	TSubclassOf<ASanctuaryHydraSplineRunSpamProjectile> ProjectileClass;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossMedallionHydra Hydra;

	UPROPERTY(EditAnywhere)
	float DistanceToWaterLevel = 2400.0;

	FHazeAcceleratedRotator AccHeadRot;

	const float ProjectileInterval = 0.7;
	AHazePlayerCharacter TargetPlayer;

	float TargetMioAlpha = 0.0;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bActive)
			return;

		FVector DirectionVector = (Math::Lerp(Game::Zoe.ActorCenterLocation, Game::Mio.ActorCenterLocation, TargetMioAlpha) - HeadRoot.WorldLocation);
		FVector Direction = DirectionVector.GetSafeNormal();
		FRotator Rotation = FRotator::MakeFromXZ(Direction, FVector::UpVector);
		AccHeadRot.AccelerateTo(Rotation, 0.5, DeltaSeconds);

		HeadRoot.SetWorldRotation(AccHeadRot.Value);
	}

	UFUNCTION()
	void Activate()
	{
		bActive = true;

		TargetQueueComp.Idle(4.0);
		TargetQueueComp.Duration(2.0, this, n"TargetOtherPlayer");
		TargetQueueComp.Idle(2.0);
		TargetQueueComp.ReverseDuration(2.0, this, n"TargetOtherPlayer");
		TargetQueueComp.Event(this, n"Deactivate");

		AttackQueueComp.Idle(1.0);
		AttackQueueComp.Event(this, n"StartShootingProjectiles");

		Hydra.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot, EMedallionHydraMovePivotPriority::High, 2.0);
		Hydra.EnterMhAnimation(EFeatureTagMedallionHydra::MachineGun);

		Hydra.BlockLaunchProjectiles(this);

		FVector DirectionVector = (Math::Lerp(Game::Zoe.ActorCenterLocation, Game::Mio.ActorCenterLocation, TargetMioAlpha) - HeadRoot.WorldLocation);
		FVector Direction = DirectionVector.GetSafeNormal();
		FRotator Rotation = FRotator::MakeFromXZ(Direction, FVector::UpVector);
		AccHeadRot.SnapTo(Rotation);

		TelegraphGodRayComp.SetGodrayOpacity(1.0);
	}

	UFUNCTION()
	void ActivateInfinite()
	{
		bActive = true;

		TargetQueueComp.SetLooping(true);
		TargetQueueComp.Idle(1.0);
		TargetQueueComp.Duration(2.0, this, n"TargetOtherPlayer");
		TargetQueueComp.Idle(4.0);
		TargetQueueComp.ReverseDuration(2.0, this, n"TargetOtherPlayer");
		TargetQueueComp.Idle(3.0);

		AttackQueueComp.Idle(2.0);
		AttackQueueComp.Event(this, n"StartShootingUnfairProjectiles");

		Hydra.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot, EMedallionHydraMovePivotPriority::High, 2.0);
		Hydra.EnterMhAnimation(EFeatureTagMedallionHydra::Roar);

		Hydra.BlockLaunchProjectiles(this);

		FVector DirectionVector = (Math::Lerp(Game::Zoe.ActorCenterLocation, Game::Mio.ActorCenterLocation, TargetMioAlpha) - HeadRoot.WorldLocation);
		FVector Direction = DirectionVector.GetSafeNormal();
		FRotator Rotation = FRotator::MakeFromXZ(Direction, FVector::UpVector);
		AccHeadRot.SnapTo(Rotation);

		TelegraphGodRayComp.SetGodrayOpacity(1.0);
	}

	UFUNCTION()
	private void StartShootingProjectiles()
	{
		AttackQueueComp.SetLooping(true);
		AttackQueueComp.Idle(ProjectileInterval);
		AttackQueueComp.Event(this, n"ShootProjectile");
	}

	UFUNCTION()
	private void StartShootingUnfairProjectiles()
	{
		AttackQueueComp.SetLooping(true);

		for (int i = 0; i < 5; i++)
		{
			AttackQueueComp.Idle(1.0);
			AttackQueueComp.Event(this, n"ShootProjectile");
		}

		AttackQueueComp.Idle(1.0);
	}

	UFUNCTION()
	private void TargetOtherPlayer(float Alpha)
	{
		TargetMioAlpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
	}

	UFUNCTION()
	private void ShootProjectile()
	{
		auto SpawnedProjectile = SpawnActor(ProjectileClass, HeadRoot.WorldLocation, HeadRoot.WorldRotation, bDeferredSpawn = true);
		SpawnedProjectile.KillZ = ActorLocation.Z - DistanceToWaterLevel;
		FinishSpawningActor(SpawnedProjectile);
	}

	UFUNCTION()
	private void ShootProjectileUnfair()
	{
		FVector Forward = Math::GetRandomConeDirection(HeadRoot.ForwardVector, 0.1);
		auto SpawnedProjectile = SpawnActor(ProjectileClass, HeadRoot.WorldLocation, Forward.Rotation(), bDeferredSpawn = true);
		SpawnedProjectile.KillZ = ActorLocation.Z - DistanceToWaterLevel;
		SpawnedProjectile.Speed = 10000.0;
		FinishSpawningActor(SpawnedProjectile);
	}

	UFUNCTION()
	void Deactivate()
	{
		bActive = false;
		AttackQueueComp.Empty();
		AttackQueueComp.SetLooping(false);

		TargetQueueComp.Empty();

		Hydra.MoveHeadPivotComp.Clear(this);
		Hydra.ExitMhAnimation(EFeatureTagMedallionHydra::MachineGun);

		Hydra.ClearBlockLaunchProjectiles(this);

		TelegraphGodRayComp.SetGodrayOpacity(0.0);
	}
};