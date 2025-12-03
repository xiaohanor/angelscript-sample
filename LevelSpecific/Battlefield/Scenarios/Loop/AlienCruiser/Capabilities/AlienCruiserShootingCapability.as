class UAlienCruiserShootingCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AAlienCruiser Cruiser;
	
	float MissileFireCooldown;
	float MissileFireTimer = 0.0;

	int CurrentMissileLaunchPointIndex = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Cruiser = Cast<AAlienCruiser>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Cruiser.bShouldShoot)
			return false;

		if(Cruiser.bIsDestroyed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Cruiser.bShouldShoot)
			return true;

		if(Cruiser.bIsDestroyed)
			return true;

		if(Cruiser.Missiles.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Cruiser.CurrentRotationSpeed = Cruiser.ShootingRotationSpeed;
		MissileFireCooldown = Cruiser.ShootDuration / (Cruiser.Missiles.Num());
		MissileFireTimer = MissileFireCooldown;
		CurrentMissileLaunchPointIndex = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Cruiser.RotateMissileArms(DeltaTime);

		MissileFireTimer -= DeltaTime;

		while(MissileFireTimer <= 0)
		{
			MissileFireTimer += MissileFireCooldown;
			if(Cruiser.Missiles.Num() == 0)
				break;

			auto Missile = Cruiser.Missiles[0];
			Cruiser.Missiles.RemoveAtSwap(0);

			CurrentMissileLaunchPointIndex++;
			USceneComponent LaunchPoint = Cruiser.MissileLaunchPoints[CurrentMissileLaunchPointIndex % Cruiser.MissileLaunchPoints.Num()];

			FAlienCruiserMissileInitParams Params;
			Params.MissileForwardSpeed = Cruiser.MissileForwardSpeed;

			int TargetIndex = Cruiser.MissileTargets.Num() - 1;
			auto Target = Cruiser.MissileTargets[TargetIndex];
			Cruiser.MissileTargets.RemoveAt(TargetIndex);
			Params.Target = Target;
			Params.OrbitSpeed = Cruiser.CurrentRotationSpeed / 2;
			Params.CruiserRotationPivot = Cruiser.MissileOrbitRoot;
			Params.OrbitSpeedSlowDown = Cruiser.MissileOrbitSlowdown;
			Params.MissileInwardSpeed = Cruiser.MissileInwardSpeed;
			Params.MissileDistanceFromCenterTarget = Cruiser.MissileDistanceFromCenterTarget;
			Params.MissileDistanceFromTargetThreshold = Cruiser.MissileDistanceFromTargetThreshold;
			Params.ExplosionRadius = Cruiser.MissileExplosionRadius;
			Params.CruiserRotationAtLaunch = Cruiser.ActorRotation;
			Params.MissileSpeedMultiplier = Cruiser.MissileSpeedMultiplier;

			Missile.RemoveActorDisable(Cruiser);

			Missile.ActorLocation = LaunchPoint.WorldLocation;
			Missile.ActorRotation = FRotator::MakeFromX(LaunchPoint.ForwardVector);
			Missile.InitMissile(Params);
			
			FAlienCruiserMissileLaunchParams LaunchEffectParams;
			LaunchEffectParams.MissileLaunchRoot = LaunchPoint;
			UAlienCruiserEffectHandler::Trigger_OnMissileLaunched(Cruiser, LaunchEffectParams);
		}
	}
}