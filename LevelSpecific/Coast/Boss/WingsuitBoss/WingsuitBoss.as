struct FWingsuitBossShootAtTargetData
{
	FVector TargetLocation;
	AActor ResponseActor;
}

struct FWingsuitBossBlockWeaponsForDurationData
{
	FWingsuitBossBlockWeaponsForDurationData(FInstigator In_Instigator)
	{
		Instigator = In_Instigator;
	}

	bool opEquals(FWingsuitBossBlockWeaponsForDurationData Other) const
	{
		return Instigator == Other.Instigator;
	}

	FInstigator Instigator;
	float TimeOfBlock;
	float BlockDuration;
}

class AWingsuitBoss : AHazeActor
{
	access ReadOnly = private, * (readonly);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SecondRoot;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USphereComponent CollisionSphere;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UWingsuitBossProjectileLauncher ProjectileLauncher;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "BottomHatchAttach")
	UWingsuitBossMineLauncher MineLauncher;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UWingsuitBossTrainMissileAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UWingsuitBossMachineGunAttackCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UWingsuitBossSplineMovementCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UWingsuitBossStationKeepingMovementCapability);
	// default CapabilityComp.DefaultCapabilityClasses.Add(UWingsuitBossMineLauncherCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UWingsuitMineBlockadeLaunchCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UWingsuitBossShootAtTargetCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UWingsuitBossWeaponsActiveCapability);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedLocationComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotationComp;

	UPROPERTY(DefaultComponent)
	UTeleportResponseComponent TeleportResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeRawVelocityTrackerComponent RawVelocityTrackerComp;

	UPROPERTY(EditDefaultsOnly, Category = "Shoot At Target")
	TSubclassOf<AWingsuitBossShootAtTargetProjectile> ShootAtTargetClass;

	UPROPERTY(EditDefaultsOnly, Category = "Mines")
	TSubclassOf<AWingsuitBossMine> MineClass;

	UPROPERTY(EditDefaultsOnly, Category = "Mines")
	TSubclassOf<AWingsuitBotProjectile> AirMineClass;

	UPROPERTY(EditDefaultsOnly, Category = "Mines")
	TSubclassOf<AWingsuitBossBlockadeMine> MineBlockadeClass;

	UPROPERTY(EditDefaultsOnly, Category = "Mines")
	UNiagaraSystem MineLauncherLaunchEffect;

	UPROPERTY(EditInstanceOnly, Category = "Mines")
	TArray<AActor> MineLauncherIgnoreActors;

	UPROPERTY(EditInstanceOnly)
	AHazeActor IntroDummy;

	bool bAllowMissileAttacks = false;
	ACoastTrainCart TargetCart = nullptr;
	float RepositionTimer = 0.0;
	UHazeSplineComponent FollowingSpline;
	UWingsuitBossSettings Settings;
	float FollowSplineSpeed = 15000.0;
	bool bFollowSplineLookAtTargets = false;
	bool bHasMovedThisFrame;
	FVector PrevLocation;
	float DisableTimer = -1.0;
	FCoastBossAnimData AnimData;
	float LastMineSpawnTime = -100.0;
	access:ReadOnly bool bWeaponsActive = false;
	TInstigated<FRotator> OverrideTargetRotation;
	TInstigated<float> OverrideRotationSpringStiffness;
	TArray<FWingsuitBossShootAtTargetData> QueuedShootAtTargets;
	private TArray<FWingsuitBossBlockWeaponsForDurationData> BlockWeaponsForDurationData;
	private UHazeActorNetworkedSpawnPoolComponent AirMineSpawnPool;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		AirMineSpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(AirMineClass, this);
		AirMineSpawnPool.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnSpawnedAirMine");
		AnimData.Init(Mesh);
		Settings = UWingsuitBossSettings::GetSettings(this);
		if (IntroDummy != nullptr)
		{
			IntroDummy.AddActorVisualsBlock(this);
			AttachToActor(IntroDummy);
		}
		PrevLocation = ActorLocation;
	}

	UFUNCTION()
	void ActivateMines()
	{
		bWeaponsActive = true;
	}

	UFUNCTION()
	void DeactivateMines()
	{
		bWeaponsActive = false;
	}

	void BlockWeaponsForDuration(float Duration, FInstigator Instigator)
	{
		int Index = BlockWeaponsForDurationData.FindIndex(FWingsuitBossBlockWeaponsForDurationData(Instigator));
		if(Index == -1)
		{
			FWingsuitBossBlockWeaponsForDurationData Data;
			Data.BlockDuration = Duration;
			Data.Instigator = Instigator;
			Data.TimeOfBlock = Time::GetGameTimeSeconds();
			BlockWeaponsForDurationData.Add(Data);
			BlockCapabilities(WingsuitBossTags::WingsuitBossAttack, FInstigator(FName(Instigator.ToString() + "_BlockWeaponsForDuration")));
			return;
		}

		FWingsuitBossBlockWeaponsForDurationData& Data = BlockWeaponsForDurationData[Index];
		Data.BlockDuration = Duration;
		Data.TimeOfBlock = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	void ShootAtTarget(FVector Location, AActor OptionalResponseActor)
	{
		if(!HasControl())
			return;

		FWingsuitBossShootAtTargetData Data;
		Data.TargetLocation = Location;
		Data.ResponseActor = OptionalResponseActor;
		QueuedShootAtTargets.Add(Data);
	}

	UFUNCTION()
	void ExtendMineLauncher(FInstigator Instigator)
	{
		MineLauncher.Extend(Instigator);
	}

	UFUNCTION()
	void RetractMineLauncher(FInstigator Instigator)
	{
		MineLauncher.Retract(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool IsMineLauncherExtended() const
	{
		return MineLauncher.IsExtended();
	}

	UFUNCTION()
	void SpawnAirMine()
	{
		if(!HasControl())
			return;

		FVector Location = MineLauncher.ShootLocation;
		FRotator Rotation = MineLauncher.ShootRotation;
		FHazeActorSpawnParameters Params;
		Params.Location = Location;
		Params.Rotation = Rotation;
		Params.Spawner = this;
		AirMineSpawnPool.SpawnControl(Params);
	}

	UFUNCTION()
	private void OnSpawnedAirMine(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		if(!HasControl())
			return;

		auto Projectile = Cast<AWingsuitBotProjectile>(SpawnedActor);
		Projectile.Init(this, AirMineSpawnPool);
		UWingsuitBossEffectHandler::Trigger_OnShootAirMine(this);
	}

	void SetTurretTargetWorldLocation(FVector WorldLocation, bool bRight)
	{
		AnimData.SetTurretWorldTarget(WorldLocation, bRight ? ECoastBossBoneName::RightTurret :  ECoastBossBoneName::LeftTurret);
	}

	void ResetTurretRotation(bool bRight)
	{
		AnimData.ResetTurretRotation(bRight ? ECoastBossBoneName::RightTurret :  ECoastBossBoneName::LeftTurret);
	}

	UFUNCTION()
	void ChangeMineProjectileDamage(float NewDamageAmount)
	{
		UWingsuitBossSettings::SetProjectilePlayerDamage(this, NewDamageAmount, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bHasMovedThisFrame = false;
		if (DeltaTime > 0.0)
			ActorVelocity = (ActorLocation - PrevLocation) / DeltaTime;
		PrevLocation = ActorLocation;
		
		if (DisableTimer > 0.0)
		{
			DisableTimer -= DeltaTime;
			if (DisableTimer < SMALL_NUMBER)
				AddActorDisable(this);
		}

		for(int i = BlockWeaponsForDurationData.Num() - 1; i >= 0; i--)
		{
			FWingsuitBossBlockWeaponsForDurationData Data = BlockWeaponsForDurationData[i];
			if(Time::GetGameTimeSince(Data.TimeOfBlock) > Data.BlockDuration)
			{
				BlockWeaponsForDurationData.RemoveAt(i);
				UnblockCapabilities(WingsuitBossTags::WingsuitBossAttack, FInstigator(FName(Data.Instigator.ToString() + "_BlockWeaponsForDuration")));
			}
		}
	}

	void ReplaceIntroDummy()
	{
		RemoveActorDisable(this);
		if (IntroDummy != nullptr)
		{
			IntroDummy.AddActorVisualsBlock(this);
			IntroDummy.AddActorCollisionBlock(this);
		}
		IntroDummy = nullptr;
		DetachFromActor();
	}

	UFUNCTION()
	void FollowTrain(ACoastTrainCart Cart, bool bTeleport)
	{
		ReplaceIntroDummy();
		TargetCart = Cart;
		if(bTeleport)
		{
			SetActorLocation(Cart.ActorLocation + FVector(0, 0, 1500));
			SetActorRotation(Cart.ActorRotation + FRotator(0, 180, 0));
		}
	}	

	UFUNCTION()
	void FollowSpline(ASplineActor Spline, float Speed = 15000.0, bool bLookAtTargets = false)
	{
		ReplaceIntroDummy();
		FollowingSpline = Spline.Spline;
		FollowSplineSpeed = Speed;
		bFollowSplineLookAtTargets = bLookAtTargets;
	}	

	UFUNCTION(DevFunction)
	void StartAttackingPlayersOnTrain()
	{
		bAllowMissileAttacks = true;
	}

	UFUNCTION()
	void StopAttackingPlayersOnTrain()
	{
		bAllowMissileAttacks = false;
	}

	UFUNCTION()
	void TransitionToEndFight(float RightSpeedFactor = 1.0)
	{
		// Fly off to greener pastures while our big evil twin Coast Boss takes over for the final fight
		StopAttackingPlayersOnTrain();
		RepositionTimer = 0.0;
		float SideOffset = Math::Sign(RightSpeedFactor) * 30000.0;
		UWingsuitBossSettings::SetStationKeepingOffsetMax(this, FVector(-20000.0, 0.0, SideOffset), this);
		UWingsuitBossSettings::SetStationKeepingOffsetMin(this, FVector(-20000.0, 0.0, SideOffset), this);
		UWingsuitBossSettings::SetStationKeepingMoveSpringStiffness(this, Math::Abs(RightSpeedFactor) * 0.1, this);
		DisableTimer = 5.0;

		// Disable all projectiles
		for (AWingsuitBossProjectile Projectile : ProjectileLauncher.LaunchedProjectiles)
		{
			Projectile.bDisarmed = true;
		}
	}
}

class UWingsuitBossProjectileLauncher : UBasicAIProjectileLauncherComponent
{
	UPROPERTY(EditAnywhere, meta = (MakeEditWidget))
	TArray<FVector> LaunchLocations;
	default LaunchLocations.SetNum(4);
	default LaunchLocations[0] = FVector(563.0, -66.0, -220.0);
	default LaunchLocations[1] = FVector(-563.0, -66.0, -220.0);
	default LaunchLocations[2] = FVector(563.0, 70.0, -220.0);
	default LaunchLocations[3] = FVector(-563.0, 70.0, -220.0);

	TInstigated<float> TargetPitch; 
	TInstigated<float> PitchDuration;
	FHazeAcceleratedFloat AccPitch;

	// Note that this can contain inactive projectiles (and even projectiles spawned by other launchers, but thta should never be the case here)
	TArray<AWingsuitBossProjectile> LaunchedProjectiles;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (AttachParent == nullptr)
			return;
		TargetPitch.SetDefaultValue(AttachParent.RelativeRotation.Pitch);
		PitchDuration.SetDefaultValue(5.0);

		OnLaunchProjectile.AddUFunction(this, n"OnLaunchedProjectile");
	}

	UFUNCTION()
	private void OnLaunchedProjectile(UBasicAIProjectileComponent Projectile)
	{
		auto ProjectileActor = Cast<AWingsuitBossProjectile>(Projectile.Owner);
		if (ProjectileActor == nullptr)
			return;
		LaunchedProjectiles.AddUnique(ProjectileActor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (AttachParent == nullptr)
			return;
		AccPitch.AccelerateTo(TargetPitch.Get(), PitchDuration.Get(), DeltaTime);
		FRotator NewRot = RelativeRotation;
		NewRot.Roll = AccPitch.Value;
		AttachParent.RelativeRotation = NewRot;
	}
}