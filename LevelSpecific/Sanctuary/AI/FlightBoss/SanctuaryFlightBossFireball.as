class USanctuaryFlightBossFireballSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Fireball")
	float ScaleTarget = 10.0;

	UPROPERTY(Category = "Fireball")
	float ScaleDuration = 10.0;

	UPROPERTY(Category = "Fireball")
	float LaunchInterval = 3.0;

	UPROPERTY(Category = "Fireball")
	float LaunchSpeed = 20000.0;

	UPROPERTY(Category = "Fireball")
	int SalvoSize = 3;

	UPROPERTY(Category = "Fireball")
	float SalvoInterval = 0.2;

	UPROPERTY(Category = "Fireball")
	float ExplodeRange = 23000.0;

	UPROPERTY(Category = "Fireball")
	float HomingStrength = 10.0;

	// Switch target after this number of salvos
	UPROPERTY(Category = "Fireball")
	float SwitchTargetCount = 3;

	// Pause for this many seconds when switching target
	UPROPERTY(Category = "Fireball")
	float SwitchTargetPauseDuration = 2.0;
}

class USanctuaryFireBallLauncherComponent : UBasicAIProjectileLauncherComponent
{
	USanctuaryFlightBossFireballSettings Settings;

	void SetWielder(AHazeActor NewWielder) override
	{
		Super::SetWielder(NewWielder);
		UpdateSettings();
	}

	void UpdateSettings()
	{
		if (Settings == nullptr)
			Settings = 	USanctuaryFlightBossFireballSettings::GetSettings(Wielder);	

		LaunchInterval = Settings.LaunchInterval;
		LaunchSpeed = Settings.LaunchSpeed;
	}

	UBasicAIProjectileComponent Prime() override
	{
		UpdateSettings();
		return Super::Prime();
	}
	
	UBasicAIProjectileComponent Launch(FVector Velocity) override
	{
		UpdateSettings();
		return Super::Launch(Velocity);
	}
}

class ASanctuaryFlighBossFireball : ABasicAIProjectile
{
	default ExpirationTime = 10.0;

	UPROPERTY(DefaultComponent)
	UBasicAIHomingProjectileComponent HomingComp;

	FVector StartScale;
	FHazeAcceleratedVector CurrentScale;
	USanctuaryFlightBossFireballSettings Settings;
	FVector LaunchLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
		StartScale = ActorScale3D;
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
		Reset();
	}

	UFUNCTION(NotBlueprintCallable)
	private void Reset()
	{
		ActorScale3D = StartScale;
		CurrentScale.SnapTo(StartScale);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		LaunchLoc = ActorLocation;
	}

	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		if (Settings == nullptr)
			Settings = USanctuaryFlightBossFireballSettings::GetSettings(ProjectileComp.Launcher);

		// Homing acceleration towards target, perpendicular to current velocity
		float FlightDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		ProjectileComp.Velocity += HomingComp.GetPlanarHomingAcceleration(HomingComp.Target.ActorCenterLocation, ProjectileComp.Velocity.GetSafeNormal(), Settings.HomingStrength * FlightDuration) * DeltaTime;	

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		if (Hit.bBlockingHit)
			ProjectileComp.Impact(Hit);

 		ActorScale3D = CurrentScale.AccelerateTo(StartScale * Settings.ScaleTarget, Settings.ScaleDuration, DeltaTime);	
		
		if (!ActorLocation.IsWithinDist(LaunchLoc, Settings.ExplodeRange))
			ProjectileComp.Impact(FHitResult());
	}
}
