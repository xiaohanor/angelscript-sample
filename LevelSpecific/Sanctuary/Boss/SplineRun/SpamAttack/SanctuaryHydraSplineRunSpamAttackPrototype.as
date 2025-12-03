class ASanctuaryHydraSplineRunSpamAttackPrototype : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ProjectileSpawnLocationComp;

	UPROPERTY()
	TSubclassOf<ASanctuaryHydraSplineRunSpamProjectile> ProjectileClass;

	AHazePlayerCharacter TargetPlayer;

	FRotator TargetRotation;
	FHazeAcceleratedRotator AcceleratedRot;

	UPROPERTY(EditAnywhere)
	float ProjectileInterval = 0.35;

	UPROPERTY(EditAnywhere)
	float DistanceToWaterLevel = 2400.0;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent AttackSEQQueueComp;

	UPROPERTY(EditAnywhere)
	bool bAttackAutomatically = true;

	UPROPERTY(EditAnywhere)
	bool bSidescrollerChaser = false;

	UPROPERTY(EditAnywhere)
	EHazePlayer InitialTargetPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		AddActorDisable(this);

		if (bAttackAutomatically)
		{
			DevToggleHydraPrototype::SplineRunMachineGun.MakeVisible();

			if (DevToggleHydraPrototype::SplineRunMachineGun.IsEnabled())
				StartAttackSEQ();

			DevToggleHydraPrototype::SplineRunMachineGun.BindOnChanged(this, n"HandleDevToggled");
		}

		if (bSidescrollerChaser)
		{
			DevToggleHydraPrototype::SplineRunMachineGun.MakeVisible();

			if (DevToggleHydraPrototype::SplineRunMachineGun.IsEnabled())
				StartChase();

			DevToggleHydraPrototype::SplineRunMachineGun.BindOnChanged(this, n"HandleDevToggled");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (TargetPlayer == nullptr)
			return;

		TargetRotation = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal().Rotation();
		AcceleratedRot.AccelerateTo(TargetRotation, 1.0, DeltaSeconds);

		SetActorRotation(AcceleratedRot.Value);
	}

	UFUNCTION()
	void Attack(AHazePlayerCharacter Player)
	{
		if (TargetPlayer == nullptr)
		{
			TargetPlayer = Player;
			RemoveActorDisable(this);

			TargetRotation = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal().Rotation();
			AcceleratedRot.SnapTo(TargetRotation);
		}
		
		TargetPlayer = Player;

		QueueComp.SetLooping(true);
		QueueComp.Event(this, n"Shoot");
		QueueComp.Idle(ProjectileInterval);
	}

	UFUNCTION()
	void StopAttacking()
	{
		QueueComp.SetLooping(false);
	}

	UFUNCTION()
	private void Shoot()
	{
		auto Projectile = SpawnActor(ProjectileClass, ProjectileSpawnLocationComp.WorldLocation, ProjectileSpawnLocationComp.WorldRotation, bDeferredSpawn = true);
		FinishSpawningActor(Projectile);
	}

	UFUNCTION()
	private void SwitchPlayerAndAttack()
	{
		TargetPlayer = TargetPlayer.OtherPlayer;
		Attack(TargetPlayer);
	}

	private void StartAttackSEQ()
	{
		RemoveActorDisable(this);

		TargetPlayer = Game::GetPlayer(InitialTargetPlayer);

		TargetRotation = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal().Rotation();
		AcceleratedRot.SnapTo(TargetRotation);

		AttackSEQQueueComp.SetLooping(true);
		AttackSEQQueueComp.Idle(3.0);
		AttackSEQQueueComp.Event(this, n"SwitchPlayerAndAttack");
		AttackSEQQueueComp.Idle(5.0);
		AttackSEQQueueComp.Event(this, n"StopAttacking");
	}

	private void StartChase()
	{
		Attack(Game::GetPlayer(InitialTargetPlayer));
	}

	UFUNCTION()
	private void HandleDevToggled(bool bNewState)
	{
		if (bNewState)
		{
			if (!bSidescrollerChaser)
				StartAttackSEQ();
			else
				StartChase();
		}
		else
			DisableAttackSEQ();
	}

	private void DisableAttackSEQ()
	{
		StopAttacking();
		AttackSEQQueueComp.Empty();
		AddActorDisable(this);
	}
};