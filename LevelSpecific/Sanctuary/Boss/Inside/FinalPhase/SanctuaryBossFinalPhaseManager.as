class ASanctuaryBossFinalPhaseManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryBossSlowWalkCapability");

	UPROPERTY(EditAnywhere)
	UHazeLocomotionFeatureBase Feature;

	UPROPERTY()
	TSubclassOf<ASanctuaryBossFinalPhaseMioGlowActor> MioGlowClass;

	UPROPERTY()
	TSubclassOf<ASanctuaryBossFinalPhaseMioGlowActor> MioGlowClassFullscreen;

	UPROPERTY()
	TSubclassOf<ASanctuaryBossFinalPhaseGhostSpike> GhostSpikeClass;

	UPROPERTY()
	TSubclassOf<ASanctuaryBossFinalPhaseBlackSmoke> SmokeClass;

	UPROPERTY()
	TSubclassOf<ASanctuaryBossFinalPhaseZoeLight> ZoeLightClass;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset FOVCameraSetting;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent SmokeActionQueueComp;

	UPROPERTY(EditInstanceOnly)
	AActor SmokeSourceActor;

	UPROPERTY()
	FPostProcessSettings PPSettings;

	UPROPERTY(EditAnywhere)
	float MaxDistance = 5000.0;

	UPROPERTY(EditAnywhere)
	float MinDistance = 2000.0;

	UPROPERTY(EditAnywhere)
	bool bSpawnGhosts = true;

	UPROPERTY(EditAnywhere)
	bool bSpawnSmoke = true;

	UPROPERTY(EditAnywhere)
	bool bSpawnLensFlare = true;

	UPROPERTY(EditAnywhere)
	bool bShouldSlowWalk = true;

	UPROPERTY(EditAnywhere)
	bool bZoeLight = true;

	bool bSlowWalk = false;

	ASanctuaryBossFinalPhaseMioGlowActor MioGlowActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void SetupSlowWalk()
	{
		bSlowWalk = true;
		
		if (!bShouldSlowWalk)
		{
			MaxDistance *= 1.5;
			MinDistance *= 1.5;
		}

		if (bSpawnLensFlare)
		{
			SpawnLensFlare();
		}

		if (bZoeLight)
		{
			auto SpawnedActor = SpawnActor(ZoeLightClass, Game::Zoe.ActorCenterLocation, Game::Zoe.ActorRotation);
			SpawnedActor.AttachToActor(Game::Zoe, NAME_None, EAttachmentRule::KeepWorld);
		}

		if (bSpawnGhosts)
			CalculateGhostSpikeSpawn();

		Game::Zoe.AddCustomPostProcessSettings(PPSettings, 1.0, this);
		
		if (bSpawnSmoke)
			Timer::SetTimer(this, n"SpawnSmoke", 5.0, true);
	}

	UFUNCTION()
	void SpawnLensFlare()
	{
		auto SpawnedActor = SpawnActor(MioGlowClassFullscreen, Game::Mio.ActorCenterLocation);
		SpawnedActor.AttachToActor(Game::Mio, NAME_None, EAttachmentRule::KeepWorld);
		MioGlowActor = SpawnedActor;
	}

	UFUNCTION()
	private void CalculateGhostSpikeSpawn()
	{
		auto Player = Game::Mio;
		FVector PlayerPredictedLocation = Player.ActorLocation + Player.ActorVelocity * 2.0;

		if (Game::Mio.GetDistanceTo(Game::Zoe) < MaxDistance)
		{
			SpawnGhostSpike(PlayerPredictedLocation + FVector::RightVector * Math::RandRange(-150.0, 150.0));
		}

		float Alpha = (Math::Clamp(Game::Mio.GetDistanceTo(Game::Zoe), MinDistance, MaxDistance) - MinDistance) / (MaxDistance - MinDistance);
		
		float Intensity = Math::Lerp(1.0, 4.0, Alpha);

		Timer::SetTimer(this, n"CalculateGhostSpikeSpawn", Math::RandRange(0.2, 1.0) * Intensity);
		PrintToScreen("Alpha = " + Intensity + " Distance = " + Game::Mio.GetDistanceTo(Game::Zoe), 3.0);
	}

	UFUNCTION()
	private void SpawnGhostSpike(FVector Location)
	{
		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		auto HitResult = Trace.QueryTraceSingle(Location + FVector::UpVector * 500.0, Location - FVector::UpVector * 500.0);

		if (HitResult.bBlockingHit)
			SpawnActor(GhostSpikeClass, HitResult.ImpactPoint, FRotator::MakeFromZ(HitResult.ImpactNormal));
	}

	UFUNCTION()
	void StartSpawningSmoke()
	{
		SmokeActionQueueComp.SetLooping(true);
		//SmokeActionQueueComp.Event(this, n"ChangeFOV");
		//SmokeActionQueueComp.Idle(0.3);
		SmokeActionQueueComp.Event(this, n"SpawnSmoke");
		SmokeActionQueueComp.Idle(5.0);
	}

	UFUNCTION()
	private void ChangeFOV()
	{
		for (auto Player : Game::Players)
		{
			Player.ApplyCameraSettings(FOVCameraSetting, 1.0, this, EHazeCameraPriority::VeryHigh);
		}
	}

	UFUNCTION()
	void SpawnSmoke()
	{
		for (int i = 0; i < 30; i++)
		{
			auto Smoke = SpawnActor(SmokeClass, SmokeSourceActor.ActorLocation, FRotator(Math::RandRange(-30.0, 30.0), Math::RandRange(90.0, 270.0), 0.0));
			Smoke.MioGlowActor = MioGlowActor;
		}

		for (auto Player : Game::Players)
		{
			Player.ClearCameraSettingsByInstigator(this, 0.2);
		}
	}

	UFUNCTION()
	void StopSpawningSmoke()
	{
		SmokeActionQueueComp.SetLooping(false);
	}
};