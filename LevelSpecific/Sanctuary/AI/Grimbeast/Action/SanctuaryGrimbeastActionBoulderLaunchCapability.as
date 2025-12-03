struct FSanctuaryGrimbeastActionBoulderData
{
	FSanctuaryGrimbeastBoulderPatternData PatternData;
}

class USanctuaryGrimbeastActionBoulderLaunchCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FSanctuaryGrimbeastActionBoulderData Params;
	default CapabilityTags.Add(GrimbeastTags::Grimbeast);
	default CapabilityTags.Add(GrimbeastTags::Action);

	USanctuaryGrimbeastActionsComponent ActionComp;
	USanctuaryGrimbeastMultiBoulderLauncherComponent MultiBoulderLauncher;

	TArray<FSanctuaryGrimbeastMultiProjectileBoulderData> Projectiles;

	AAISanctuaryGrimbeast Grimbeast;

	UBasicAIProjectileComponent LastProjectile;
	USanctuaryGrimbeastSettings Settings;
	UBasicAIAnimationComponent AnimComp;

	AActor Mio;
	AActor Zoe;

	float LastActiveDuration = 0.0;
	FVector ActivatedTowardsCentipedeDirection;

	bool bAllScalingDone = false;
	float AttackAnimElapsed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Grimbeast = Cast<AAISanctuaryGrimbeast>(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		ActionComp = USanctuaryGrimbeastActionsComponent::GetOrCreate(Owner);
		MultiBoulderLauncher = Grimbeast.MultiBoulderLauncher;
		Settings = USanctuaryGrimbeastSettings::GetSettings(Owner);
		Mio = Game::GetMio();
		Zoe = Game::GetZoe();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryGrimbeastActionBoulderData& ActivationParams) const
	{
		// Don't activate if player isn't centipede yet
		UPlayerCentipedeComponent ControlPlayerCentipedeComponent = UPlayerCentipedeComponent::Get(GetControlPlayer());
		if (ControlPlayerCentipedeComponent == nullptr)
			return false;

		if (!ControlPlayerCentipedeComponent.IsCentipedeActive())
			return false;

		if (!ActionComp.ActionQueue.Start(this, ActivationParams))
			return false;

		if (!HasControl())
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

		if (HasLaunchedAllProjectiles() && bAllScalingDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryGrimbeastActionBoulderData ActivationParams)
	{
		Params = ActivationParams;
		FBasicAIAnimationActionDurations Durations;
		Durations.Telegraph = 0.1;
		Durations.Anticipation = 0.1;
		Durations.Action = 0.1;
		Durations.Recovery = 0.1;

		TArray<FSanctuaryGrimbeastBoulderCreationData> TempSpawnData;
		GetShootDataFromPattern(TempSpawnData, Params.PatternData);
		for (const FSanctuaryGrimbeastBoulderCreationData& SpawnData : TempSpawnData) 
		{
			FSanctuaryGrimbeastMultiProjectileBoulderData ProjectileData;
			ProjectileData.SpawnData = SpawnData;
			Projectiles.Add(ProjectileData);
		}

		TArray<FVector> Locations = GetTailLocations();
		FVector AttackLocation;
		for(FVector Location: Locations)
			AttackLocation += Location;
		AttackLocation = AttackLocation / Locations.Num();
		ActivatedTowardsCentipedeDirection = (AttackLocation - MultiBoulderLauncher.LaunchLocation).GetSafeNormal();
		bAllScalingDone = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ActionComp.ActionQueue.Finish(this);
		ExpireUnlaunchedProjectiles();
		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(GrimbeastTags::AnimationBoulder, EBasicBehaviourPriority::Medium, this);
		AttackAnimElapsed += DeltaTime;
		if (AttackAnimElapsed > AnimComp.GetAnimDuration(GrimbeastTags::AnimationBoulder) * 0.7)
		{
			AttackAnimElapsed = 0.0;
			AnimComp.ClearFeature(this);
		}
		
		const FVector TinyScale = FVector::OneVector * 0.001;
		for (int i = 0; i < Projectiles.Num(); ++i) 
		{
			FSanctuaryGrimbeastMultiProjectileBoulderData& ProjectileData = Projectiles[i];
			if (!ProjectileData.bPrimed && ProjectileData.SpawnData.SpawnDelay >= LastActiveDuration && ProjectileData.SpawnData.SpawnDelay <= ActiveDuration)
				CrumbPrimeProjectile(i);

			if (!ProjectileData.bPrimed)
				continue;

			float ProjectileActiveDuration = ActiveDuration - ProjectileData.PrimeTimeStamp;

			// snowball whohoooieieee
			if (Settings.BoulderSnowballDuration > KINDA_SMALL_NUMBER)
			{
				float InterpolationValue = Math::Clamp(ProjectileActiveDuration / Settings.BoulderSnowballDuration, 0.0, 1.0);
				ProjectileData.Projectile.Owner.SetActorScale3D(Math::EaseInOut(TinyScale, FVector::OneVector, InterpolationValue, 2));

				bool bScalingDone = ProjectileActiveDuration > Settings.BoulderSnowballDuration;
				if (bScalingDone && i == Projectiles.Num() -1)
					bAllScalingDone = true;
			}
			else
			{
				ProjectileData.Projectile.Owner.SetActorScale3D(FVector::OneVector);
				if (i == Projectiles.Num() -1)
					bAllScalingDone = true;
			}

			if(!ProjectileData.bLaunched && ProjectileActiveDuration > 0.1)
				Launch(i, ProjectileData);
		}

		LastActiveDuration = ActiveDuration;
	}

	private void Launch(int Index, FSanctuaryGrimbeastMultiProjectileBoulderData& ProjectileData)
	{
		FVector StartDirection = MultiBoulderLauncher.ForwardVector;
		if (ProjectileData.SpawnData.AngleSpace == ESanctuaryGrimbeastBoulderAngleSpace::TowardsCentipedeMiddle)
			StartDirection = ActivatedTowardsCentipedeDirection;
		else if (ProjectileData.SpawnData.AngleSpace == ESanctuaryGrimbeastBoulderAngleSpace::WorldSpace)
			StartDirection = FVector::ForwardVector;

		if (!Math::IsNearlyEqual(ProjectileData.SpawnData.Angle, 0.0))
			StartDirection = FRotator::MakeFromEuler(FVector(0.0, 0.0, ProjectileData.SpawnData.Angle)).RotateVector(StartDirection);

		CrumbLaunch(Index, StartDirection);
	}


	UFUNCTION(CrumbFunction)
	private void CrumbPrimeProjectile(int Index)
	{
		FSanctuaryGrimbeastMultiProjectileBoulderData& ProjectileData = Projectiles[Index];
		ProjectileData.bPrimed = true;
		ProjectileData.PrimeTimeStamp = ActiveDuration;
		ProjectileData.Projectile = MultiBoulderLauncher.Prime();
		Cast<ASanctuaryGrimbeastBoulderProjectile>(ProjectileData.Projectile.Owner).Owner = Owner;
		// const FVector TinyScale = FVector::OneVector * 0.001;
		// ProjectileData.Projectile.Owner.SetActorScale3D(TinyScale);

		// USanctuaryGrimbeastEventHandler::Trigger_OnBoulderTelegraph(Owner, FSanctuaryGrimbeastOnBoulderTelegraphEventData(MultiBoulderLauncher.LaunchLocation));
		// UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(MultiBoulderLauncher, Durations.GetPreActionDuration()));	
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLaunch(int Index, FVector StartDirection)
	{
		FSanctuaryGrimbeastMultiProjectileBoulderData& ProjectileData = Projectiles[Index];
		ProjectileData.bLaunched = true;
		FVector TargetLocation = MultiBoulderLauncher.LaunchLocation + StartDirection * 300.0;
		Cast<ASanctuaryGrimbeastBoulderProjectile>(ProjectileData.Projectile.Owner).AttackLocation = TargetLocation;
		MultiBoulderLauncher.Launch(StartDirection * Settings.BoulderProjectileSpeed);
		ProjectileData.Projectile.Friction = 0;
		ProjectileData.Projectile.UpVector = -Owner.ActorRightVector;
		ProjectileData.Projectile.Gravity = ProjectileData.SpawnData.CurveToRight;
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(MultiBoulderLauncher, 1, 1));
	}

	private void ExpireUnlaunchedProjectiles()
	{
		for (FSanctuaryGrimbeastMultiProjectileBoulderData& ProjectileData : Projectiles) 
		{
			if(ProjectileData.Projectile != nullptr && !ProjectileData.Projectile.bIsLaunched)
				ProjectileData.Projectile.Expire();
		}
		Projectiles.Empty();
	}

	private bool HasLaunchedAllProjectiles() const
	{
		for (const FSanctuaryGrimbeastMultiProjectileBoulderData& ProjectileData : Projectiles) 
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
	private void GetShootDataFromPattern(TArray<FSanctuaryGrimbeastBoulderCreationData>& OutData, const FSanctuaryGrimbeastBoulderPatternData& PatternData)
	{
		OutData.Empty();
		if (PatternData.Amount == 0)
			return;

		if (PatternData.Amount == 1)
		{
			OutData.Add(FSanctuaryGrimbeastBoulderCreationData(PatternData.Delay));
		}
		else 
		{
			switch (PatternData.PatternType)
			{
				case ESanctuaryGrimbeastBoulderPattern::Arrow:
					CreateArrowShot(OutData, PatternData.Amount, PatternData.Delay, PatternData.AngleSpread, false);
					break;
				case ESanctuaryGrimbeastBoulderPattern::V:
					CreateArrowShot(OutData, PatternData.Amount, PatternData.Delay, PatternData.AngleSpread, true);
					break;
				case ESanctuaryGrimbeastBoulderPattern::SpiralShot:
					CreateSpiralShot(OutData, PatternData.Amount, PatternData.Delay, PatternData.AngleSpread);
					break;
				case ESanctuaryGrimbeastBoulderPattern::AntiSpiralShot:
					CreateSpiralShot(OutData, PatternData.Amount, PatternData.Delay, -PatternData.AngleSpread);
					break;
				case ESanctuaryGrimbeastBoulderPattern::Cross:
				{
					int CrossWaves = Math::IntegerDivisionTrunc(PatternData.Amount, 4);
					for (int i = 0; i < CrossWaves; ++i)
						CreateCircleShot(OutData, 4, i * PatternData.Delay, 360.0);
					break;
				}
				case ESanctuaryGrimbeastBoulderPattern::Circle:
					CreateCircleShot(OutData, PatternData.Amount, PatternData.Delay, 360.0);
					break;
				default: // single shot
				{
	#if EDITOR
					PrintToScreen("Lava Mole Pattern not found! Defaulting to single", 1.0, FLinearColor::Red);
	#endif
					OutData.Add(FSanctuaryGrimbeastBoulderCreationData(PatternData.Delay));
				}
			}
		}

		for (FSanctuaryGrimbeastBoulderCreationData& CreationData : OutData)
		{
			CreationData.AngleSpace = PatternData.AngleSpace;
			CreationData.CurveToRight = PatternData.CurveToRight;
			CreationData.Angle += PatternData.AngleOffset;
		}
	}

	private void CreateArrowShot(TArray<FSanctuaryGrimbeastBoulderCreationData>& OutData, int Amount, float Delay, float TotalAngle, bool bIsVShape)
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

			OutData.Add(FSanctuaryGrimbeastBoulderCreationData(ShapeDelay * Delay, CurrentAngle));
		}
	}

	private void CreateSpiralShot(TArray<FSanctuaryGrimbeastBoulderCreationData>& OutData, int Amount, float Delay, float TotalAngle)
	{
		const float AngleStep = TotalAngle / (Amount -1);
		for (int i = 0; i < Amount; ++i)
			OutData.Add(FSanctuaryGrimbeastBoulderCreationData(Delay * i, AngleStep * i));
	}

	private void CreateCircleShot(TArray<FSanctuaryGrimbeastBoulderCreationData>& OutData, int Amount, float Delay, float TotalAngle, bool bDelayEven = false)
	{
		const float AngleStep = TotalAngle / Amount;
		for (int i = 0; i < Amount; ++i)
		{
			int DelayEven = 0;
			if (bDelayEven)
				DelayEven = i % 2;
			OutData.Add(FSanctuaryGrimbeastBoulderCreationData(DelayEven * Delay, AngleStep * i));
		}
	}

	AHazePlayerCharacter GetControlPlayer() const
	{
		if (Game::Mio.HasControl())
			return Game::Mio;

		return Game::Zoe;
	}
}
