struct FWalkerHeadFireChaseDeactivationParams
{
	AHazePlayerCharacter NewTarget = nullptr;
}

class UIslandWalkerHeadFireChaseBehaviour : UBasicBehaviour
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

	bool bInitialMove = true;
	bool bHasTelegraphed = false;
	FVector Destination;
	FVector ChaseDirection;
	FVector CurEdgeEnd;
	FVector CurEdgeStart;
	FVector LastValidTargetLoc;
	TArray<AIslandWalkerFirewall> FireLines;
	AIslandWalkerHeadStumpTarget Stump;
	float AttackStartTime;

	float StuckDuration;
	FVector StuckLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Character = Cast<AIslandWalkerHead>(Owner);
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		HeadAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		Flamethrower = UIslandWalkerFlameThrowerComponent::Get(Owner);
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
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FWalkerHeadFireChaseDeactivationParams& OutParams) const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > AttackStartTime + Settings.FireChaseDuration)
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
		LastValidTargetLoc = Target.ActorLocation;
		bInitialMove = true;
		bHasTelegraphed = false;
		FireLines.Reset();
		UpdateStartChaseDestination();
		AttackStartTime = 10.0;

		ResetStuck();

		// Free flying 
		UMovementGravitySettings::SetGravityScale(Owner, 0.0, this, EHazeSettingsPriority::Gameplay);
	}

	void UpdateStartChaseDestination()
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector EdgeStart, EdgeEnd;
		Arena.GetInnerEdge(LastValidTargetLoc, EdgeStart, EdgeEnd, Settings.FireChaseOutsidePoolOffset);
		ChaseDirection = (EdgeEnd - EdgeStart).GetSafeNormal2D();
		FVector TargetEdgeLoc = Math::ProjectPositionOnInfiniteLine(EdgeStart, ChaseDirection, LastValidTargetLoc);
		if (ChaseDirection.DotProduct(TargetEdgeLoc - OwnLoc) > 0.0)
		{
			// Chase forward along edge
			CurEdgeEnd = EdgeEnd + ChaseDirection * Settings.FireChaseOutsidePoolOffset;
			CurEdgeStart = EdgeStart - ChaseDirection * Settings.FireChaseOutsidePoolOffset;
		}
		else
		{
			// Chase backward along edge	
			ChaseDirection *= -1.0;
			CurEdgeEnd = EdgeStart + ChaseDirection * Settings.FireChaseOutsidePoolOffset;
			CurEdgeStart = EdgeEnd - ChaseDirection * Settings.FireChaseOutsidePoolOffset;
		}
		Destination = TargetEdgeLoc - ChaseDirection * Settings.FireChaseSprayRange * 2.0;
		Destination.Z = Arena.Height + Settings.FireChaseHeight;
		Destination = Arena.ClampToArena(Destination);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FWalkerHeadFireChaseDeactivationParams Params)
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		if (TargetComp.IsValidTarget(Target))
			LastValidTargetLoc = Target.ActorLocation;

		if (!bHasTelegraphed && OwnLoc.IsWithinDist2D(Destination, Settings.FireChaseMoveSpeed * 1.5))
			TelegraphAttack();

		if (bInitialMove && OwnLoc.IsWithinDist2D(Destination, Settings.FireChaseMoveSpeed * 0.5))
		{
			bInitialMove = false;
			if (ChaseDirection.DotProduct(LastValidTargetLoc - OwnLoc) < 0.0)
			{
				// Target has moved around to the other side of us
				ChaseDirection *= -1.0;
				FVector NewStart = CurEdgeEnd;
				CurEdgeEnd = CurEdgeStart;
				CurEdgeStart = NewStart;	
			}

			FVector SpreadDir = GetGasSpreadDirection(ChaseDirection, CurEdgeStart);
			FVector StartLoc = GetAdjustedSprayTargetLocation(Arena.GetAtArenaHeight(OwnLoc + ChaseDirection * Settings.FireChaseSprayRange), SpreadDir);
			if (HasControl())
				CrumbStartAttack(StartLoc, SpreadDir, ChaseDirection);
		}

		bool bMoving = false;

		if (bInitialMove)
		{
			// Move to starting chase position
			bMoving = true;
			DestinationComp.RotateTowards(LastValidTargetLoc + FVector(0.0, 0.0, 100.0));
		}
		else if (ActiveDuration < AttackStartTime + Settings.FireChaseDuration - Settings.FireChaseRecoverDuration)
		{
			// Chase around the pool dribbling gas as we go
			FVector OwnEdgeLoc = Math::ProjectPositionOnInfiniteLine(CurEdgeEnd, ChaseDirection, OwnLoc);
			Destination = OwnEdgeLoc + ChaseDirection * Settings.FireChaseOutsidePoolOffset;
			Destination.Z = Arena.Height + Settings.FireChaseHeight;

			// Check if we should turn onto next edge
			if (ChaseDirection.DotProduct(OwnEdgeLoc + ChaseDirection * Settings.FireChaseMoveSpeed - CurEdgeEnd) > 0.0)
			{
				FVector NextEdgeNearCenterLoc; 
				if (Math::Abs(ChaseDirection.DotProduct(Arena.ActorForwardVector)) > 0.7)
				{
					// Currently chasing along left or right edge, turn onto front or back edge	
					NextEdgeNearCenterLoc = Math::ProjectPositionOnInfiniteLine(Arena.ActorLocation, Arena.ActorForwardVector, Destination); 
				}
				else
				{
					// Currently chasing along front or back edge, turn onto left or right edge
					NextEdgeNearCenterLoc = Math::ProjectPositionOnInfiniteLine(Arena.ActorLocation, Arena.ActorRightVector, Destination); 
				}
				FVector NextEdgeStart; 
				FVector NextEdgeEnd;
				Arena.GetInnerEdge(NextEdgeNearCenterLoc, NextEdgeStart, NextEdgeEnd, Settings.FireChaseOutsidePoolOffset);
				if (NextEdgeStart.DistSquared(Destination) < NextEdgeEnd.DistSquared(Destination))
				{
					ChaseDirection = (NextEdgeEnd - NextEdgeStart).GetSafeNormal2D();
					CurEdgeEnd = NextEdgeEnd + ChaseDirection * Settings.FireChaseOutsidePoolOffset;
					CurEdgeStart = NextEdgeStart - ChaseDirection * Settings.FireChaseOutsidePoolOffset;
				}
				else
				{
					ChaseDirection = (NextEdgeStart - NextEdgeEnd).GetSafeNormal2D();
					CurEdgeEnd = NextEdgeStart + ChaseDirection * Settings.FireChaseOutsidePoolOffset;
					CurEdgeStart = NextEdgeEnd - ChaseDirection * Settings.FireChaseOutsidePoolOffset;
				} 

				// Update destination along the new edge
				Destination = Math::ProjectPositionOnInfiniteLine(CurEdgeEnd, ChaseDirection, OwnLoc) + ChaseDirection * Settings.FireChaseOutsidePoolOffset * 0.25;
				Destination.Z = Arena.Height + Settings.FireChaseHeight;

				// Update spread direction to cover the new arena side
				Flamethrower.SpreadDirectionOverride = GetGasSpreadDirection(ChaseDirection, OwnEdgeLoc); 

				Arena.DisableRespawnPointsAtSide((OwnLoc + Destination) * 0.5, this);		
			}

			bMoving = true;
			DestinationComp.RotateInDirection(FRotator(-30.0, ChaseDirection.Rotation().Yaw, 0.0).Vector());

			// Update where gas is sprayed
			FVector MovedSprayLoc = Flamethrower.TargetLocation + Owner.ActorVelocity.ProjectOnTo(ChaseDirection) * DeltaTime;
			Flamethrower.TargetLocation = GetAdjustedSprayTargetLocation(MovedSprayLoc, Flamethrower.SpreadDirection);
		
			// In case gas spraying was interrupted, we always request this with low priority
			AnimComp.RequestFeature(FeatureTagWalker::HeadSprayGas, SubTagWalkerHeadSprayGas::Start, EBasicBehaviourPriority::Low, this);
		}
		else
		{
			// Stop and rest for a while
			DestinationComp.RotateInDirection(Owner.ActorForwardVector);
			StopSprayingFire();
			AnimComp.RequestSubFeature(SubTagWalkerHeadSprayGas::End, this);
		}

		if (bMoving)
		{
			// Make sure we stay well above arena floor
			FVector CurDest = Destination;
			if (!Owner.ActorLocation.IsWithinDist(Destination, 200.0))
				CurDest = Owner.ActorLocation + (Destination - Owner.ActorLocation).GetSafeNormal() * 200.0;
			float FloorClearance = Arena.GetFloorLocation(CurDest).Z + 300.0;
			auto MoveComp = UHazeMovementComponent::Get(Owner);
			for (FMovementHitResult Impact : MoveComp.GetAllImpacts())
			{
				FloorClearance = Math::Max(FloorClearance, Impact.ImpactPoint.Z + 300.0);
			}

			// Check if we get stuck even if the above won't detect it
			if (Owner.ActorLocation.IsWithinDist(StuckLocation, 40.0))
				StuckDuration += DeltaTime;
			else
				ResetStuck();
			// If this gives jerky movement, keep this height for a while after be coming unstuck
			if (StuckDuration > 0.5)
				FloorClearance = Math::Max(Owner.ActorLocation.Z, FloorClearance) + 400.0 * StuckDuration;

			if (CurDest.Z < FloorClearance)
				CurDest.Z = FloorClearance;

			DestinationComp.MoveTowardsIgnorePathfinding(CurDest, Settings.FireChaseMoveSpeed);		
		}
		else
		{
			ResetStuck();
		}

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			if (ActiveDuration < AttackStartTime + Settings.FireChaseDuration - Settings.FireChaseRecoverDuration)
			{
				Debug::DrawDebugSphere(Destination, 100, 4, FLinearColor::Purple, 10);
				Debug::DrawDebugLine(CurEdgeStart, CurEdgeEnd, FLinearColor::Green, 5.0);
			}
		}
#endif	
	}

	void ResetStuck()
	{
		StuckDuration = 0.0;
		StuckLocation = Owner.ActorLocation;
	}

	FVector GetAdjustedSprayTargetLocation(FVector Loc, FVector OutwardsDir)
	{
		FVector AdjustedLoc = Math::ProjectPositionOnInfiniteLine(CurEdgeEnd, ChaseDirection, Loc);
		AdjustedLoc -= OutwardsDir * (Settings.FireChaseOutsidePoolOffset - Settings.FirewallDamageRadius * 0.5);
		return AdjustedLoc;
	}

	FVector GetGasSpreadDirection(FVector EdgeDir, FVector CurEdgeLoc)
	{
		FVector SpreadDir = EdgeDir.CrossProduct(FVector::UpVector);	
		if (SpreadDir.DotProduct(CurEdgeLoc - Arena.ActorLocation) < 0.0)
			SpreadDir *= -1.0; // Spread orthogonally away from pool
		return SpreadDir;
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
		AnimComp.RequestFeature(FeatureTagWalker::HeadSprayGas, SubTagWalkerHeadSprayGas::Start, EBasicBehaviourPriority::Low, this);

		UIslandWalkerHeadEffectHandler::Trigger_OnHeadChaseTelegraphFire(Owner, FIslandWalkerSprayFireParams(Flamethrower));
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartAttack(FVector StartLoc, FVector SpreadDirection, FVector ChaseDir)
	{
		AttackStartTime = ActiveDuration;
		ChaseDirection = ChaseDir;

		if (!bHasTelegraphed)
			TelegraphAttack(); // Should only rarely happen in network

		Flamethrower.TargetLocation = StartLoc;
		Flamethrower.SpreadDirectionOverride = SpreadDirection;

		UIslandWalkerHeadEffectHandler::Trigger_OnHeadChaseSprayFireStart(Owner, FIslandWalkerSprayFireParams(Flamethrower));

		FireLines.SetNum(4);
		for (int i = 0; i < FireLines.Num(); i++)
		{
			FireLines[i] = Cast<AIslandWalkerFirewall>(Flamethrower.Launch(Flamethrower.SprayDirection * Settings.FirewallSprayFuelSpeed).Owner);
			FireLines[i].ExtraOffset = i * Settings.FirewallDamageRadius - (Settings.FireChaseOutsidePoolOffset - Settings.FirewallDamageRadius);
			FireLines[i].StartSprayingFire(Owner, Flamethrower, Settings.FireChaseDamagePerSecond, Settings.FireChaseDangerZoneLength / Settings.FireChaseMoveSpeed, Settings.FirewallDamageShenanigansHeight);
		}

		Arena.DisableRespawnPointsAtSide(StartLoc + ChaseDirection * 1000.0, this);		
	}
}
