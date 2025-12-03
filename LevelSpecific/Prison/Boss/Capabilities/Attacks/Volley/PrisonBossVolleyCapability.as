class UPrisonBossVolleyCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Volley");

	default TickGroup = EHazeTickGroup::Gameplay;

	APrisonBoss Boss;
	AHazePlayerCharacter TargetPlayer;

	bool bSpawningVolley = false;
	float TimeUntilNextProjectile = 0.0;

	float TimeUntilNextVolley = 0.0;

	FPrisonBossVolleyData VolleyData;

	TArray<APrisonBossVolleyProjectile> PrimedProjectiles;

	float CurrentPrimeDuration = 0.0;

	int CurrentProjectileAmount = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APrisonBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Boss.bVolleyActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Boss.bVolleyActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetPlayer = Game::Zoe;
		bSpawningVolley = false;

		VolleyData = Boss.CurrentVolleyData;

		TimeUntilNextVolley = VolleyData.VolleyInterval;
		TimeUntilNextProjectile = VolleyData.ProjectileInterval;

		CurrentPrimeDuration = 0.0;
		CurrentProjectileAmount = 0;

		PrimedProjectiles.Empty();

		UPrisonBossEffectEventHandler::Trigger_VolleyEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.bVolleyActive = false;

		DissipateActiveProjectiles();

		UPrisonBossEffectEventHandler::Trigger_VolleyExit(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		VolleyData = Boss.CurrentVolleyData;

		if (bSpawningVolley)
		{
			CurrentPrimeDuration += DeltaTime;
			if (CurrentPrimeDuration >= PrisonBoss::VolleyPrimeDuration)
			{
				TimeUntilNextProjectile += DeltaTime;
				if (TimeUntilNextProjectile >= VolleyData.ProjectileInterval)
					LaunchProjectile();
			}
		}
		else
		{
			TimeUntilNextVolley += DeltaTime;
			if (TimeUntilNextVolley >= VolleyData.VolleyInterval)
				SpawnVolley();
		}
	}

	void SpawnVolley()
	{
		CurrentPrimeDuration = 0.0;
		TimeUntilNextVolley = 0.0;
		bSpawningVolley = true;

		CurrentProjectileAmount = Boss.bHacked ? VolleyData.ProjectilesPerVolley : VolleyData.ProjectilesPerVolley * 2;
		CurrentProjectileAmount += 1;

		bool bBigOffset = true;
		for (int i = 0; i < CurrentProjectileAmount; i++)
		{
			FVector SpawnLoc = Boss.Mesh.GetSocketLocation(n"Backpack");
			FVector SpawnDir = Boss.ActorRightVector;
			if (Boss.bHacked)
				SpawnDir = SpawnDir.RotateAngleAxis(30.0, Boss.ActorForwardVector);
			float Angle = Boss.bHacked ? 240.0/(VolleyData.ProjectilesPerVolley * 2) : 180.0/(VolleyData.ProjectilesPerVolley * 2.0);
			SpawnDir = SpawnDir.RotateAngleAxis(Angle * i, Boss.ActorForwardVector);
			float SpawnLength = bBigOffset ? PrisonBoss::VolleyPrimeMaxOffset : PrisonBoss::VolleyPrimeMinOffset;
			SpawnLoc += SpawnDir * SpawnLength;
			FVector RelativeSpawnLoc = Boss.ActorTransform.InverseTransformPosition(SpawnLoc);
			APrisonBossVolleyProjectile Projectile = SpawnActor(Boss.AttackDataComp.VolleyClass, Boss.Mesh.GetSocketLocation(n"Backpack"));
			Projectile.AttachToActor(Boss, NAME_None, EAttachmentRule::KeepWorld);
			Projectile.Boss = Boss;
			
			float Delay = Math::CeilToFloat(i) * 0.05;
			Projectile.Prime(RelativeSpawnLoc, Delay, Boss.IsHacked());
			PrimedProjectiles.Add(Projectile);
			bBigOffset = !bBigOffset;
		}

		UPrisonBossEffectEventHandler::Trigger_SpawnVolley(Boss, FPrisonBossVolleySpawnData(PrimedProjectiles));
	}

	void LaunchProjectile()
	{
		TimeUntilNextProjectile = 0.0;

		if (!Boss.bHacked)
			TargetPlayer = TargetPlayer.OtherPlayer;

		FVector TargetLoc = TargetPlayer.ActorLocation;
		float PlayerSpeedModifier = Math::GetMappedRangeValueClamped(FVector2D(0.0, 500.0), FVector2D(0.0, 1.0), TargetPlayer.ActorHorizontalVelocity.Size());
		TargetLoc += Math::GetRandomPointInCircle_XY().GetSafeNormal() * Math::RandRange(50.0 * PlayerSpeedModifier, 150 + (100.0 * PlayerSpeedModifier));

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.UseLine();

		FVector TraceStart = TargetLoc + (FVector::UpVector * 800.0);
		FHitResult Hit = Trace.QueryTraceSingle(TraceStart, TraceStart - (FVector::UpVector * 2000.0));
		FVector HitLocation = Hit.ImpactPoint;

		if (TargetPlayer.IsAnyCapabilityActive(n"RemoteHackingActive"))
			HitLocation = FVector::ZeroVector;

		PrimedProjectiles[0].Shoot(HitLocation, Hit.ImpactNormal);
		PrimedProjectiles.RemoveAt(0);

		if (PrimedProjectiles.Num() == 0)
		{
			bSpawningVolley = false;
			PrimedProjectiles.Empty();
		}
	}

	void DissipateActiveProjectiles()
	{
		TArray<APrisonBossVolleyProjectile> Projectiles = TListedActors<APrisonBossVolleyProjectile>().Array;
		for (APrisonBossVolleyProjectile Projectile : Projectiles)
		{
			Projectile.Dissipate();
		}
	}
}

struct FPrisonBossVolleyData
{
	UPROPERTY()
	int ProjectilesPerVolley = 8;

	UPROPERTY()
	float ProjectileInterval = 0.1;

	UPROPERTY()
	float VolleyInterval = 2.0;
}

struct FPrisonBossVolleyImpactData
{
	UPROPERTY()
	FVector ImpactLocation;

	FPrisonBossVolleyImpactData(const FVector InImpactLocation)
	{
		ImpactLocation = InImpactLocation;
	}
}

struct FPrisonBossVolleySpawnData
{
	UPROPERTY()
	TArray<APrisonBossVolleyProjectile> Projectiles;

	FPrisonBossVolleySpawnData(const TArray<APrisonBossVolleyProjectile> InProjectiles)
	{
		Projectiles = InProjectiles;
	}
}