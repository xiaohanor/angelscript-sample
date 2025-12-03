enum EMedallionHydraProjectileType
{
	Basic,
	Splitting,
	SplittingSetOffset,
	SplittingQuad,
	Flying,
	Rain,
	BallistaRain,
	BallistaRainOnPlayer,
	Spam,
	Meteor
}

struct FMedallionHydraLaunchProjectileParams
{
	AHazePlayerCharacter TargetPlayer;
	EMedallionHydraProjectileType Type = EMedallionHydraProjectileType::Basic;
	float PredictedLocationOffset = 0.0;
}

struct FMedallionHydraMultipleLaunchProjectileParams
{
	TArray<FMedallionHydraLaunchProjectileParams> LaunchProjectileParams;
}

class UMedallionHydraLaunchProjectileCapability : UHazeActionQueueCapability
{
	//default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::AfterGameplay;

	FMedallionHydraMultipleLaunchProjectileParams QueueParameters;
	ASanctuaryBossMedallionHydra Hydra;

	UMedallionPlayerReferencesComponent RefsComp;

	int RainIndex = -1;
	float LastSplineDistance = 0.0;

	private TPerPlayer<bool> bHasStartedPlayerRainAttack;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FMedallionHydraMultipleLaunchProjectileParams Parameters)
	{
		QueueParameters = Parameters;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto Params : QueueParameters.LaunchProjectileParams)
		{
			LaunchProjectile(Params);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bHasStartedPlayerRainAttack[0] = false;
		bHasStartedPlayerRainAttack[1] = false;
	}

	UFUNCTION()
	void LaunchProjectile(FMedallionHydraLaunchProjectileParams Params)
	{
		if (!Params.TargetPlayer.HasControl())
			return;

		switch (Params.Type)
		{
			case EMedallionHydraProjectileType::Basic: LaunchBasicProjectile(Params);
			break;
			case EMedallionHydraProjectileType::Splitting: LaunchBasicProjectile(Params);
			break;
			case EMedallionHydraProjectileType::SplittingSetOffset: LaunchBasicProjectile(Params);
			break;
			case EMedallionHydraProjectileType::SplittingQuad: LaunchBasicProjectile(Params);
			break;
			case EMedallionHydraProjectileType::Flying: LaunchFlyingProjectile(Params);
			break;
			case EMedallionHydraProjectileType::Rain: LaunchRainProjectile(Params);
			break;
			case EMedallionHydraProjectileType::BallistaRain: LaunchBallistaRainProjectile(Params);
			break;
			case EMedallionHydraProjectileType::BallistaRainOnPlayer: LaunchBallistaRainProjectile(Params);
			break;
			case EMedallionHydraProjectileType::Spam: LaunchSpamProjectile(Params);
			break;
			case EMedallionHydraProjectileType::Meteor: break;
		}
	}

	void LaunchBasicProjectile(FMedallionHydraLaunchProjectileParams Params)
	{
		//SETUP

		AHazePlayerCharacter TargetPlayer = Params.TargetPlayer;
		UPlayerMovementComponent TargetPlayerMoveComp = UPlayerMovementComponent::Get(TargetPlayer);
		UHazeSplineComponent Spline = Hydra.Refs.SideScrollerSplineLocker.Spline;

		float PlayerSign = Params.TargetPlayer == Game::Mio ? 1.0 : -1.0;

		auto Targets = TListedActors<ASanctuaryBossArenaHydraTarget>();
		float ClosestDistance = BIG_NUMBER;
		ASanctuaryBossArenaHydraTarget ClosestTarget;

		FVector PlayerVelocity = TargetPlayerMoveComp.GetVelocity() * 2.0;

		if (Params.Type == EMedallionHydraProjectileType::SplittingSetOffset)
			PlayerVelocity = FVector::ZeroVector;

		FVector PredictedFutureLocation = TargetPlayer.ActorLocation + PlayerVelocity;

		float PlayerSplineProgress = Spline.GetClosestSplineDistanceToWorldLocation(TargetPlayer.ActorLocation);
		float PredictedFutureSplineProgress = Spline.GetClosestSplineDistanceToWorldLocation(PredictedFutureLocation) + Params.PredictedLocationOffset * PlayerSign;

		if (PredictedFutureSplineProgress * PlayerSign < PlayerSplineProgress * PlayerSign)
			PredictedFutureSplineProgress = PlayerSplineProgress;

		FVector PredictedFutureSplineLocation = Spline.GetWorldLocationAtSplineDistance(PredictedFutureSplineProgress);

		FVector TargetLocation;

		//-----------------------------------

		//FIND CLOSEST TARGET ACTOR

		for (auto Target : Targets)
		{
			if (!Target.bTargetable)
				continue;

			if (Target.bProjectileTargeted)
				continue;

			float DistanceToTarget = Math::Abs((Spline.GetClosestSplineDistanceToWorldLocation(Target.TargetComp.WorldLocation) - PredictedFutureSplineProgress));
			
			if (DistanceToTarget < ClosestDistance)
			{
				ClosestTarget = Target;
				ClosestDistance = DistanceToTarget;
			}
		}

		if (ClosestTarget != nullptr)
			TargetLocation = ClosestTarget.TargetComp.WorldLocation;

		//-----------------------------------

		//FIND CLOSEST SPLINE TARGET LOCATION IF TARGET LOCATION WAS OUT OF REACH

		if (ClosestDistance > Hydra.MinimumTargetableDistance)
		{
			for (int i = 0; i < 10; i++)
			{
				float SplineProgressOffset = 0.0;
				SplineProgressOffset = i * 300.0;

				if (i % 2 == 0)
				{
					SplineProgressOffset = -SplineProgressOffset;
				}

				FVector ClosestSplineLocation = Spline.GetWorldLocationAtSplineDistance(PredictedFutureSplineProgress + SplineProgressOffset);

				auto Trace = Trace::InitProfile(n"PlayerCharacter");
				auto HitResult = Trace.QueryTraceSingle(ClosestSplineLocation + FVector::UpVector * 3000.0, ClosestSplineLocation - FVector::UpVector * 1000.0);

				if (HitResult.bBlockingHit)
				{
					if (Cast<ASanctuaryBossArenaFloatingPlatform>(HitResult.Actor) != nullptr)
						continue;

					TargetLocation = HitResult.ImpactPoint;
					break;
				}
			}

			//CHECK IF CLOSEST SPLINE TARGET LOCATION IS CLOSER THAN CLOSEST TARGET ACTOR

			if (ClosestTarget != nullptr)
			{
				float DistanceToClosestTarget = Math::Abs((Spline.GetClosestSplineDistanceToWorldLocation(ClosestTarget.TargetComp.WorldLocation) - PredictedFutureSplineProgress));
				float DistanceToClosestSplineTarget = Math::Abs((Spline.GetClosestSplineDistanceToWorldLocation(TargetLocation) - PredictedFutureSplineProgress));

				if (DistanceToClosestTarget < DistanceToClosestSplineTarget)
					TargetLocation = ClosestTarget.TargetComp.WorldLocation;
				else
					ClosestTarget = nullptr;
			}
		}

		//-----------------------------------

		//DEBUG

		if (SanctuaryHydraDevToggles::Drawing::DrawHydraProjectileTargeting.IsEnabled() && ClosestTarget != nullptr)
			Debug::DrawDebugSphere(ClosestTarget.ActorLocation, 100.0, 12, TargetPlayer.GetPlayerUIColor());

		if (SanctuaryHydraDevToggles::Drawing::DrawHydraProjectileTargeting.IsEnabled())
		{
			PrintToScreen("" + TargetPlayer.GetName() + " " + PlayerVelocity);
			Debug::DrawDebugLine(TargetPlayer.ActorLocation, PredictedFutureSplineLocation, TargetPlayer.GetPlayerUIColor(), 5.0, 5.0);
		}

		//-----------------------------------

		//LAUNCH PROJECTILE


		if (Params.Type == EMedallionHydraProjectileType::Basic)
		{
			CrumbLaunchBasicProjectile(TargetLocation, ClosestTarget, Params.TargetPlayer);
		}
		else if (Params.Type == EMedallionHydraProjectileType::Splitting || Params.Type == EMedallionHydraProjectileType::SplittingSetOffset)
		{
			CrumbLaunchSplittingProjectile(TargetLocation, ClosestTarget, Params.TargetPlayer);
		}
		else if (Params.Type == EMedallionHydraProjectileType::SplittingQuad)
		{
			CrumbLaunchSplittingProjectileQuad(TargetLocation, ClosestTarget, Params.TargetPlayer);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchBasicProjectile(FVector TargetLocation, ASanctuaryBossArenaHydraTarget ClosestTarget, AHazePlayerCharacter TargetPlayer)
	{
		FTransform ProjectileSpitTransform = Hydra.SkeletalMesh.GetSocketTransform(Hydra.SpitProjectileName);
		FVector LaunchLocation = ProjectileSpitTransform.Location;
		FVector ToTarget = TargetLocation - LaunchLocation;

		auto Projectile = SpawnActor(Hydra.BasicProjectileClass, LaunchLocation, ToTarget.ToOrientationRotator(), bDeferredSpawn = true);
		
		if (ClosestTarget != nullptr)
		{
			Projectile.FloatingPlatform = ClosestTarget.FloatingPlatform;
			Projectile.TargetActor = ClosestTarget;
		}

		Projectile.Hydra = Hydra;
		Projectile.TargetLocation = TargetLocation;	
		FinishSpawningActor(Projectile);

		{
			FSanctuaryBossMedallionHydraEventProjectileData Data;
			Data.MaybeActorTarget = ClosestTarget;
			Data.StartLocation = LaunchLocation;
			Data.MaybeTargetLocation = TargetLocation;
			Data.ProjectileType = EMedallionHydraProjectileType::Basic;
			Data.MaybeTargetPlayer = TargetPlayer;
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnShootProjectile(Hydra, Data);
		}
		{
			FSanctuaryBossMedallionManagerEventProjectileData Data;
			Data.MaybeActorTarget = ClosestTarget;
			Data.StartLocation = LaunchLocation;
			Data.MaybeTargetLocation = TargetLocation;
			Data.ProjectileType = EMedallionHydraProjectileType::Basic;	
			Data.Hydra = Hydra;
			Data.Projectile = Projectile;
			Data.MaybeTargetPlayer = TargetPlayer;
			UMedallionHydraAttackManagerEventHandler::Trigger_OnShootProjectile(RefsComp.Refs.HydraAttackManager, Data);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchSplittingProjectile(FVector TargetLocation, ASanctuaryBossArenaHydraTarget ClosestTarget, AHazePlayerCharacter TargetPlayer)
	{
		FTransform ProjectileSpitTransform = Hydra.SkeletalMesh.GetSocketTransform(Hydra.SpitProjectileName);
		FVector LaunchLocation = ProjectileSpitTransform.Location;
		FVector ToTarget = TargetLocation - LaunchLocation;
		auto Projectile = SpawnActor(Hydra.SplittingProjectileClass, LaunchLocation, ToTarget.ToOrientationRotator(), bDeferredSpawn = true);
		
		if (ClosestTarget != nullptr)
		{
			Projectile.FloatingPlatform = ClosestTarget.FloatingPlatform;
			Projectile.TargetActor = ClosestTarget;
		}

		Projectile.Hydra = Hydra;
		Projectile.TargetLocation = TargetLocation;	
		FinishSpawningActor(Projectile);

		{
			FSanctuaryBossMedallionHydraEventProjectileData Data;
			Data.MaybeActorTarget = ClosestTarget;
			Data.StartLocation = LaunchLocation;
			Data.MaybeTargetLocation = TargetLocation;
			Data.ProjectileType = EMedallionHydraProjectileType::Splitting;
			Data.MaybeTargetPlayer = TargetPlayer;
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnShootProjectile(Hydra, Data);
		}
		{
			FSanctuaryBossMedallionManagerEventProjectileData Data;
			Data.MaybeActorTarget = ClosestTarget;
			Data.StartLocation = LaunchLocation;
			Data.MaybeTargetLocation = TargetLocation;
			Data.ProjectileType = EMedallionHydraProjectileType::Splitting;
			Data.Hydra = Hydra;
			Data.Projectile = Projectile;
			Data.MaybeTargetPlayer = TargetPlayer;
			UMedallionHydraAttackManagerEventHandler::Trigger_OnShootProjectile(RefsComp.Refs.HydraAttackManager, Data);
		}
	}
	
	UFUNCTION(CrumbFunction)
	void CrumbLaunchSplittingProjectileQuad(FVector TargetLocation, ASanctuaryBossArenaHydraTarget ClosestTarget, AHazePlayerCharacter TargetPlayer)
	{
		FTransform ProjectileSpitTransform = Hydra.SkeletalMesh.GetSocketTransform(Hydra.SpitProjectileName);
		FVector LaunchLocation = ProjectileSpitTransform.Location;
		FVector ToTarget = TargetLocation - LaunchLocation;
		auto Projectile = SpawnActor(Hydra.QuadSplittingProjectileClass, LaunchLocation, ToTarget.ToOrientationRotator(), bDeferredSpawn = true);
		
		if (ClosestTarget != nullptr)
		{
			Projectile.FloatingPlatform = ClosestTarget.FloatingPlatform;
			Projectile.TargetActor = ClosestTarget;
		}

		Projectile.TargetLocation = TargetLocation;	
		Projectile.Hydra = Hydra;
		FinishSpawningActor(Projectile);

		{
			FSanctuaryBossMedallionHydraEventProjectileData Data;
			Data.MaybeActorTarget = ClosestTarget;
			Data.StartLocation = LaunchLocation;
			Data.MaybeTargetLocation = TargetLocation;
			Data.ProjectileType = EMedallionHydraProjectileType::SplittingQuad;
			Data.MaybeTargetPlayer = TargetPlayer;
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnShootProjectile(Hydra, Data);
		}
		{
			FSanctuaryBossMedallionManagerEventProjectileData Data;
			Data.MaybeActorTarget = ClosestTarget;
			Data.StartLocation = LaunchLocation;
			Data.MaybeTargetLocation = TargetLocation;
			Data.ProjectileType = EMedallionHydraProjectileType::SplittingQuad;
			Data.Hydra = Hydra;
			Data.Projectile = Projectile;
			Data.MaybeTargetPlayer = TargetPlayer;
			UMedallionHydraAttackManagerEventHandler::Trigger_OnShootProjectile(RefsComp.Refs.HydraAttackManager, Data);
		}
	}

	void LaunchFlyingProjectile(FMedallionHydraLaunchProjectileParams Params)
	{
		FTransform ProjectileSpitTransform = Hydra.SkeletalMesh.GetSocketTransform(Hydra.SpitProjectileName);
		FVector LaunchLocation = ProjectileSpitTransform.Location;

		FVector ToTarget = Params.TargetPlayer.ActorLocation - LaunchLocation;

		auto Projectile = SpawnActor(Hydra.FlyingProjectileClass, LaunchLocation, ToTarget.ToOrientationRotator(), bDeferredSpawn = true);

		Projectile.TargetPlayer = Params.TargetPlayer;
		Projectile.Hydra = Hydra;
		
		FinishSpawningActor(Projectile);

		{
			FSanctuaryBossMedallionHydraEventProjectileData Data;
			Data.StartLocation = LaunchLocation;
			Data.MaybeTargetPlayer = Params.TargetPlayer;
			Data.ProjectileType = EMedallionHydraProjectileType::Flying;
			Data.MaybeTargetPlayer = Params.TargetPlayer;
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnShootProjectile(Hydra, Data);
		}
		{
			FSanctuaryBossMedallionManagerEventProjectileData Data;
			Data.StartLocation = LaunchLocation;
			Data.MaybeTargetPlayer = Params.TargetPlayer;
			Data.ProjectileType = EMedallionHydraProjectileType::Flying;
			Data.Hydra = Hydra;
			Data.Projectile = Projectile;
			Data.MaybeTargetPlayer = Params.TargetPlayer;
			UMedallionHydraAttackManagerEventHandler::Trigger_OnShootProjectile(RefsComp.Refs.HydraAttackManager, Data);
		}
	}
	
	void LaunchRainProjectile(FMedallionHydraLaunchProjectileParams Params)
	{
		//Setup
		UHazeSplineComponent Spline = Hydra.Refs.SideScrollerSplineLocker.Spline;
		float PlayerSign = Params.TargetPlayer == Game::Mio ? 1.0 : -1.0;
		float PlayerSplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(Params.TargetPlayer.ActorLocation);
		float ProjectileSplineDistance = 0.0;

		FLinearColor DebugColor;
		bool bHasStartedRainProjectiles = false;
		if(!bHasStartedPlayerRainAttack[Params.TargetPlayer])
		{			
			FSanctuaryBossMedallionManagerEventPlayerAttackData EventParams;
			EventParams.AttackType = EMedallionHydraAttack::RainAttack;
			EventParams.Hydra = Hydra;
			EventParams.TargetPlayer = Params.TargetPlayer;

			UMedallionHydraAttackManagerEventHandler::Trigger_OnRainAttackStartFall(Hydra.Refs.HydraAttackManager, EventParams);
			bHasStartedPlayerRainAttack[Params.TargetPlayer] = true;
		}

		RainIndex += 1;

		if (RainIndex >= 4)
			RainIndex -= 4;

		if (RainIndex == 0)
		{
			UPlayerMovementComponent TargetPlayerMoveComp = UPlayerMovementComponent::Get(Params.TargetPlayer);
			FVector PlayerVelocity = TargetPlayerMoveComp.GetVelocity() * 2.0;
			float PredictedPlayerSplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(
				Params.TargetPlayer.ActorLocation + PlayerVelocity);

			ProjectileSplineDistance = PredictedPlayerSplineDistance;

			DebugColor = FLinearColor::Red;
		}
		if (RainIndex == 1)
		{
			ProjectileSplineDistance = PlayerSplineDistance + 
				Math::RandRange(-1000.0 * PlayerSign, 500.0 * PlayerSign);

			DebugColor = FLinearColor::Green;

		}
		if (RainIndex == 2)
		{
			ProjectileSplineDistance = PlayerSplineDistance + 
				Math::RandRange(500.0 * PlayerSign, 2000.0 * PlayerSign);

			DebugColor = FLinearColor::Purple;
		}
		if (RainIndex == 3)
		{
			ProjectileSplineDistance = PlayerSplineDistance + 
				Math::RandRange(2000.0 * PlayerSign, 3500.0 * PlayerSign);

			DebugColor = FLinearColor::Yellow;
		}

		if (Math::Abs(LastSplineDistance - ProjectileSplineDistance) < 300.0)
			ProjectileSplineDistance += 600.0;

		//Target Location
		float TargetSplineOffset = ProjectileSplineDistance - PlayerSplineDistance;
		float WaitDuration = Params.PredictedLocationOffset;

		CrumbLaunchRainProjectile(TargetSplineOffset, WaitDuration, Params.TargetPlayer);

		LastSplineDistance = ProjectileSplineDistance;

		//Debug::DrawDebugArrow(TargetLocation, TargetLocation - FVector::UpVector * 1000.0, 10.0, DebugColor, Duration = 5.0);
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchRainProjectile(float TargetSplineOffset, float WaitDuration, AHazePlayerCharacter TargetPlayer)
	{
		FTransform ProjectileSpitTransform = Hydra.SkeletalMesh.GetSocketTransform(Hydra.SpitProjectileName);
		FVector LaunchLocation = ProjectileSpitTransform.Location;
		AMedallionHydraRainProjectile Projectile = SpawnActor(Hydra.RainProjectileClass, LaunchLocation, bDeferredSpawn = true);
		Projectile.TargetSplineOffset = TargetSplineOffset;
		Projectile.WaitDuration = WaitDuration;
		Projectile.TargetPlayer = TargetPlayer;
		Projectile.Hydra = Hydra;
		FinishSpawningActor(Projectile);

		{
			FSanctuaryBossMedallionHydraEventProjectileData Data;
			Data.StartLocation = LaunchLocation;
			Data.ProjectileType = EMedallionHydraProjectileType::Rain;
			Data.MaybeTargetPlayer = TargetPlayer;
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnShootProjectile(Hydra, Data);
		}
		{
			FSanctuaryBossMedallionManagerEventProjectileData Data;
			Data.StartLocation = LaunchLocation;
			Data.ProjectileType = EMedallionHydraProjectileType::Rain;
			Data.Hydra = Hydra;
			Data.Projectile = Projectile;
			Data.MaybeTargetPlayer = TargetPlayer;
			UMedallionHydraAttackManagerEventHandler::Trigger_OnShootProjectile(RefsComp.Refs.HydraAttackManager, Data);
		}
	}

	void LaunchSpamProjectile(FMedallionHydraLaunchProjectileParams Params)
	{
		AHazePlayerCharacter TargetPlayer = Params.TargetPlayer;
		UHazeSplineComponent Spline = Hydra.Refs.SideScrollerSplineLocker.Spline;

		float SplineProgress = Spline.GetClosestSplineDistanceToWorldLocation(TargetPlayer.ActorCenterLocation);
		FVector ClosestSplineLocation = Spline.GetWorldLocationAtSplineDistance(SplineProgress);
		FVector TraceStart = ClosestSplineLocation;
		TraceStart.Z = TargetPlayer.ActorCenterLocation.Z;

		FVector TraceEnd = TraceStart;
		TraceEnd.Z -= 600.0;

		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		auto HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);

		bool bValidGroundTarget = HitResult.bBlockingHit;
		FVector TargetLocation;

		auto FloatingPlatform = Cast<ASanctuaryBossArenaFloatingPlatform>(HitResult.Actor);

		if (HitResult.bBlockingHit)
			TargetLocation = HitResult.ImpactPoint;
		else
			TargetLocation = TargetPlayer.ActorCenterLocation;

		CrumbLaunchSpamProjectile(bValidGroundTarget, TargetLocation, FloatingPlatform, Params.TargetPlayer);
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchSpamProjectile(bool bValidGroundTarget, FVector TargetLocation, ASanctuaryBossArenaFloatingPlatform FloatingPlatform, AHazePlayerCharacter TargetPlayer)
	{
		FTransform ProjectileSpitTransform = Hydra.SkeletalMesh.GetSocketTransform(Hydra.SpitProjectileName);

		auto Projectile = SpawnActor(Hydra.SpamProjectileClass, ProjectileSpitTransform.Location, ProjectileSpitTransform.Rotator(), bDeferredSpawn = true);
		Projectile.bValidGroundTarget = bValidGroundTarget;
		Projectile.FloatingPlatform = FloatingPlatform;
		Projectile.TargetLocation = TargetLocation;
		Projectile.Hydra = Hydra;
		FinishSpawningActor(Projectile);

		{
			FSanctuaryBossMedallionHydraEventProjectileData Data;
			Data.StartLocation = ProjectileSpitTransform.Location;
			Data.MaybeTargetLocation = TargetLocation;
			Data.ProjectileType = EMedallionHydraProjectileType::Spam;
			Data.MaybeTargetPlayer = TargetPlayer;
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnShootProjectile(Hydra, Data);
		}
		{
			FSanctuaryBossMedallionManagerEventProjectileData Data;
			Data.StartLocation = ProjectileSpitTransform.Location;
			Data.MaybeTargetLocation = TargetLocation;
			Data.ProjectileType = EMedallionHydraProjectileType::Spam;
			Data.Hydra = Hydra;
			Data.Projectile = Projectile;
			Data.MaybeTargetPlayer = TargetPlayer;
			UMedallionHydraAttackManagerEventHandler::Trigger_OnShootProjectile(RefsComp.Refs.HydraAttackManager, Data);
		}
	}

	void LaunchBallistaRainProjectile(FMedallionHydraLaunchProjectileParams Params)
	{
		ABallistaHydraSplinePlatform HitPlatform;
		FVector TargetCenterLocation = Params.TargetPlayer.ActorLocation;
		
		float ClosestDistance = Hydra.BallistaRefs.Refs.Spline.Spline.GetClosestSplineDistanceToWorldLocation(TargetCenterLocation);
		float DesiredSplineDistance = Math::Clamp(ClosestDistance - Params.PredictedLocationOffset, 0.0, Hydra.BallistaRefs.Refs.Spline.Spline.SplineLength);
		FVector ProjectileClosestSplineDesiredLocation = Hydra.BallistaRefs.Refs.Spline.Spline.GetWorldLocationAtSplineDistance(DesiredSplineDistance);

		
		const float RainMinMaxOffset = 1000;
		FVector ProjectileTargetLocation = ProjectileClosestSplineDesiredLocation;
		//ProjectileTargetLocation.X += Math::RandRange(-RainMinMaxOffset, RainMinMaxOffset);
		//ProjectileTargetLocation.Y += Math::RandRange(-RainMinMaxOffset, RainMinMaxOffset);

		//UPlayerMovementComponent TargetPlayerMoveComp = UPlayerMovementComponent::Get(Params.TargetPlayer);
		//FVector PlayerVelocity = TargetPlayerMoveComp.GetVelocity() * 3.0;

		ProjectileTargetLocation.Y = Params.TargetPlayer.ActorLocation.Y;
		//ProjectileTargetLocation.X += Math::Min(0.0, PlayerVelocity.X);
		ProjectileTargetLocation += Math::GetRandomPointInCircle_XY() * RainMinMaxOffset;

		if (Params.Type == EMedallionHydraProjectileType::BallistaRainOnPlayer)
			ProjectileTargetLocation = Params.TargetPlayer.ActorLocation;

		auto Trace = Trace::InitProfile(n"PlayerCharacter");

		const float TraceHalfLength = 10000;
		int Safety = 10;
		bool bSpawned = false;

		while (Safety > 0)
		{
			FHitResult Hit = Trace.QueryTraceSingle(ProjectileTargetLocation + FVector::UpVector * TraceHalfLength, ProjectileTargetLocation - FVector::UpVector * TraceHalfLength);
			if (!Hit.bBlockingHit)
			{
				float SplineDistanceOffset = DesiredSplineDistance - Hydra.BallistaRefs.Refs.Spline.LocalSplineDistance;
				FVector OffsetToSpline = ProjectileTargetLocation - ProjectileClosestSplineDesiredLocation;
				CrumbLaunchBallistaRainProjectile(ProjectileTargetLocation, nullptr, SplineDistanceOffset, OffsetToSpline - FVector::UpVector * 200.0, FVector::UpVector, Params.TargetPlayer);
				bSpawned = true;
				break;
			}
			else
			{
				HitPlatform = Cast<ABallistaHydraSplinePlatform>(Hit.Actor);
				if (HitPlatform != nullptr)
				{
					ASanctuaryHydraKillerBallista AttachedBallista = TryGetAttachedBallista(HitPlatform);
					FVector TargetInWorldSpace;
					if (AttachedBallista != nullptr)
						TargetInWorldSpace = GetOffsetFromBallista(AttachedBallista, Hit.ImpactPoint);
					else
						TargetInWorldSpace = Hit.ImpactPoint;
					FVector OffsetInPlatformSpace = HitPlatform.ActorTransform.InverseTransformPositionNoScale(TargetInWorldSpace);
					CrumbLaunchBallistaRainProjectile(ProjectileTargetLocation, HitPlatform, DesiredSplineDistance, OffsetInPlatformSpace, Hit.ImpactNormal, Params.TargetPlayer);
					bSpawned = true;
					break;
				}
				else
				{
					Trace.IgnoreActor(Hit.Actor);
				}
			}
			Safety--;
		}
		devCheck(bSpawned, "Hit more than 10 non-platform actors while trying to find a good spot to target with ballista projectile. Is that valid?");
	}

	private ASanctuaryHydraKillerBallista TryGetAttachedBallista(ABallistaHydraSplinePlatform Platform)
	{
		TArray<AActor> AttachedActors;
		Platform.GetAttachedActors(AttachedActors, true, false);
		if (!AttachedActors.IsEmpty())
		{
			for (auto AttachedActor : AttachedActors)
			{
				ASanctuaryHydraKillerBallista Ballista = Cast<ASanctuaryHydraKillerBallista>(AttachedActor);
				if (Ballista != nullptr)
					return Ballista;
			}
		}
		return nullptr;
	}
	
	private FVector GetOffsetFromBallista(ASanctuaryHydraKillerBallista Ballista, FVector TargetLocation)
	{
		bool bMioCloser = TargetLocation.Dist2D(Ballista.MioInteractComp.WorldLocation, FVector::UpVector) < TargetLocation.Dist2D(Ballista.ZoeInteractComp.WorldLocation, FVector::UpVector);
		FVector ClosestInteraction = bMioCloser ? Ballista.MioInteractComp.WorldLocation : Ballista.ZoeInteractComp.WorldLocation;
		float OffsetRadius = 500;
		if (TargetLocation.Dist2D(ClosestInteraction, Ballista.ActorUpVector) > OffsetRadius)
			return TargetLocation;

		// closest point on circle around point
		FVector ClosestOnPlane = Math::LinePlaneIntersection(TargetLocation + FVector::UpVector * 10000, TargetLocation - FVector::UpVector * 10000, ClosestInteraction, Ballista.ActorUpVector);
		FVector Direction = ClosestOnPlane - ClosestInteraction;
		FRotator RotatationTowardsOutside = FRotator::MakeFromZX(Ballista.ActorUpVector, Direction);
		FVector NewTargetLocation = ClosestInteraction + RotatationTowardsOutside.ForwardVector * OffsetRadius;
		FVector UpwardsOffset = Ballista.ActorUpVector * 50;
		if (SanctuaryBallistaHydraDevToggles::Draw::HydraProjectiles.IsEnabled())
		{
			Debug::DrawDebugSphere(ClosestOnPlane, 50, 12, ColorDebug::Magenta, 10, 10.0);
			Debug::DrawDebugCircle(ClosestInteraction + UpwardsOffset, OffsetRadius, 12, Hydra.DebugColor, 10, Ballista.ActorRightVector, Ballista.ActorForwardVector, false, 10.0, false);
			Debug::DrawDebugLine(TargetLocation + UpwardsOffset, NewTargetLocation + UpwardsOffset, ColorDebug::White, 10, 10.0, false);
		}
		return NewTargetLocation;
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchBallistaRainProjectile(FVector WorldLocationToRotateTowards, ABallistaHydraSplinePlatform TargetPlatform, float SplineDistanceOffset, FVector RelativeOffset, FVector DecalNormal, AHazePlayerCharacter TargetPlayer)
	{
		FTransform ProjectileSpitTransform = Hydra.SkeletalMesh.GetSocketTransform(Hydra.SpitProjectileName);
		FVector LaunchLocation = ProjectileSpitTransform.Location;
		FVector ToTarget = WorldLocationToRotateTowards - LaunchLocation;

		auto Projectile = SpawnActor(Hydra.BallistaProjectileClass, LaunchLocation, ToTarget.ToOrientationRotator(), bDeferredSpawn = true);
		if (TargetPlatform != nullptr)
		{
			Projectile.HitPlatformData.TargetPlatform = TargetPlatform;
			Projectile.HitPlatformData.OffsetInPlatformSpace = RelativeOffset;
			Projectile.HitPlatformData.DecalNormal = DecalNormal;
		}
		else
		{
			Projectile.HitWaterData.SplineDistanceOffset = SplineDistanceOffset;
			Projectile.HitWaterData.OffsetToSpline = RelativeOffset;		
		}
		Projectile.bIsHitPlatform = TargetPlatform != nullptr;
		Projectile.HydraShooter = Hydra;
		FinishSpawningActor(Projectile);

		{
			FSanctuaryBossMedallionHydraEventProjectileData Data;
			Data.StartLocation = ProjectileSpitTransform.Location;
			Data.MaybeActorTarget = TargetPlatform;
			Data.ProjectileType = EMedallionHydraProjectileType::BallistaRain;
			Data.MaybeTargetPlayer = TargetPlayer;
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnShootProjectile(Hydra, Data);
		}
		{
			FSanctuaryBossMedallionManagerEventProjectileData Data;
			Data.StartLocation = ProjectileSpitTransform.Location;
			Data.MaybeActorTarget = TargetPlatform;
			Data.ProjectileType = EMedallionHydraProjectileType::BallistaRain;
			Data.Hydra = Hydra;
			Data.Projectile = Projectile;
			Data.MaybeTargetPlayer = TargetPlayer;
			UMedallionHydraAttackManagerEventHandler::Trigger_OnShootProjectile(RefsComp.Refs.HydraAttackManager, Data);
		}
	}
};