struct FWingsuitBossTrainAttackTargetData
{
	FHazeAcceleratedVector PredictedVelocity;
	float LaunchTime;
	int NumProjectilesFired = 0;
	float TargetOffset = 0.0;
	ACoastTrainCart TargetCart;

	UCoastTrainRiderComponent TrainRiderComp;

	void Reset()
	{
		PredictedVelocity.SnapTo(FVector::ZeroVector);
		NumProjectilesFired = 0;
		TargetOffset = 0.0;
	}

	void SkipAttack()
	{
		NumProjectilesFired	= 1000000;
		LaunchTime = BIG_NUMBER;	
	}	
}

struct FWingSuitBossTrainMissileAttackParameters
{
	AHazePlayerCharacter PrimaryTarget;
	AHazePlayerCharacter SecondaryTarget;
}

class UWingsuitBossTrainMissileAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(WingsuitBossTags::WingsuitBossAttack);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AWingsuitBoss Boss;
	UWingsuitBossSettings Settings;
	TPerPlayer<FWingsuitBossTrainAttackTargetData> TargetData;
	int ActivationCount = 0;
	float CooldownTime = 0.0;
	int NumProjectilesFired;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<AWingsuitBoss>(Owner);
		Settings = UWingsuitBossSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsBlocked())	
			return;
		if (Boss.TargetCart == nullptr)
			return;	

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (TargetData[Player].TrainRiderComp == nullptr)
				TargetData[Player].TrainRiderComp = UCoastTrainRiderComponent::Get(Player);

			// Players will be moving relative to train, so this velocity is in train space
			FVector ClampedVelocity = Player.ActorVelocity.GetClampedToMaxSize(500.0);			
			TargetData[Player].PredictedVelocity.AccelerateTo(ClampedVelocity, 1.0, DeltaTime);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWingSuitBossTrainMissileAttackParameters& OutParams) const
	{
		if (Boss.TargetCart == nullptr)
			return false;
		if (!Boss.bAllowMissileAttacks)
			return false;
		if (Time::GameTimeSeconds < CooldownTime)
			return false;
		bool bCanAttackMio = CanBeAttacked(Game::Mio);
		bool bCanAttackZoe = CanBeAttacked(Game::Zoe);
		if (!bCanAttackMio && !bCanAttackZoe)
			return false;
		
		OutParams.SecondaryTarget = nullptr;
		if (!bCanAttackMio)
		{
			// Can only attack Zoe
			OutParams.PrimaryTarget = Game::Zoe;
		}
		else if (!bCanAttackZoe)
		{
			// Can only attack Mio
			OutParams.PrimaryTarget = Game::Mio;
		}
		else
		{
			// Attack both players if they are some distance apart, or only foremost player when they are close
			float MioBehind = TargetData[Game::Mio].TrainRiderComp.DistanceToDriver;
			float ZoeBehind = TargetData[Game::Zoe].TrainRiderComp.DistanceToDriver;
			OutParams.PrimaryTarget = (ZoeBehind < MioBehind) ? Game::Zoe : Game::Mio;
			if (Math::Abs(MioBehind - ZoeBehind) > Settings.AttackBothPlayersThreshold)
				OutParams.SecondaryTarget = OutParams.PrimaryTarget.OtherPlayer;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Boss.TargetCart == nullptr)
			return true;
		if (!Boss.bAllowMissileAttacks)
			return true;
		if (IsAttackFinished())
			return true;
		return false;
	}

	bool CanBeAttacked(AHazePlayerCharacter Player) const
	{
		if (TargetData[Player].TrainRiderComp == nullptr)
			return false;
		if (TargetData[Player].TrainRiderComp.CurrentTrainCart == nullptr)
			return false;
		if (Player.IsPlayerDead())
			return false;
		if (TargetData[Player].TrainRiderComp.CurrentTrainCart.IsInBossAttackSafeZone(Player.ActorLocation))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FWingSuitBossTrainMissileAttackParameters Params)
	{
		ActivationCount++;
		Boss.RepositionTimer = BIG_NUMBER;
		NumProjectilesFired = 0;

		// Note that attacks themselves are crumbed, so it's fine if preparatory data is desynced in network
		// We do need to keep track of which players are targetable and who is the foremost target though.
		// Also note that any players deemed targetable on control side which do not have a target cart 
		// at this time will use the other player's or the boss target cart as backup.
		TArray<AHazePlayerCharacter> Targets;
		Targets.Add(Params.PrimaryTarget);
		if (Params.SecondaryTarget != nullptr)
			Targets.Add(Params.SecondaryTarget);
		else 	
			TargetData[Params.PrimaryTarget.OtherPlayer].SkipAttack();

		// Launch attack at predicted player location
		for (AHazePlayerCharacter Player : Targets)
		{
			TargetData[Player].TrainRiderComp = UCoastTrainRiderComponent::Get(Player);
			TargetData[Player].TargetCart = TargetData[Player].TrainRiderComp.CurrentTrainCart;
			if ((TargetData[Player].TargetCart == nullptr) && (TargetData[Player.OtherPlayer].TrainRiderComp != nullptr))
				TargetData[Player].TargetCart = TargetData[Player.OtherPlayer].TrainRiderComp.CurrentTrainCart;
			if (TargetData[Player].TargetCart == nullptr)
				TargetData[Player].TargetCart = Boss.TargetCart;
			
			FTransform CartPosition = GetAttackTransform(TargetData[Player].TargetCart);
			FVector PlayerPosition = Player.ActorLocation;
			PlayerPosition += TargetData[Player].PredictedVelocity.Value * Settings.ProjectilePredictionTime;
			TargetData[Player].TargetOffset = CartPosition.InverseTransformPositionNoScale(PlayerPosition).X;
			TargetData[Player].TargetOffset += Settings.SpaceBeforeFirstProjectile;

			// If one player is a long distance behind the other, we aim at where they are to drive them forward
			float MioBehind = TargetData[Game::Mio].TrainRiderComp.DistanceToDriver;
			float ZoeBehind = TargetData[Game::Zoe].TrainRiderComp.DistanceToDriver;
			if ((Player != Params.PrimaryTarget) && (Math::Abs(MioBehind - ZoeBehind) > Settings.DriveRearmostPlayerForwardThreshold))
			{
				TargetData[Player].TargetOffset += Settings.DriveRearmostPlayerForwardOffset;
				if (Settings.NumberOfProjectilesPerPlayer > 0)
					TargetData[Player].TargetOffset -= Settings.SpaceBetweenProjectiles; // More than one projectile, first is fired behind player
			}

			// We can never target a location in front of ourselves along train track
			float OwnFwdOffset = TargetData[Player].TargetCart.ActorForwardVector.DotProduct(Owner.ActorLocation - TargetData[Player].TargetCart.ActorLocation);
			float Buffer = (Settings.NumberOfProjectilesPerPlayer - 1) * Settings.SpaceBetweenProjectiles + 500.0;
			if (TargetData[Player].TargetOffset > OwnFwdOffset - Buffer)
				TargetData[Player].TargetOffset = OwnFwdOffset - Buffer;

			TargetData[Player].LaunchTime = Settings.InitialLaunchDelay;
			if (Player != Params.PrimaryTarget)
				TargetData[Player].LaunchTime += 0.4;
		}

		Boss.ProjectileLauncher.TargetPitch.Apply(Settings.LauncherAttackPitch, this, EInstigatePriority::Normal);
		Boss.ProjectileLauncher.PitchDuration.Apply(Settings.InitialLaunchDelay * 2.0, this, EInstigatePriority::Normal);

		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Settings.InitialLaunchDelay));			
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.RepositionTimer = Settings.RepsitionCooldownAfterAttack;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			TargetData[Player].Reset();
		}

		Boss.ProjectileLauncher.TargetPitch.Clear(this);
		Boss.ProjectileLauncher.PitchDuration.Clear(this);

		CooldownTime = Time::GameTimeSeconds + Settings.AttackCooldown;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (AHazePlayerCharacter Target : Game::Players)
		{
			if (!Target.HasControl())
				continue;
			if (ActiveDuration < TargetData[Target].LaunchTime)
				continue;
			
			ACoastTrainCart CurrentCart = TargetData[Target].TrainRiderComp.CurrentTrainCart;
			if (CurrentCart == nullptr)
				CurrentCart = Boss.TargetCart;

			if (CurrentCart != TargetData[Target].TargetCart)
			{
				// Rebase target offset onto current cart
				FVector TargetWorldLoc = TargetData[Target].TargetCart.ActorTransform.TransformPosition(FVector(TargetData[Target].TargetOffset, 0.0, 0.0));
				TargetData[Target].TargetOffset = CurrentCart.ActorTransform.InverseTransformPosition(TargetWorldLoc).X;
				TargetData[Target].TargetCart = CurrentCart;
			}

			FVector TargetCartOffset = FVector::ZeroVector;
			TargetCartOffset.X = TargetData[Target].TargetOffset;
			TargetCartOffset.X += (Settings.SpaceBetweenProjectiles * TargetData[Target].NumProjectilesFired);

			// Do a trace from the sky to find where the projectile will land 
			FTransform CartPosition = GetAttackTransform(CurrentCart);

			// We might have moved forward enough to be hitting a new cart
			FVector PositionAfterCart = CartPosition.TransformPosition(TargetCartOffset);
			CurrentCart = CurrentCart.Driver.GetCartClosestToLocation(PositionAfterCart);

			FTransform NewCartPosition = GetAttackTransform(CurrentCart);
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
			CrumbFireProjectile(Target, CurrentCart, DestinationOffset);
		}	
	}

	FTransform GetAttackTransform(ACoastTrainCart Cart)
	{
		return Cart.MeshRootAbsoluteComp.WorldTransform;
	}

	UFUNCTION(CrumbFunction)
	void CrumbFireProjectile(AHazePlayerCharacter Target, ACoastTrainCart TargetCart, FVector DestinationOffset)
	{
		UBasicAIProjectileComponent ProjectileComp = Boss.ProjectileLauncher.Launch(FVector::ZeroVector, FRotator::MakeFromX(Boss.ActorUpVector));
		auto Projectile = Cast<AWingsuitBossProjectile>(ProjectileComp.Owner);
		
		NumProjectilesFired++;
		FVector LaunchLoc = Boss.ProjectileLauncher.LaunchLocation;
		int NumLaunchers = Boss.ProjectileLauncher.LaunchLocations.Num();
		bool bLeft = false; 
		if (NumLaunchers > 0)
		{
			int Launchindex = (NumProjectilesFired % NumLaunchers);
			if (ensure(Boss.ProjectileLauncher.LaunchLocations.IsValidIndex(Launchindex)))
				LaunchLoc = Boss.ProjectileLauncher.WorldTransform.TransformPosition(Boss.ProjectileLauncher.LaunchLocations[Launchindex]);
			bLeft = (Boss.ProjectileLauncher.LaunchLocations[Launchindex].X < 0.0);
		}
		FVector StartOffset = GetAttackTransform(TargetCart).InverseTransformPosition(LaunchLoc);
		Projectile.Launch(TargetCart, StartOffset, DestinationOffset, bLeft);

		TargetData[Target].NumProjectilesFired++;
		TargetData[Target].LaunchTime += Settings.TimeBetweenProjectiles;
		if (TargetData[Target].NumProjectilesFired >= Settings.NumberOfProjectilesPerPlayer)
			TargetData[Target].LaunchTime = BIG_NUMBER;

		UTrainFlyingEnemyEffectEventHandler::Trigger_FireProjectile(Boss);
		UWingsuitBossEffectHandler::Trigger_OnShootMultiRocket(Boss);
	}

	bool IsAttackFinished() const
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (TargetData[Player].NumProjectilesFired < Settings.NumberOfProjectilesPerPlayer)
				return false;
		}
		return true;
	}
}
