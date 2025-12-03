class UIslandWalkerHeadFireBreachingBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	AIslandWalkerHead Character;
	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerAnimationComponent HeadAnimComp;
	UIslandWalkerFlameThrowerComponent Flamethrower;
	UIslandWalkerComponent SuspendComp;
	UIslandWalkerSwimmingObstacleSetComponent ObstacleSet;
	AIslandWalkerArenaLimits Arena;
	UIslandWalkerSettings Settings;

	AHazePlayerCharacter Target;

	bool bBreaching = true;
	bool bHasTelegraphed = false;
	bool bIsAttacking;
	bool bIsRecovering;
	FVector LastValidTargetLoc;
	TArray<AIslandWalkerFirewall> FireLines;
	AIslandWalkerHeadStumpTarget Stump;
	float TelegraphStartTime;
	float AttackStartTime;
	FVector SwoopDirection;
	FVector SweepOffset = FVector::ZeroVector;
	bool bShouldSwapTarget = true;
	const float SwapTargetMaxTime = 5.0;
	bool bStartedSubmerged = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Character = Cast<AIslandWalkerHead>(Owner);
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		HeadAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		Flamethrower = UIslandWalkerFlameThrowerComponent::Get(Owner);
		if (HeadComp.NeckCableOrigin != nullptr)
		{
			SuspendComp = UIslandWalkerComponent::Get(HeadComp.NeckCableOrigin.Owner);
			UIslandWalkerPhaseComponent::Get(HeadComp.NeckCableOrigin.Owner).OnPhaseChange.AddUFunction(this, n"OnPhaseChange");
		}
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		UIslandWalkerHeadStumpRoot::Get(Owner).OnStumpTargetSetup.AddUFunction(this, n"OnStumpSetup");

		if (ensure(Owner.Level.LevelScriptActor != nullptr))
			ObstacleSet = UIslandWalkerSwimmingObstacleSetComponent::GetOrCreate(Owner.Level.LevelScriptActor);
		
		UTargetTrailComponent::GetOrCreate(Game::Mio);
		UTargetTrailComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION()
	private void OnPhaseChange(EIslandWalkerPhase NewPhase)
	{
		if (NewPhase == EIslandWalkerPhase::Swimming)
			Cooldown.Set(Settings.FireBreachingInitialCooldown);
	}

	UFUNCTION()
	private void OnStumpSetup(AIslandWalkerHeadStumpTarget StumpTarget)
	{
		Stump = StumpTarget;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (ShouldSwapTarget())
			CrumbSwapTarget(Target.OtherPlayer);
		if (DeactiveDuration > SwapTargetMaxTime)
			bShouldSwapTarget = false;
	}

	bool ShouldSwapTarget() const
	{
		if (!bShouldSwapTarget)
			return false;
		if (IsActive())
			return false;
		if (!HasControl())
			return false;
		if (Target == nullptr)
			return false;
		if (!TargetComp.IsValidTarget(Target.OtherPlayer))
			return false;
		if (DeactiveDuration > SwapTargetMaxTime) 
			return true;
		if ((Arena != nullptr) && (Arena.GetFloodedSubmergedDepth(Owner) > 200.0))
			return true;
		return false;
	}
	
	UFUNCTION(CrumbFunction)
	void CrumbSwapTarget(AHazePlayerCharacter NewTarget)
	{
		// Switch target and swap to matching shield if necessary
		bShouldSwapTarget = false;
		TargetComp.SetTargetLocal(NewTarget);
		if (Stump.ShieldBreaker == NewTarget)
			Stump.SwapShieldBreaker();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (SuspendComp == nullptr)
			return false;
		if (TargetComp.Target.ActorLocation.IsWithinDist2D(Owner.ActorLocation, Settings.FireBreachingMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > AttackStartTime + Settings.FireBreachingDuration + Settings.FireBreachingRecoverDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Arena = UIslandWalkerComponent::Get(HeadComp.NeckCableOrigin.Owner).ArenaLimits;
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		bBreaching = true;
		bHasTelegraphed = false;
		bIsAttacking = false;
		bIsRecovering = false;
		FireLines.Reset();
		AttackStartTime = 10.0;
		TelegraphStartTime = BIG_NUMBER;
		UpdateTargetLocation();
		bShouldSwapTarget = false;
		SweepOffset = FVector::ZeroVector;

		// Free flying 
		UMovementGravitySettings::SetGravityScale(Owner, 0.0, this, EHazeSettingsPriority::Gameplay);

		bStartedSubmerged = (Arena.GetFloodedSubmergedDepth(Owner) > 350.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		bShouldSwapTarget = true;

		Owner.ClearSettingsByInstigator(this);
		StopSprayingFire();
		Arena.EnableAllRespawnPoints(this);		
		
		if (ActiveDuration > 2.0)
			Cooldown.Set(Math::RandRange(0.8, 1.2) * Settings.FireBreachingCooldown); 

		if (bHasTelegraphed && !bIsAttacking)
			UIslandWalkerHeadEffectHandler::Trigger_OnFireSwoopTelegraphStop(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ShouldStartTelegraphing())
			TelegraphAttack();

		if (ShouldStopBreaching())
			bBreaching = false;

		if (ShouldUpdateTargetLocation())	
			UpdateTargetLocation();

		if (ShouldStartAttack() && HasControl())
			CrumbStartAttack();
		
		if (ShouldStopAttack())
			StartRecovery();

		FVector OwnLoc = Owner.ActorLocation;
		if (bBreaching)
		{
			// Turn towards last known target location
			DestinationComp.RotateInDirection(FRotator(-30.0, SwoopDirection.Rotation().Yaw, 0.0).Vector());

			// Rise out of the pool, but if obstructed first move towards center of pool
			if (IsObstructed(Owner.ActorLocation))
				DestinationComp.MoveTowardsIgnorePathfinding(Arena.GetAtFloodedPoolDepth(Arena.ActorLocation, Settings.SwimAroundObstructedDepth), Settings.SwimAroundSpeed);
			else if (Owner.ActorLocation.Z < Arena.FloodedPoolSurfaceHeight + Settings.FireBreachingHeight)
				DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + FVector(0.0, 0.0, 1000.0), Settings.FireBreachingAscendSpeed);
		}
		else if (!bIsRecovering)
		{
			// Swoop in near target
			FVector SwoopLocation = GetSwoopLocation(LastValidTargetLoc - SwoopDirection * Settings.FireBreachingSprayRange * 0.9);
			FVector2D DistanceRange = FVector2D(Settings.FireBreachingSprayRange, Settings.FireBreachingSprayRange * 2.0);
			float Speed = Settings.FireBreachingMoveSpeed * Math::GetMappedRangeValueClamped(DistanceRange, FVector2D(0.5, 1.0), OwnLoc.Dist2D(LastValidTargetLoc));
			DestinationComp.MoveTowardsIgnorePathfinding(SwoopLocation, Speed);

			if (bIsAttacking)
			{
				// Update where fire is sprayed
				FVector MovedSprayLoc = Flamethrower.TargetLocation + Owner.ActorVelocity.ProjectOnTo(SwoopDirection) * DeltaTime - SweepOffset;
				float Frequency = 2.0 * PI / Math::Max(Settings.FireBreachingDuration, 1.0);
				SweepOffset = Owner.ActorRightVector * Math::Sin((ActiveDuration - AttackStartTime) * Frequency) * Settings.FireBreachingSpraySweepAmplitude;
				Flamethrower.TargetLocation = Arena.GetAtFloodedPoolDepth(MovedSprayLoc + SweepOffset, 0.0);

				// In case spraying was interrupted, we always request this with low priority
				AnimComp.RequestFeature(FeatureTagWalker::HeadSprayGas, SubTagWalkerHeadSprayGas::Start, EBasicBehaviourPriority::Low, this);
			}

			FVector CenterDir = FRotator(-30.0, SwoopDirection.Rotation().Yaw, 0.0).Vector() * Settings.FireBreachingSprayRange;
			DestinationComp.RotateInDirection(CenterDir + SweepOffset);
		}
		else
		{
			// Stop and rest for a while
			DestinationComp.RotateInDirection(Owner.ActorForwardVector);
			AnimComp.RequestSubFeature(SubTagWalkerHeadSprayGas::End, this);
		}

		HeadComp.FireSwoopTargetLoc = LastValidTargetLoc;

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(OwnLoc, OwnLoc + SwoopDirection * 1000.0, FLinearColor::Red, 10.0);
			FVector StateLoc = OwnLoc + FVector(0.0, 0.0, 300.0) + Owner.ActorForwardVector * 400.0;
			if (bIsRecovering)
				Debug::DrawDebugSphere(StateLoc, 100.0, 4, FLinearColor::Green, 5.0);
			else if (bIsAttacking)
				Debug::DrawDebugSphere(StateLoc, 100.0, 4, FLinearColor::Red, 5.0);
			else if (bBreaching)
				Debug::DrawDebugSphere(StateLoc, 100.0, 4, FLinearColor::LucBlue, 5.0);
			else
				Debug::DrawDebugSphere(StateLoc, 100.0, 4, FLinearColor::Yellow, 5.0);
		}
#endif	
	}

	void UpdateTargetLocation()
	{
		LastValidTargetLoc = Target.ActorLocation;

		if (!LastValidTargetLoc.IsWithinDist2D(Owner.ActorLocation, Settings.FireBreachingMinRange * 0.9))
			SwoopDirection = (LastValidTargetLoc - Owner.ActorLocation).GetSafeNormal2D();
	}

	bool ShouldStartTelegraphing()
	{
		// Telegraph when reasonably close and above surface
		if (bHasTelegraphed)
			return false;
		if (Owner.ActorLocation.Z < Arena.FloodedPoolSurfaceHeight)
			return false;
 		if (!Owner.ActorLocation.IsWithinDist2D(LastValidTargetLoc, Settings.FireBreachingMoveSpeed * 1.5))
			return false;
		return true;		
	}	

	bool ShouldStopBreaching()
	{
		// Turn until facing target
		if (!bBreaching)
			return false;
		if (ActiveDuration < Settings.FireBreachingMinBreachingDuration)
			return false;
		if (Owner.ActorLocation.Z < Arena.FloodedPoolSurfaceHeight + Settings.FireBreachingHeight)
			return false;
		if (Owner.ActorForwardVector.DotProduct(SwoopDirection) < Math::Cos(Math::DegreesToRadians(Settings.FireBreachingAngleThreshold)))
			return false;
		return true;	
	}

	bool ShouldUpdateTargetLocation()
	{
		if (!TargetComp.IsValidTarget(Target))
			return false;
		if (bBreaching)
			return true;
		if (bIsAttacking)
			return false;
		if (bIsRecovering)
			return false;
		if (ActiveDuration > TelegraphStartTime + Settings.FireBreachingMaxTrackTargetDuration)
			return false; // Target has eluded us through good traversal, stop tracking
		return true;
	}

	bool ShouldStartAttack()
	{
		if (bBreaching)
			return false;
		if (bIsAttacking)
			return false;
		if (!Owner.ActorLocation.IsWithinDist(LastValidTargetLoc, Settings.FireBreachingSprayRange * 1.5))
			return false;
		return true;
	}

	bool ShouldStopAttack()
	{
		if (bBreaching)
			return false;
		if (!bIsAttacking)
			return false;
		if (bIsRecovering)
			return false;
		if (ActiveDuration < AttackStartTime + Settings.FireBreachingDuration)
			return false;
		return true;
	}

	FVector GetSwoopLocation(FVector Location)
	{
		FVector Loc = Location;
		Loc.Z = Arena.FloodedPoolSurfaceHeight + Settings.FireBreachingHeight;
		return Arena.ClampToArena(Loc);
	}

	void StopSprayingFire()
	{
		if (FireLines.Num() == 0)
			return;
		UIslandWalkerHeadEffectHandler::Trigger_OnHeadChaseSprayFireStop(Owner);
		for (AIslandWalkerFirewall FireLine : FireLines)
		{
			FireLine.StopSprayingFire(Settings.FirewallDissipateDuration);
		}
		FireLines.Reset();
	}

	void TelegraphAttack()
	{
		bHasTelegraphed = true;
		TelegraphStartTime = ActiveDuration;
		AnimComp.RequestFeature(FeatureTagWalker::HeadSprayGas, SubTagWalkerHeadSprayGas::Start, EBasicBehaviourPriority::Low, this);

		// If we started below the surface VO wants an event when we emerge.
		if (bStartedSubmerged) 
			UIslandWalkerHeadEffectHandler::Trigger_OnSneakyHeadSurfacing(Owner);

		UIslandWalkerHeadEffectHandler::Trigger_OnHeadChaseTelegraphFire(Owner, FIslandWalkerSprayFireParams(Flamethrower));
		UIslandWalkerHeadEffectHandler::Trigger_OnFireSwoopTelegraphStart(Owner);	
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartAttack()
	{
		bIsAttacking = true;
		AttackStartTime = ActiveDuration;

		if (!bHasTelegraphed)
			TelegraphAttack(); // Should only rarely happen in network

		FVector TargetLoc = Flamethrower.LaunchLocation + SwoopDirection * Settings.FireBreachingSprayRange * 0.5;
		Flamethrower.TargetLocation = Arena.GetAtFloodedPoolDepth(TargetLoc, 0.0);
		Flamethrower.SpreadDirectionOverride = FVector::ZeroVector;

		UIslandWalkerHeadEffectHandler::Trigger_OnHeadChaseSprayFireStart(Owner, FIslandWalkerSprayFireParams(Flamethrower));
		UIslandWalkerHeadEffectHandler::Trigger_OnFireSwoopTelegraphStop(Owner);	

		FireLines.SetNum(1);
		for (int i = 0; i < FireLines.Num(); i++)
		{
			FireLines[i] = Cast<AIslandWalkerFirewall>(Flamethrower.Launch(Flamethrower.SprayDirection * Settings.FirewallSprayFuelSpeed).Owner);
			FireLines[i].StartSprayingFire(Owner, Flamethrower, Settings.FireBreachingDamagePerSecond, Settings.FireBreachingFloorBurnTime, Settings.FirewallDamageShenanigansHeight + 1000.0);
		}

		Arena.DisableRespawnPointsAtSide(LastValidTargetLoc, this);		
	}

	void StartRecovery()
	{
		bIsRecovering = true;
		StopSprayingFire();
	}

	bool IsObstructed(FVector Loc)
	{
		if (ObstacleSet == nullptr)
			return false;
		for (UIslandWalkerSwimmingObstacleComponent Obstacle : ObstacleSet.Obstacles)
		{
			if (Obstacle.IsObstructing(Loc, Loc + Owner.ActorForwardVector))
				return true;	
		}
		return false;
	}
}
