struct FWalkerHeadFireSwoopDeactivationParams
{
	AHazePlayerCharacter NewTarget = nullptr;
}

class UIslandWalkerHeadFireSwoopBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	AIslandWalkerHead Character;
	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerAnimationComponent HeadAnimComp;
	UIslandWalkerFlameThrowerComponent Flamethrower;
	UIslandWalkerComponent SuspendComp;
	AIslandWalkerArenaLimits Arena;
	UIslandWalkerSettings Settings;

	AHazePlayerCharacter Target;

	bool bInitialTurn = true;
	bool bHasTelegraphed = false;
	bool bIsAttacking;
	bool bIsRecovering;
	FVector LastValidTargetLoc;
	TArray<AIslandWalkerFirewall> FireLines;
	AIslandWalkerHeadStumpTarget Stump;
	float TelegraphStartTime;
	float AttackStartTime;
	FVector SwoopDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Character = Cast<AIslandWalkerHead>(Owner);
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		HeadAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		Flamethrower = UIslandWalkerFlameThrowerComponent::Get(Owner);
		if (HeadComp.NeckCableOrigin != nullptr)
			SuspendComp = UIslandWalkerComponent::Get(HeadComp.NeckCableOrigin.Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		UIslandWalkerHeadStumpRoot::Get(Owner).OnStumpTargetSetup.AddUFunction(this, n"OnStumpSetup");

		UTargetTrailComponent::GetOrCreate(Game::Mio);
		UTargetTrailComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION()
	private void OnStumpSetup(AIslandWalkerHeadStumpTarget StumpTarget)
	{
		Stump = StumpTarget;
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
		if (TargetComp.Target.ActorLocation.IsWithinDist2D(Owner.ActorLocation, Settings.FireSwoopMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FWalkerHeadFireSwoopDeactivationParams& OutParams) const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > AttackStartTime + Settings.FireSwoopDuration + Settings.FireSwoopRecoverDuration)
		{
			if (TargetComp.IsValidTarget(Target.OtherPlayer))
				OutParams.NewTarget = Target.OtherPlayer; 
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Arena = UIslandWalkerComponent::Get(HeadComp.NeckCableOrigin.Owner).ArenaLimits;
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		bInitialTurn = true;
		bHasTelegraphed = false;
		bIsAttacking = false;
		bIsRecovering = false;
		FireLines.Reset();
		AttackStartTime = 10.0;
		TelegraphStartTime = BIG_NUMBER;
		UpdateTargetLocation();

		// Free flying 
		UMovementGravitySettings::SetGravityScale(Owner, 0.0, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FWalkerHeadFireSwoopDeactivationParams Params)
	{
		Super::OnDeactivated();
		Owner.ClearSettingsByInstigator(this);
		StopSprayingFire();
		Arena.EnableAllRespawnPoints(this);		
		
		if (Params.NewTarget != nullptr)
		{
			// Switch target and swap to matching shield if necessary
			TargetComp.SetTargetLocal(Params.NewTarget);
			if (Stump.ShieldBreaker == Params.NewTarget)
				Stump.SwapShieldBreaker();
		}

		if (TargetComp.HasValidTarget() && TargetComp.Target.ActorLocation.IsWithinDist2D(Owner.ActorLocation, Settings.FireSwoopMinRange * 1.2))
			Cooldown.Set(4.0); // Allow other behaviours time to reposition us

		if (bHasTelegraphed && !bIsAttacking)
			UIslandWalkerHeadEffectHandler::Trigger_OnFireSwoopTelegraphStop(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ShouldStartTelegraphing())
			TelegraphAttack();

		if (ShouldStopInitialTurn())
			bInitialTurn = false;

		if (ShouldUpdateTargetLocation())	
			UpdateTargetLocation();

		if (ShouldStartAttack() && HasControl())
			CrumbStartAttack();
		
		if (ShouldStopAttack())
			StartRecovery();

		FVector OwnLoc = Owner.ActorLocation;
		if (bInitialTurn)
		{
			// Turn towards last known target location
			DestinationComp.RotateInDirection(FRotator(-30.0, SwoopDirection.Rotation().Yaw, 0.0).Vector());

			// Swing away slowly before swooping forward
			FVector AwayLoc = GetSwoopLocation(OwnLoc - SwoopDirection.GetSafeNormal2D() * 1000.0);
			AwayLoc.Z += 400.0;
			DestinationComp.MoveTowardsIgnorePathfinding(AwayLoc, 500.0);
		}
		else if (!bIsRecovering)
		{
			// Swoop in towards target
			FVector SwoopLocation = GetSwoopLocation(OwnLoc + SwoopDirection * 1000.0);
			DestinationComp.RotateInDirection(FRotator(-30.0, SwoopDirection.Rotation().Yaw, 0.0).Vector());
			if (!Owner.ActorLocation.IsWithinDist2D(LastValidTargetLoc, 200.0))
			{
				FVector2D DistanceRange = FVector2D(Settings.FireSwoopMinRange, Settings.FireSwoopMinRange + Settings.FireSwoopMoveSpeed * 0.5);
				float Speed = Settings.FireSwoopMoveSpeed * Math::GetMappedRangeValueClamped(DistanceRange, FVector2D(0.25, 1.0), OwnLoc.Dist2D(LastValidTargetLoc));
				DestinationComp.MoveTowardsIgnorePathfinding(SwoopLocation, Speed);
			}
			
			if (bIsAttacking)
			{
				// Update where fire is sprayed
				FVector MovedSprayLoc = Flamethrower.TargetLocation + Owner.ActorVelocity.ProjectOnTo(SwoopDirection) * DeltaTime;
				Flamethrower.TargetLocation = Arena.GetAtArenaHeight(MovedSprayLoc);

				// In case spraying was interrupted, we always request this with low priority
				AnimComp.RequestFeature(FeatureTagWalker::HeadSprayGas, SubTagWalkerHeadSprayGas::Start, EBasicBehaviourPriority::Low, this);
			}
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
			else if (bInitialTurn)
				Debug::DrawDebugSphere(StateLoc, 100.0, 4, FLinearColor::LucBlue, 5.0);
			else
				Debug::DrawDebugSphere(StateLoc, 100.0, 4, FLinearColor::Yellow, 5.0);
		}
#endif	
	}

	void UpdateTargetLocation()
	{
		if (!Arena.IsWithinInnerEdge(Target.ActorLocation))
			LastValidTargetLoc = Target.ActorLocation;

		if (!LastValidTargetLoc.IsWithinDist2D(Owner.ActorLocation, Settings.FireSwoopMinRange * 0.9))
			SwoopDirection = (LastValidTargetLoc - Owner.ActorLocation).GetSafeNormal2D();
	}

	bool ShouldStartTelegraphing()
	{
		// Telegraph when reasonably close
		if (bHasTelegraphed)
			return false;
 		if (!Owner.ActorLocation.IsWithinDist2D(LastValidTargetLoc, Settings.FireSwoopMoveSpeed * 1.5))
			return false;
		return true;		
	}	

	bool ShouldStopInitialTurn()
	{
		// Turn until facing target
		if (!bInitialTurn)
			return false;
		if (ActiveDuration < Settings.FireSwoopInitialTurnDuration)
			return false;
		if (Owner.ActorForwardVector.DotProduct(SwoopDirection) < Math::Cos(Math::DegreesToRadians(Settings.FireSwoopInitialTurnAngleThreshold)))
			return false;
		return true;	
	}

	bool ShouldUpdateTargetLocation()
	{
		if (!TargetComp.IsValidTarget(Target))
			return false;
		if (bInitialTurn)
			return true;
		if (bIsAttacking)
			return false;
		if (bIsRecovering)
			return false;
		if (ActiveDuration > TelegraphStartTime + Settings.FireSwoopMaxTrackTargetDuration)
			return false; // Target has eluded us through good traversal, stop tracking
		return true;
	}

	bool ShouldStartAttack()
	{
		if (bInitialTurn)
			return false;
		if (bIsAttacking)
			return false;
		if (!Owner.ActorLocation.IsWithinDist(LastValidTargetLoc, Settings.FireSwoopSprayRange * 1.5))
			return false;
		return true;
	}

	bool ShouldStopAttack()
	{
		if (bInitialTurn)
			return false;
		if (!bIsAttacking)
			return false;
		if (bIsRecovering)
			return false;
		if (ActiveDuration < AttackStartTime + Settings.FireSwoopDuration)
			return false;
		return true;
	}

	FVector GetSwoopLocation(FVector Location)
	{
		FVector Loc = Location;
		Loc.Z = Arena.Height + Settings.FireSwoopHeight;
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

		FVector TargetLoc = Flamethrower.LaunchLocation + SwoopDirection * Settings.FireSwoopSprayRange * 0.5;
		Flamethrower.TargetLocation = Arena.GetAtArenaHeight(TargetLoc);
		Flamethrower.SpreadDirectionOverride = FVector::ZeroVector;

		UIslandWalkerHeadEffectHandler::Trigger_OnHeadChaseSprayFireStart(Owner, FIslandWalkerSprayFireParams(Flamethrower));
		UIslandWalkerHeadEffectHandler::Trigger_OnFireSwoopTelegraphStop(Owner);	

		FireLines.SetNum(1);
		for (int i = 0; i < FireLines.Num(); i++)
		{
			FireLines[i] = Cast<AIslandWalkerFirewall>(Flamethrower.Launch(Flamethrower.SprayDirection * Settings.FirewallSprayFuelSpeed).Owner);
			FireLines[i].StartSprayingFire(Owner, Flamethrower, Settings.FireSwoopDamagePerSecond, Settings.FireSwoopFloorBurnTime, Settings.FirewallDamageShenanigansHeight + 200.0);
		}

		Arena.DisableRespawnPointsAtSide(LastValidTargetLoc, this);		
	}

	void StartRecovery()
	{
		bIsRecovering = true;
		StopSprayingFire();
	}
}
