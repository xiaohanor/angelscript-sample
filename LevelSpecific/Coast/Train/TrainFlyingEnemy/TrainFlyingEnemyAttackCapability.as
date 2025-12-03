
class UTrainFlyingEnemyAttackCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ATrainFlyingEnemy Enemy;

	int ProjectilesFired = 0;
	float Timer = 0.0;
	float TargetOffset = 0.0;
	float RepositionTime = BIG_NUMBER;

	UTrainFlyingEnemySettings Settings;
	FHazeAcceleratedVector PredictionVelocity;
	AHazePlayerCharacter PrevTarget = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enemy = Cast<ATrainFlyingEnemy>(Owner);
		Settings = UTrainFlyingEnemySettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsBlocked())	
			return;
		if (Enemy.Target.TargetPlayer == nullptr)
			return;
		if (Enemy.Target.TargetPlayer != PrevTarget)
			PredictionVelocity.SnapTo(Enemy.Target.TargetPlayer.ActorVelocity);
		else
			PredictionVelocity.AccelerateTo(Enemy.Target.TargetPlayer.ActorVelocity, 1.0, DeltaTime);
		PrevTarget = Enemy.Target.TargetPlayer;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTrainFlyingEnemyTargetingParams& OutParams) const
	{
		if (Enemy.bDestroyedByPlayer)
			return false;
		if (Enemy.bRetarget)
			return false;
		if (Enemy.Target.TargetPlayer == nullptr)
			return false;
		if (Enemy.bIsFlyingIn)
			return false;
		OutParams = Enemy.Target;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ProjectilesFired >= Settings.ProjectileAmount && Timer >= Settings.TimeWaitAfterProjectiles)
			return true;
		if (Enemy.bDestroyedByPlayer)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTrainFlyingEnemyTargetingParams Params)
	{
		ProjectilesFired = 0;
		Timer = 0.0;

		Enemy.Target = Params;

		FTransform CartPosition = Enemy.Target.TargetCart.CurrentPosition.WorldTransform;
		FVector PlayerPosition = Enemy.Target.TargetPlayer.ActorLocation;
		PlayerPosition += PredictionVelocity.Value * Settings.ProjectilePredictionTime;
		TargetOffset = CartPosition.InverseTransformPositionNoScale(PlayerPosition).X;
		TargetOffset += Settings.SpaceBeforeFirstProjectile;

		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Settings.TimeWaitBeforeProjectiles));			
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Enemy.bRetarget = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Timer += DeltaTime;

		float RequiredTime = Settings.TimeBetweenProjectiles;
		if (ProjectilesFired == 0)
			RequiredTime = Settings.TimeWaitBeforeProjectiles;

		if (Timer >= RequiredTime && ProjectilesFired < Settings.ProjectileAmount)
		{
			FireProjectile(ProjectilesFired);
			Timer -= RequiredTime;
			ProjectilesFired += 1;
			if (ProjectilesFired == Settings.ProjectileAmount)
				RepositionTime = Time::GameTimeSeconds + Settings.TimeWaitAfterProjectiles * 0.5;
		}

		if (Time::GameTimeSeconds > RepositionTime)
		{
			Enemy.bReposition = true;
			RepositionTime = BIG_NUMBER;
		}
	}

	void FireProjectile(int Index)
	{
		if (!HasControl())
			return;

		ACoastTrainCart TargetCart = Enemy.Target.TargetCart;

		FVector TargetCartOffset;
		TargetCartOffset.X = TargetOffset;
		TargetCartOffset.X += (Settings.SpaceBetweenProjectiles * Index);

		// Do a trace from the sky to find where we're going to land 
		FTransform CartPosition = TargetCart.CurrentPosition.WorldTransform;

		// We might have moved forward enough to be hitting a new cart
		FVector PositionAfterCart = CartPosition.TransformPosition(TargetCartOffset);
		TargetCart = TargetCart.Driver.GetCartClosestToLocation(PositionAfterCart);

		FTransform NewCartPosition = TargetCart.CurrentPosition.WorldTransform;
		TargetCartOffset = NewCartPosition.InverseTransformPosition(CartPosition.TransformPosition(TargetCartOffset));
		CartPosition = NewCartPosition;

		FVector CartUp = CartPosition.Rotation.UpVector;
		FVector TraceStart = CartPosition.TransformPosition(TargetCartOffset) + CartUp * 3000.0;
		FVector TraceEnd = CartPosition.TransformPosition(TargetCartOffset) - CartUp * 0.0;

		FHazeTraceSettings Trace;
		Trace.TraceWithChannel(ECollisionChannel::ECC_WorldDynamic);
		Trace.UseLine();

		FVector TargetPosition = TraceEnd;
		FHitResult Hit = Trace.QueryTraceSingle(TraceStart, TraceEnd);
		if (Hit.bBlockingHit)
			TargetPosition = Hit.ImpactPoint;

		FVector DestinationOffset = CartPosition.InverseTransformPosition(TargetPosition);
		FVector StartOffset = CartPosition.InverseTransformPosition(Enemy.ProjectileSpawnPoint.WorldLocation);
		CrumbFireProjectile(TargetCart, TargetCartOffset, DestinationOffset, StartOffset);
	}

	UFUNCTION(CrumbFunction)
	void CrumbFireProjectile(ACoastTrainCart TargetCart, FVector TargetCartOffset, FVector DestinationOffset, FVector StartOffset)
	{
		auto Projectile = Cast<ATrainFlyingEnemyProjectile>(SpawnActor(
			Enemy.ProjectileType,
			Enemy.ProjectileSpawnPoint.WorldLocation,
			FRotator::MakeFromX(Enemy.ActorUpVector),
			bDeferredSpawn = true));

		Projectile.Launcher = Owner;
		Projectile.TargetCart = TargetCart;
		Projectile.TargetCartOffset = TargetCartOffset;
		Projectile.DestinationOffset = DestinationOffset;
		Projectile.StartOffset = StartOffset;

		FinishSpawningActor(Projectile);

		UTrainFlyingEnemyEffectEventHandler::Trigger_FireProjectile(Enemy);
		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Enemy.ProjectileSpawnPoint.WorldLocation, Enemy.ActorForwardVector * 120000.0, ProjectilesFired + 1, Settings.ProjectileAmount));
	}
}