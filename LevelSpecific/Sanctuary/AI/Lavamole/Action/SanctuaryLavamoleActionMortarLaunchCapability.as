enum ESanctuaryLavamoleMortarTargetingStrategy
{
	ChaseMiddle = 0,
	ChaseMio,
	ChaseZoe,
	PredictMio,
	PredictZoe,
	Ambush,
	Tactical,
	Oblivious,
	MiddleArea,
}

struct FSanctuaryLavamoleActionMortarQueueData
{
	float Duration;
	float SpeedMultiplier = 1.0;
	ESanctuaryLavamoleMortarTargetingStrategy TargetingStrategy = ESanctuaryLavamoleMortarTargetingStrategy::MiddleArea;
}

struct FSanctuaryLavamoleActionMortarActivationData
{
	FVector TargetLocation;
	FVector Velocity;
	FVector Forwards;
}

class USanctuaryLavamoleActionMortarLaunchCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FSanctuaryLavamoleActionMortarQueueData QueueParams;
	default CapabilityTags.Add(LavamoleTags::LavaMole);
	default CapabilityTags.Add(LavamoleTags::Action);

	UBasicAIProjectileLauncherComponent ProjectileLauncher;

	FHazeAcceleratedVector AccScale;
	AAISanctuaryLavamole Mole;
	USanctuaryLavamoleSettings Settings;

	AActor Mio;
	AActor Zoe;

	int LaunchedProjectiles = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mole = Cast<AAISanctuaryLavamole>(Owner);
		ProjectileLauncher = Mole.MortarLauncher;
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
		Mio = Game::GetMio();
		Zoe = Game::GetZoe();
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FSanctuaryLavamoleActionMortarQueueData Parameters)
	{
		QueueParams = Parameters;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryLavamoleActionMortarActivationData & ActivationParams) const
	{
		ActivationParams.TargetLocation = GetAttackLocation();
		float Distance = (ActivationParams.TargetLocation - ProjectileLauncher.LaunchLocation).Size();
		const float MagicSpeedModifier = 0.3;
		float Speed = Distance * QueueParams.SpeedMultiplier * MagicSpeedModifier;
		ActivationParams.Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ProjectileLauncher.LaunchLocation, ActivationParams.TargetLocation, Settings.MortarProjectileGravity, Speed);
		ActivationParams.Forwards = Mole.ActorForwardVector;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > QueueParams.Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryLavamoleActionMortarActivationData ActivationParams)
	{
		check(Mole.PrimedMortar != nullptr);
		Launch(ActivationParams.TargetLocation, ActivationParams.Velocity, FRotator::MakeFromX(ActivationParams.Forwards));
		Mole.PrimedMortar = nullptr;
		Mole.AnimationMode = ESanctuaryLavamoleAnimation::Shoot;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Mole.AnimationMode == ESanctuaryLavamoleAnimation::Shoot && !Mole.bIsAggressive)
			Mole.AnimationMode = ESanctuaryLavamoleAnimation::IdleAbove;
	}

	private void Launch(FVector AttackLocation, FVector Velocity, FRotator Rotation)
	{
		// Debug::DrawDebugString(AttackLocation, "Attack " + GetName(), Color = ColorDebug::Rainbow(2.0), Duration = 10.0);
		ASanctuaryLavamoleMortarProjectile Projectile = Cast<ASanctuaryLavamoleMortarProjectile>(Mole.PrimedMortar.Owner);
		Mole.Manager.StartListen(Projectile);
		Projectile.AttackLocation = AttackLocation;
		ProjectileLauncher.Launch(Velocity, Rotation);
		Mole.PrimedMortar.Gravity = Settings.MortarProjectileGravity;
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(ProjectileLauncher, 1, 1));
	}

	// ATTACK LOCATION LOGIC BELOW ------------------

	FVector GetAttackLocation() const
	{
		FVector AttackLocation = FVector::ZeroVector;
		switch (QueueParams.TargetingStrategy)
		{
			case ESanctuaryLavamoleMortarTargetingStrategy::ChaseMiddle:
			{
				AttackLocation = GetChaseAttackLocation();
				break;
			}
			case ESanctuaryLavamoleMortarTargetingStrategy::ChaseMio:
			{
				AttackLocation = GetMioAttackLocation();
				break;
			}
			case ESanctuaryLavamoleMortarTargetingStrategy::ChaseZoe:
			{
				AttackLocation = GetZoeAttackLocation();
				break;
			}
			case ESanctuaryLavamoleMortarTargetingStrategy::PredictMio:
			{
				AttackLocation = GetPredictedMioAttackLocation();
				break;
			}
			case ESanctuaryLavamoleMortarTargetingStrategy::PredictZoe:
			{
				AttackLocation = GetPredictedZoeAttackLocation();
				break;
			}
			case ESanctuaryLavamoleMortarTargetingStrategy::Ambush:
			{
				AttackLocation = GetAmbushAttackLocation();
				break;
			}
			case ESanctuaryLavamoleMortarTargetingStrategy::Tactical:
			{
				AttackLocation = GetTacticalAttackLocation();
				break;
			}
			case ESanctuaryLavamoleMortarTargetingStrategy::Oblivious:
			{
				AttackLocation = GetObliviousAttackLocation();
				break;
			}
			case ESanctuaryLavamoleMortarTargetingStrategy::MiddleArea:
			{
				AttackLocation = GetMiddleAttackAreaLocation();
				break;
			}
			default:
			AttackLocation = GetChaseAttackLocation();
		}
		return AttackLocation;
	}

	// Oblivious location, constant random location
	private FVector GetObliviousAttackLocation() const
	{
		return FVector::ZeroVector;
	}

	// Predict future location considering ambush && chase
	private FVector GetTacticalAttackLocation() const
	{
		FVector ChaseAttackLocation = GetChaseAttackLocation();
		FVector AmbushAttackLocation = GetAmbushAttackLocation();
		FVector ToAmbush = AmbushAttackLocation - ChaseAttackLocation;
		return ChaseAttackLocation - ToAmbush;
	}

	// Predict future location
	private FVector GetAmbushAttackLocation() const
	{
		FVector CurrentMiddle = GetCentipedeMiddleAttackLocation();
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(Mio);
		if(!ensure(CentipedeComp != nullptr, "Player isn't a centipede!"))
			return CurrentMiddle;

		// This needs to be redone if we want to use it :)
		// weigh in both players velocity / facing, or picking either player velcotiy / facing
		FVector GeneralVelocity = CentipedeComp.Centipede.ActorHorizontalVelocity;
		if (GeneralVelocity.Size() < KINDA_SMALL_NUMBER)
			GeneralVelocity = CentipedeComp.Centipede.ActorRotation.ForwardVector * 1000.0;

		return CurrentMiddle;// + GeneralVelocity * 2.0;
	}

	// An area near centipede middle
	private FVector GetMiddleAttackAreaLocation() const
	{
		FVector CurrentMiddle = GetCentipedeMiddleAttackLocation();
		float RandomAngle = Math::RandRange(0.0, 360.0);
		float RandomOutwards = Math::RandRange(0.1, 1.0);
		float Radius = 300.0 + Mole.NumMortarsToShoot * 20.0;
		FVector CenterOffset = Math::RotatorFromAxisAndAngle(FVector::UpVector, RandomAngle).RotateVector(FVector::ForwardVector) * RandomOutwards * Radius;
		return CurrentMiddle + CenterOffset;
	}

	// Chase current location
	private FVector GetChaseAttackLocation() const
	{
		return GetCentipedeMiddleAttackLocation();
	}

	private FVector GetMioAttackLocation() const
	{
		return Mio.ActorLocation;
	}

	private FVector GetZoeAttackLocation() const
	{
		return Zoe.ActorLocation;
	}

	private float MinMaxOffset = 200.0;

	private FVector GetPredictedMioAttackLocation() const
	{
		FVector FlatOffset = Mio.ActorVelocity * 2.0;
		FlatOffset.Z = 0.0;
		FlatOffset.X += Math::RandRange(-MinMaxOffset, MinMaxOffset);
		FlatOffset.Y += Math::RandRange(-MinMaxOffset, MinMaxOffset);
		return Mio.ActorLocation + FlatOffset;
	}

	private FVector GetPredictedZoeAttackLocation() const
	{
		FVector FlatOffset = Zoe.ActorVelocity * 2.0;
		FlatOffset.Z = 0.0;
		FlatOffset.X += Math::RandRange(-MinMaxOffset, MinMaxOffset);
		FlatOffset.Y += Math::RandRange(-MinMaxOffset, MinMaxOffset);
		return Zoe.ActorLocation + FlatOffset;
	}

	private FVector GetCentipedeMiddleAttackLocation() const
	{
		TArray<FVector> Locations = GetTailLocations();
		FVector AttackLocation;
		for(FVector Location: Locations)
			AttackLocation += Location;
		AttackLocation = AttackLocation / Locations.Num();
		return AttackLocation;
	}

	private TArray<FVector> GetTailLocations() const
	{
		TArray<FVector> Locations;
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(Mio);
		if(ensure(CentipedeComp != nullptr, "Player isn't a centipede!"))
			Locations = CentipedeComp.GetBodyLocations();
		return Locations;
	}
}
