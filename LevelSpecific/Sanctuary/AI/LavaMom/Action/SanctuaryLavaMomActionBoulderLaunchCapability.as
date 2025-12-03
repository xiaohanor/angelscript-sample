struct FSanctuaryLavaMomActionBoulderData
{
	FSanctuaryLavaMomBoulderPatternData PatternData;
}

class USanctuaryLavaMomActionBoulderLaunchCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	FSanctuaryLavaMomActionBoulderData Params;
	default CapabilityTags.Add(LavaMomTags::LavaMom);
	default CapabilityTags.Add(LavaMomTags::Action);

	USanctuaryLavaMomActionsComponent ActionComp;
	USanctuaryLavaMomMultiBoulderLauncherComponent MultiBoulderLauncher;

	TArray<FSanctuaryLavaMomMultiProjectileBoulderData> Projectiles;

	ASanctuaryLavaMom LavaMom;

	UBasicAIProjectileComponent LastProjectile;
	USanctuaryLavaMomSettings Settings;

	AActor Mio;
	AActor Zoe;

	float LastActiveDuration = 0.0;
	FVector ActivatedTowardsCentipedeDirection;

	float TimeSinceLastProjectile = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LavaMom = Cast<ASanctuaryLavaMom>(Owner);
		ActionComp = USanctuaryLavaMomActionsComponent::GetOrCreate(Owner);
		MultiBoulderLauncher = LavaMom.MultiBoulderLauncher;
		Settings = USanctuaryLavaMomSettings::GetSettings(Owner);
		Mio = Game::GetMio();
		Zoe = Game::GetZoe();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryLavaMomActionBoulderData& ActivationParams) const
	{
		// CONTROL ONLY CAPABILITY
		if (!HasControl())
			return false;

		// Don't activate if player isn't centipede yet
		UPlayerCentipedeComponent ControlPlayerCentipedeComponent = UPlayerCentipedeComponent::Get(GetControlPlayer());
		if (ControlPlayerCentipedeComponent == nullptr)
			return false;

		if (!ControlPlayerCentipedeComponent.IsCentipedeActive())
			return false;

		if (!ActionComp.ActionQueue.Start(this, ActivationParams))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		UPlayerCentipedeComponent ControlPlayerCentipedeComponent = UPlayerCentipedeComponent::Get(GetControlPlayer());
		if (ControlPlayerCentipedeComponent == nullptr)
			return true;

		if (!ControlPlayerCentipedeComponent.IsCentipedeActive())
			return true;

		if (!ActionComp.ActionQueue.IsActive(this))
			return true;

		if (HasLaunchedAllProjectiles() && TimeSinceLastProjectile > 3.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryLavaMomActionBoulderData ActivationParams)
	{
		Params = ActivationParams;
		FBasicAIAnimationActionDurations Durations;
		Durations.Telegraph = 0.1;
		Durations.Anticipation = 0.1;
		Durations.Action = 0.1;
		Durations.Recovery = 0.1;

		TArray<FSanctuaryLavaMomBoulderCreationData> TempSpawnData;
		GetShootDataFromPattern(TempSpawnData, Params.PatternData);
		CrumbAddProjectiles(TempSpawnData, Params.PatternData.bBigBoulder);

		TArray<FVector> Locations = GetTailLocations();
		FVector AttackLocation;
		for(FVector Location: Locations)
			AttackLocation += Location;
		AttackLocation = AttackLocation / Locations.Num();
		ActivatedTowardsCentipedeDirection = (AttackLocation - MultiBoulderLauncher.LaunchLocation).GetSafeNormal();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbAddProjectiles(TArray<FSanctuaryLavaMomBoulderCreationData> CreationsDatas, bool bBigBoulder)
	{
		for (int iData = 0; iData < CreationsDatas.Num(); ++iData) 
		{
			const FSanctuaryLavaMomBoulderCreationData& SpawnData = CreationsDatas[iData];
			FSanctuaryLavaMomMultiProjectileBoulderData ProjectileData;
			ProjectileData.SpawnData = SpawnData;
			ProjectileData.SpawnData.bBigBoulder = bBigBoulder;
			Projectiles.Add(ProjectileData);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ActionComp.ActionQueue.Finish(this);
		CrumbExpireUnlaunched();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TimeSinceLastProjectile += DeltaTime;
		for (int i = 0; i < Projectiles.Num(); ++i) 
		{
			FSanctuaryLavaMomMultiProjectileBoulderData& ProjectileData = Projectiles[i];
			if (!ProjectileData.bPrimed && ProjectileData.SpawnData.SpawnDelay >= LastActiveDuration && ProjectileData.SpawnData.SpawnDelay <= ActiveDuration)
				CrumbPrimeProjectile(i);

			if (!ProjectileData.bPrimed)
				continue;

			float ProjectileActiveDuration = ActiveDuration - ProjectileData.PrimeTimeStamp;
			if(!ProjectileData.bLaunched && ProjectileActiveDuration > 0.1)
				Launch(i, ProjectileData);
		}

		LastActiveDuration = ActiveDuration;
	}

	private void Launch(int Index, FSanctuaryLavaMomMultiProjectileBoulderData& ProjectileData)
	{
		FVector StartDirection = MultiBoulderLauncher.ForwardVector;
		if (ProjectileData.SpawnData.AngleSpace == ESanctuaryLavaMomBoulderAngleSpace::TowardsCentipedeMiddle)
			StartDirection = ActivatedTowardsCentipedeDirection;
		else if (ProjectileData.SpawnData.AngleSpace == ESanctuaryLavaMomBoulderAngleSpace::WorldSpace)
			StartDirection = FVector::ForwardVector;

		if (!Math::IsNearlyEqual(ProjectileData.SpawnData.Angle, 0.0))
			StartDirection = FRotator::MakeFromEuler(FVector(0.0, 0.0, ProjectileData.SpawnData.Angle)).RotateVector(StartDirection);

		CrumbLaunch(Index, StartDirection);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPrimeProjectile(int Index)
	{
		FSanctuaryLavaMomMultiProjectileBoulderData& ProjectileData = Projectiles[Index];
		ProjectileData.bPrimed = true;
		ProjectileData.PrimeTimeStamp = ActiveDuration;
		ProjectileData.Projectile = MultiBoulderLauncher.Prime();
		ProjectileData.ProjectileActor = Cast<ASanctuaryLavaMomBoulderProjectile>(ProjectileData.Projectile.Owner);
		ProjectileData.ProjectileActor.Owner = Owner;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLaunch(int Index, FVector StartDirection)
	{
		TimeSinceLastProjectile = 0.0;
		FSanctuaryLavaMomMultiProjectileBoulderData& ProjectileData = Projectiles[Index];
		ProjectileData.bLaunched = true;
		FVector TargetLocation = MultiBoulderLauncher.LaunchLocation + StartDirection * 300.0;
		ProjectileData.ProjectileActor.bBigBoulder = ProjectileData.SpawnData.bBigBoulder;
		ProjectileData.ProjectileActor.AttackLocation = TargetLocation;
		ProjectileData.ProjectileActor.GroundSpeed = Settings.BoulderProjectileSpeed;
		FVector UpwardsLaunch = FVector::UpVector * Settings.BoulderProjectileSpeed * 2.0;
		MultiBoulderLauncher.Launch(StartDirection * 1.4 * Settings.BoulderProjectileSpeed + UpwardsLaunch);
		ProjectileData.Projectile.Friction = 0;
		ProjectileData.Projectile.UpVector = -Owner.ActorRightVector;
		ProjectileData.Projectile.Gravity = ProjectileData.SpawnData.CurveToRight;
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(MultiBoulderLauncher, 1, 1));
	}

	UFUNCTION(CrumbFunction)
	private void CrumbExpireUnlaunched()
	{
		for (FSanctuaryLavaMomMultiProjectileBoulderData& ProjectileData : Projectiles) 
		{
			if(ProjectileData.Projectile != nullptr && !ProjectileData.Projectile.bIsLaunched)
				ProjectileData.Projectile.Expire();
		}
		Projectiles.Empty();
	}

	private bool HasLaunchedAllProjectiles() const
	{
		for (const FSanctuaryLavaMomMultiProjectileBoulderData& ProjectileData : Projectiles) 
		{
			if (!ProjectileData.bLaunched)
				return false;
		}
		return true;
	}

	private TArray<FVector> GetTailLocations() const
	{
		TArray<FVector> Locations;
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(Mio);
		if(ensure(CentipedeComp != nullptr, "Player isn't a centipede!"))
			Locations = CentipedeComp.GetBodyLocations();
		return Locations;
	}

	// ------------------ SHOOT PATTERN UTILS
	private void GetShootDataFromPattern(TArray<FSanctuaryLavaMomBoulderCreationData>& OutData, const FSanctuaryLavaMomBoulderPatternData& PatternData)
	{
		OutData.Empty();
		if (PatternData.Amount == 0)
			return;

		if (PatternData.Amount == 1)
		{
			OutData.Add(FSanctuaryLavaMomBoulderCreationData(PatternData.Delay));
		}
		else 
		{
			switch (PatternData.PatternType)
			{
				case ESanctuaryLavaMomBoulderPattern::Arrow:
					CreateArrowShot(OutData, PatternData.Amount, PatternData.Delay, PatternData.AngleSpread, false);
					break;
				case ESanctuaryLavaMomBoulderPattern::V:
					CreateArrowShot(OutData, PatternData.Amount, PatternData.Delay, PatternData.AngleSpread, true);
					break;
				case ESanctuaryLavaMomBoulderPattern::SpiralShot:
					CreateSpiralShot(OutData, PatternData.Amount, PatternData.Delay, PatternData.AngleSpread);
					break;
				case ESanctuaryLavaMomBoulderPattern::AntiSpiralShot:
					CreateSpiralShot(OutData, PatternData.Amount, PatternData.Delay, -PatternData.AngleSpread);
					break;
				case ESanctuaryLavaMomBoulderPattern::Cross:
				{
					int CrossWaves = Math::IntegerDivisionTrunc(PatternData.Amount, 4);
					for (int i = 0; i < CrossWaves; ++i)
						CreateCircleShot(OutData, 4, i * PatternData.Delay, 360.0);
					break;
				}
				case ESanctuaryLavaMomBoulderPattern::Circle:
					CreateCircleShot(OutData, PatternData.Amount, PatternData.Delay, 360.0);
					break;
				default: // single shot
				{
	#if EDITOR
					PrintToScreen("Lava Mole Pattern not found! Defaulting to single", 1.0, FLinearColor::Red);
	#endif
					OutData.Add(FSanctuaryLavaMomBoulderCreationData(PatternData.Delay));
				}
			}
		}

		for (FSanctuaryLavaMomBoulderCreationData& CreationData : OutData)
		{
			CreationData.AngleSpace = PatternData.AngleSpace;
			CreationData.CurveToRight = PatternData.CurveToRight;
			CreationData.Angle += PatternData.AngleOffset;
		}
	}

	private void CreateArrowShot(TArray<FSanctuaryLavaMomBoulderCreationData>& OutData, int Amount, float Delay, float TotalAngle, bool bIsVShape)
	{
		const float AngleStep = TotalAngle / (Amount -1);
		const float HalfCone = TotalAngle / 2;
		const int HalfAmount = Math::IntegerDivisionTrunc(Amount, 2);
		bool bHasEvenNumberOfShots = Amount % 2 == 0;
		for (int i = 0; i < Amount; ++i)
		{
			const float CurrentAngle = (AngleStep * i) - HalfCone;
			int ShapeDelayUnAbsed = i - HalfAmount;
			int ShapeDelay = Math::Abs(ShapeDelayUnAbsed);
			if (bHasEvenNumberOfShots && i < HalfAmount)
				ShapeDelay -= 1;
			if (bIsVShape)
				ShapeDelay = HalfAmount - ShapeDelay;

			OutData.Add(FSanctuaryLavaMomBoulderCreationData(ShapeDelay * Delay, CurrentAngle));
		}
	}

	private void CreateSpiralShot(TArray<FSanctuaryLavaMomBoulderCreationData>& OutData, int Amount, float Delay, float TotalAngle)
	{
		const float AngleStep = TotalAngle / (Amount -1);
		for (int i = 0; i < Amount; ++i)
			OutData.Add(FSanctuaryLavaMomBoulderCreationData(Delay * i, AngleStep * i));
	}

	private void CreateCircleShot(TArray<FSanctuaryLavaMomBoulderCreationData>& OutData, int Amount, float Delay, float TotalAngle, bool bDelayEven = false)
	{
		const float AngleStep = TotalAngle / Amount;
		for (int i = 0; i < Amount; ++i)
		{
			int DelayEven = 0;
			if (bDelayEven)
				DelayEven = i % 2;
			OutData.Add(FSanctuaryLavaMomBoulderCreationData(DelayEven * Delay, AngleStep * i));
		}
	}

	AHazePlayerCharacter GetControlPlayer() const
	{
		if (Game::Mio.HasControl())
			return Game::Mio;

		return Game::Zoe;
	}
}
