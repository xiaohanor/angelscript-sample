event void FAllMolesDeadSignature();
event void FOnSpawnMoleSignature(AAISanctuaryLavamole Mole);
event void FOnMoleDiedSignature(AAISanctuaryLavamole Mole);

class AMoleCombatManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY()
	TSubclassOf<AAISanctuaryLavamole> MoleClass;
	
	UPROPERTY()
	FAllMolesDeadSignature OnAllMolesDead;

	UPROPERTY()
	FOnSpawnMoleSignature OnSpawnMole;

	UPROPERTY()
	FOnMoleDiedSignature OnMoleDied;

	UPROPERTY(EditAnywhere)
	TArray<FSanctuaryLavamoleBoulderPatternData> ShootPatterns;

	UPROPERTY(EditAnywhere)
	FSanctuaryLavamoleBoulderPatternData ShootPatter1;

	UPROPERTY(EditAnywhere)
	FSanctuaryLavamoleBoulderPatternData ShootPatter2;

	UPROPERTY(EditAnywhere)
	FSanctuaryLavamoleBoulderPatternData ShootPatter3;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASanctuaryLavamoleMortarProjectilePool> LavaPoolClass;
	FHazeActorSpawnParameters LavaPoolSpawnParams;
	UHazeActorLocalSpawnPoolComponent LavaPoolSpawnPool; // moon moon lol
	TArray<ASanctuaryLavamoleMortarProjectilePool> LavaPools;

	UPROPERTY(EditInstanceOnly)
	TArray<ASanctuaryLavamoleWhackSplitBody> SplitWormHeads;

	TArray<AAISanctuaryLavamole> Moles;

	UPROPERTY(DefaultComponent)
	USanctuaryMoleCombatHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	UPROPERTY(EditInstanceOnly)
	ADraggableGateActor Gate;

	int DeadMoles = 0;
	int SpawnedMoles = 0;
	int TotalSpawnedMoles = 0;
	int Wave2Moles = 4;

	bool bSpawnNextWave = false;
	float SpawnNextWaveTimer = 1.5;
	float GeyserTimer = 1.5;

	bool bAggressive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// HealthBarComp.SetHealthBarEnabled(false);
		// HealthBarComp.UpdateHealthBarVisibility();

		if (LavaPoolClass != nullptr)
		{
			LavaPoolSpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(LavaPoolClass, this);
		}
		SanctuaryCentipedeDevToggles::Mole::NoMoleMortarPools.MakeVisible();
		SanctuaryCentipedeDevToggles::Mole::MoleGeysers.MakeVisible();

		if (Gate != nullptr)
		{
			Gate.UpdateChainImpossibility(true);
			Gate.OnGateInteractionStarted.AddUFunction(this,  n"StartAggressive");
			Gate.OnGateInteractionStopped.AddUFunction(this, n"StopAggressive");
		}
	}

	UFUNCTION()
	private void StartAggressive()
	{
		bAggressive = true;
	}

	UFUNCTION()
	private void StopAggressive()
	{
		bAggressive = false;
	}

	int GetTotalMolesForHealthBar()
	{
		return Wave2Moles + 1;
	}

	UFUNCTION()
	void SpawnWave1()
	{
		USanctuaryUglyProgressionPlayerComponent UglyComp = USanctuaryUglyProgressionPlayerComponent::GetOrCreate(Game::Mio);
		if (UglyComp.bPassedMoleGateCheckpoint)
			return;
		// please edit GetNumMoleFamilyMembers if you change
		bAggressive = true;
		SpawnMole(ESanctuaryLavamoleMortarTargetingStrategy::MiddleArea, 3);
	}

	UFUNCTION()
	void SpawnWave1FromCheckpoint()
	{
		// please edit GetNumMoleFamilyMembers if you change
		SpawnMole(ESanctuaryLavamoleMortarTargetingStrategy::MiddleArea, 3);
	}

	void SpawnWave2()
	{
		for (int i = 0; i < Wave2Moles; ++i)
		{
			ActionQueueComp.Event(this, n"CallbackSpawnMole");
			ActionQueueComp.Idle(0.5);
		}
		// No health bar by current design!
		// 
		if (SanctuaryCentipedeDevToggles::Mole::MoleBigHealthBar.IsEnabled())
		{
			UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::AlwaysShow, this);
			HealthComp.SpawnHealthBar();
		}
	}

	UFUNCTION()
	private void CallbackSpawnMole()
	{
		SpawnMole(ESanctuaryLavamoleMortarTargetingStrategy::MiddleArea, 2);
	}

	private void SpawnMole(ESanctuaryLavamoleMortarTargetingStrategy MortarStrategy, int NumMortarsToShoot)
	{
		if (HasControl())
			CrumbSpawnMole(MortarStrategy, NumMortarsToShoot);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawnMole(ESanctuaryLavamoleMortarTargetingStrategy MortarStrategy, int NumMortarsToShoot)
	{
		AAISanctuaryLavamole Mole = SpawnActor(MoleClass, ActorLocation, FRotator::ZeroRotator, NAME_None, true, this.Level);
		Mole.MakeNetworked(this, TotalSpawnedMoles);
		Mole.Manager = this;
		Mole.bIsAggressive = bAggressive;
		TotalSpawnedMoles++;
		FinishSpawningActor(Mole);
		// Mole.ShootComp.AssignShootPattern(ShootPatter1);
		Mole.MortarTargetingStrategy = MortarStrategy;
		Mole.NumMortarsToShoot = NumMortarsToShoot;
		Mole.OnMoleStartedDying.AddUFunction(this, n"HandleMoleDied");
		Moles.Add(Mole);

		if (Gate != nullptr)
		{
			Gate.OnGateInteractionStarted.AddUFunction(Mole, n"StartAggressive");
			Gate.OnGateInteractionStopped.AddUFunction(Mole, n"StopAggressive");
		}

		++SpawnedMoles;
		OnSpawnMole.Broadcast(Mole);
	}
	
	UFUNCTION()
	private void HandleMoleDied(AAISanctuaryLavamole DeadMole)
	{
		DeadMoles++;
		Moles.Remove(DeadMole);

		OnMoleDied.Broadcast(DeadMole);

		if (Gate != nullptr)
		{
			Gate.OnGateInteractionStarted.UnbindObject(DeadMole);
			Gate.OnGateInteractionStopped.UnbindObject(DeadMole);
		}

		if (DeadMoles == 1)
		{
			bSpawnNextWave = true;
		}
		else
		{
			if (SanctuaryCentipedeDevToggles::Mole::MoleBigHealthBar.IsEnabled())
			{
				HealthComp.TakeDamage(HealthComp.MaxHealth / Wave2Moles);	
			}
			
			if (DeadMoles >= SpawnedMoles)
			{
				// FIGHT OVER
				for (auto LavaPool : LavaPools)
					LavaPool.FightIsOver();
				if (SanctuaryCentipedeDevToggles::Mole::MoleBigHealthBar.IsEnabled())
				{
					HealthComp.TakeDamage(HealthComp.MaxHealth + 1.0); // safe guard against any floating point errorz
				}

				OnAllMolesDead.Broadcast();
				if (Gate != nullptr)
					Gate.UpdateChainImpossibility(false);
			}

			if (DeadMoles == 2)
			{
				for (auto Mole : Moles)
					Mole.NumMortarsToShoot = 3;
			}

			if (DeadMoles == 3)
			{
				for (auto Mole : Moles)
					Mole.NumMortarsToShoot = 5;
			}

			if (DeadMoles == 4)
			{
				for (auto Mole : Moles)
				{
					Mole.NumMortarsToShoot = 10;
				}
			}
		}

		if (SanctuaryCentipedeDevToggles::Mole::MoleBigHealthBar.IsEnabled() && DeadMoles >= GetTotalMolesForHealthBar())
		{
			HealthComp.RemoveHealthBar();
		}
	}

	void StartListen(ASanctuaryLavamoleMortarProjectile Projectile)
	{
		Projectile.OnWantsSpawnPool.AddUFunction(this, n"SpawnLavaPool");
		Projectile.RespawnComp.OnUnspawn.AddUFunction(this, n"StopListen");
	}

	UFUNCTION()
	private void SpawnLavaPool(FVector Location, FRotator Rotation)
	{
		if (HasControl())
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WorldGeometry);
			Trace.UseLine();
			auto Hit = Trace.QueryTraceSingle(Location, Location - FVector::UpVector * 200.0);
			CrumbSpawnLavaPool(Hit.Location, FQuat(Rotation.UpVector, Math::RandRange(-PI, PI)).Rotator());
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawnLavaPool(FVector Location, FRotator Rotation)
	{
		// TSubclassOf<ASanctuaryLavamoleMortarProjectilePool> LavaPoolClass;
		// FHazeActorSpawnParameters LavaPoolSpawnParams;
		// UHazeActorLocalSpawnPoolComponent LavaPoolSpawnPool; // m
		if (LavaPoolClass != nullptr)
		{
			LavaPoolSpawnParams.Spawner = this;
			LavaPoolSpawnParams.Location = Location;
			LavaPoolSpawnParams.Rotation = Rotation;
			ASanctuaryLavamoleMortarProjectilePool LavaPool = Cast<ASanctuaryLavamoleMortarProjectilePool>(LavaPoolSpawnPool.Spawn(LavaPoolSpawnParams));
			LavaPool.RemoveActorDisable(this);
			LavaPool.Reset();
			UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(LavaPool);
			RespawnComp.OnSpawned(this, LavaPoolSpawnParams);
			RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedLavapool");
#if EDITOR
			LavaPools.AddUnique(LavaPool);
#endif
		}
	}

	UFUNCTION()
	private void OnUnspawnedLavapool(AHazeActor Pool)
	{
		ASanctuaryLavamoleMortarProjectilePool LavaPool = Cast<ASanctuaryLavamoleMortarProjectilePool>(Pool);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(LavaPool);
		RespawnComp.OnUnspawn.Unbind(this, n"OnUnspawnedLavapool");
		LavaPool.AliveDuration = 0.0;
		LavaPool.AddActorDisable(this);
		LavaPoolSpawnPool.UnSpawn(LavaPool);
	}

	UFUNCTION()
	private void StopListen(AHazeActor RespawnableActor)
	{
		ASanctuaryLavamoleMortarProjectile Projectile = Cast<ASanctuaryLavamoleMortarProjectile>(RespawnableActor);
		Projectile.OnWantsSpawnPool.UnbindObject(this);
		Projectile.RespawnComp.OnUnspawn.UnbindObject(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!HasControl())
			return;

		if (bSpawnNextWave)
		{
			SpawnNextWaveTimer -= DeltaSeconds;
			if (SpawnNextWaveTimer < 0.0)
			{
				bSpawnNextWave = false;
				SpawnWave2();
			}
		}
		
		if (SanctuaryCentipedeDevToggles::Mole::MoleGeysers.IsEnabled())
		{
			GeyserTimer -= DeltaSeconds;
			if (GeyserTimer < 0.0)
			{
				GeyserTimer = Math::RandRange(3.0, 3.0);
				SelectGeyser();
			}
		}
	}

	private void SelectGeyser()
	{
		auto Team = HazeTeam::GetTeam(SanctuaryLavamoleTags::DigPointTeam);
		if (Team != nullptr)
		{
			TArray<AHazeActor> Members = Team.GetMembers();
			TArray<ASanctuaryLavamoleDigPoint> FreeDigPoints;
			for (int iMember = 0; iMember < Members.Num(); ++iMember)
			{
				ASanctuaryLavamoleDigPoint DigPoint = Cast<ASanctuaryLavamoleDigPoint>(Members[iMember]);
				if (DigPoint != nullptr && !DigPoint.HasOccupant() && DigPoint.Geyser != nullptr)
				{
					FreeDigPoints.Add(DigPoint);
				}
			}
			if (FreeDigPoints.Num() == 1)
			{
				CrumbGeyser(FreeDigPoints[0].Geyser);
			}
			else if (FreeDigPoints.Num() > 0)
			{
				ASanctuaryLavamoleGeyser ChosenGeyser = FreeDigPoints[Math::RandRange(0, FreeDigPoints.Num() -1)].Geyser;
				CrumbGeyser(ChosenGeyser);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbGeyser(ASanctuaryLavamoleGeyser Geyser)
	{
		Geyser.StartGeyser();
	}

	ASanctuaryLavamoleWhackSplitBody EnableFunnyDeadHead(FVector Location, FRotator Rotation, FVector Impulse)
	{
		for (ASanctuaryLavamoleWhackSplitBody DeadHead : SplitWormHeads)
		{
			if (DeadHead.bTaken)
				continue;
			DeadHead.EnableHead(Location, Rotation, Impulse);
			return DeadHead;
		}
		return nullptr;
	}
};