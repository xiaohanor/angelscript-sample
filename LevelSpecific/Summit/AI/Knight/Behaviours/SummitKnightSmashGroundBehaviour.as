class USummitKnightSmashGroundBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightSceptreComponent Sceptre;
	USummitKnightBladeComponent Blade;
	USummitKnightMobileCrystalBottom CrystalBottom;
	USummitKnightGenericAttackShockwaveLauncher Launcher;
	UBasicAIHealthComponent HealthComp;
	USummitKnightSettings Settings;

	AHazePlayerCharacter Target;
	AHazePlayerCharacter TrackingTarget;
	FVector Destination;
	FBasicAIAnimationActionDurations Durations;
	float TargetSpeed;
	FHazeAcceleratedFloat Speed;

	float RetractCrystalBottomTime;
	float DisallowStunTime;
	float DeployCrystalBottomTime;
	bool bHasCheckedMiss;
	bool bCheckTarget;

	bool bHasStartedSecondTelegraph = false;
	bool bHasStartedFirstSwing = false;
	bool bHasStartedSecondSwing = false;

	int NumTriggeredImpacts;
	TArray<FHazeAnimNotifyStateGatherInfo> TelegraphInfo; 
	TArray<FHazeAnimNotifyStateGatherInfo> ActionInfo; 

	TArray<AHazePlayerCharacter> DirectHitPlayers; 
	TArray<AHazePlayerCharacter> NearHitPlayers; 

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		KnightComp = USummitKnightComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);

		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		TArray<USummitKnightBladeComponent> Blades;
		Owner.GetComponentsByClass(Blades);
		Blade = Blades[0];

		CrystalBottom = USummitKnightMobileCrystalBottom::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);

		TArray<USummitKnightGenericAttackShockwaveLauncher> Launchers;
		Blade.GetChildrenComponentsByClass(USummitKnightGenericAttackShockwaveLauncher, true, Launchers);
		Launcher = Launchers[0];
		Launcher.PrepareProjectiles(2);
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
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal()) 
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		TrackingTarget = Target;
		bCheckTarget = false;
		Destination = GetDestination();

		Durations.Telegraph = Settings.SmashGroundTelegraphDuration;
		Durations.Anticipation = Settings.SmashGroundAnticipationDuration;
		Durations.Action = Settings.SmashGroundActionDuration;
		Durations.Recovery = Settings.SmashGroundRecoveryDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::SmashGround, NAME_None, Durations);
		AnimComp.RequestAction(SummitKnightFeatureTags::SmashGround, EBasicBehaviourPriority::Medium, this, Durations);

		NumTriggeredImpacts = 0;
		ActionInfo.Reset(2);
		UAnimSequence Anim = KnightAnimComp.GetRequestedAnimation(SummitKnightFeatureTags::SmashGround, NAME_None);
		if (ensure(Anim != nullptr))
		{
			Anim.GetAnimNotifyStateTriggerTimes(UBasicAIActionAnimNotify, ActionInfo);
			Anim.GetAnimNotifyStateTriggerTimes(UBasicAITelegraphingAnimNotify, TelegraphInfo);
		}

		bHasCheckedMiss = false;
		RetractCrystalBottomTime = Durations.Telegraph * 0.25;
		DisallowStunTime = RetractCrystalBottomTime + 0.5;
		DeployCrystalBottomTime = Durations.PreRecoveryDuration;

		bHasStartedFirstSwing = false;
		bHasStartedSecondSwing = false;
		bHasStartedSecondTelegraph = false;

		TargetSpeed = Owner.ActorLocation.Dist2D(Destination) / Math::Max(0.1, Durations.Anticipation);
		Speed.SnapTo(0.0);

		Sceptre.Unequip();
		Blade.Equip();

		CrystalBottom.Deploy(this);

		DirectHitPlayers.Reset(2);
		NearHitPlayers.Reset(2);

		USummitKnightSettings::SetRotationDuration(Owner, Settings.SmashGroundTurnDuration, this);

		USummitKnightEventHandler::Trigger_OnSmashGroundAggroFirstTelegraph(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		KnightComp.bCanBeStunned.Clear(this);
		CrystalBottom.Deploy(this);
		Owner.ClearSettingsByInstigator(this);

		// Switch target
		if (Target != nullptr)
			TargetComp.SetTarget(Target.OtherPlayer);

		if (HasControl() && (NumTriggeredImpacts < ActionInfo.Num()) && HealthComp.IsStunned())
			CrumbAborted(); // We can only be aborted by tail dragon attack causing stun

		USummitKnightEventHandler::Trigger_OnSmashGroundEnd(Owner);
	}

	FVector GetDestination()
	{
		FVector Dest = Target.ActorLocation + (Owner.ActorLocation - Target.ActorLocation).GetSafeNormal2D() * Settings.SmashGroundReachToTarget;
		return KnightComp.Arena.GetClampedToArena(Dest, 800.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActionInfo.IsValidIndex(NumTriggeredImpacts) && TelegraphInfo.IsValidIndex(NumTriggeredImpacts))
		{
			// Track target, then move to destination and slam sword down upon them
			if (IsInTelegraphRange(ActiveDuration, NumTriggeredImpacts))
			{
				CheckSwitchTarget();

				DestinationComp.RotateTowards(TrackingTarget);		
				if (NumTriggeredImpacts == 0)	
					Destination = GetDestination();
			}

			if(!bHasStartedSecondTelegraph && NumTriggeredImpacts > 0 && ActiveDuration >= (TelegraphInfo[NumTriggeredImpacts].TriggerTime))
			{
				bHasStartedSecondTelegraph = true;
				USummitKnightEventHandler::Trigger_OnSmashGroundAggroFinalTelegraph(Owner);
			}

			if ((NumTriggeredImpacts == 0) && Durations.IsInAnticipationRange(ActiveDuration))
			{
				Speed.AccelerateTo(TargetSpeed, Durations.Anticipation * 0.25, DeltaTime);
				if (!Destination.IsWithinDist2D(Owner.ActorLocation, 400.0))
					DestinationComp.MoveTowardsIgnorePathfinding(Destination, Speed.Value);
			}
			else
			{
				USummitKnightSettings::SetFriction(Owner, 20.0, this);			
			}

			// Pre-fire events for juicyness
			if(!bHasStartedFirstSwing && IsInFirstSwingRange())
			{
				USummitKnightEventHandler::Trigger_OnSmashGroundAggroFirstImpact(Owner);
				bHasStartedFirstSwing = true;
			}
			if(!bHasStartedSecondSwing && IsInSecondSwingRange())
			{
				USummitKnightEventHandler::Trigger_OnSmashGroundAggroFinalImpact(Owner);
				bHasStartedSecondSwing = true;
			}

			if (IsInActionRange(ActiveDuration, NumTriggeredImpacts))
			{
				NumTriggeredImpacts++;
				FVector BladeDir = (Blade.TipLocation - Blade.HiltLocation).GetSafeNormal2D();
				if (HasControl())
					CrumbLaunchShockwave(Blade.TipLocation, BladeDir);	

				FVector HiltLoc = KnightComp.Arena.GetAtArenaHeight(Blade.HiltLocation);
				FVector TipLoc = KnightComp.Arena.GetAtArenaHeight(HiltLoc + BladeDir * Blade.BladeLength); // Ensure we get full length along arena even if animnotify is slightly misplaced
				FVector BaseLoc = KnightComp.Arena.GetAtArenaHeight(Owner.ActorLocation + Owner.ActorForwardVector * 500.0);
				float OuterBaseRadius = Settings.SmashGroundBaseRadius + Settings.SmashGroundHitOuterBuffer;
				float OuterTipRadius = Settings.SmashGroundTipRadius + Settings.SmashGroundHitOuterBuffer;
				for (AHazePlayerCharacter Player : Game::Players)
				{
					if (!Player.HasControl())
						continue;
					if (Player.ActorLocation.Z > Owner.ActorLocation.Z + 1000.0)
						continue;
					FVector PlayerArenaLoc = KnightComp.Arena.GetAtArenaHeight(Player.ActorLocation);
					if (!PlayerArenaLoc.IsInsideTeardrop2D(BaseLoc, TipLoc, OuterBaseRadius, OuterTipRadius))
						continue;

					bool bDirectHit = PlayerArenaLoc.IsInsideTeardrop2D(BaseLoc, TipLoc, Settings.SmashGroundBaseRadius, Settings.SmashGroundTipRadius);				
					CrumbHitPlayer(Player, bDirectHit);
				}
				KnightComp.SmashObstaclesInTeardrop(BaseLoc, TipLoc, OuterBaseRadius, OuterTipRadius);					
			}
		}

		if (ActiveDuration > RetractCrystalBottomTime)		
		{
			RetractCrystalBottomTime = BIG_NUMBER;
			CrystalBottom.Retract(this);
		}
		if (ActiveDuration > DisallowStunTime)
		{
			DisallowStunTime = BIG_NUMBER;
			KnightComp.bCanBeStunned.Apply(false, this);
		}
		if (ActiveDuration > DeployCrystalBottomTime)
		{
			DeployCrystalBottomTime = BIG_NUMBER;
			KnightComp.bCanBeStunned.Clear(this);
			CrystalBottom.Deploy(this);
		}

		if (!bHasCheckedMiss && Durations.IsInRecoveryRange(ActiveDuration))
		{
			bHasCheckedMiss = true;
			if ((DirectHitPlayers.Num() == 0) && (NearHitPlayers.Num() == 0))
				USummitKnightEventHandler::Trigger_OnSmashGroundAggroMiss(Owner);
		}

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			if (Durations.IsInActionRange(ActiveDuration))
			{
				FVector Offset = FVector(0,0,50);
				FVector TipLoc = KnightComp.Arena.GetAtArenaHeight(Blade.TipLocation) + Offset;
				FVector BaseLoc = KnightComp.Arena.GetAtArenaHeight(Owner.ActorLocation + Owner.ActorForwardVector * 500.0) + Offset;
				ShapeDebug::DrawTeardrop(TipLoc, BaseLoc, Settings.SmashGroundTipRadius + Settings.SmashGroundHitOuterBuffer, Settings.SmashGroundBaseRadius + Settings.SmashGroundHitOuterBuffer, FLinearColor::Yellow, 20);
				ShapeDebug::DrawTeardrop(TipLoc, BaseLoc, Settings.SmashGroundTipRadius, Settings.SmashGroundBaseRadius, FLinearColor::Red, 20);
				ShapeDebug::DrawTeardrop(TipLoc + Offset * 20, BaseLoc + Offset * 20, Settings.SmashGroundTipRadius, Settings.SmashGroundBaseRadius, FLinearColor::Red, 20);
			}
		}
#endif
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchShockwave(FVector Location, FVector Direction)
	{
		UBasicAIProjectileComponent Projectile = Launcher.Launch(Direction * Settings.GenericAttackShockwaveMoveSpeed);
		Cast<ASummitKnightGenericAttackShockwave>(Projectile.Owner).LaunchLocal(Location, Owner);
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitPlayer(AHazePlayerCharacter Player, bool bDirectHit)
	{
		UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Player);
		float Damage = Settings.SmashGroundDamage;
		if (!bDirectHit)
			Damage = Math::Min(Damage, PlayerHealthComp.Health.CurrentHealth * 0.8);	// Don't kill in outer layer of danger zone
		Player.DealTypedDamage(Owner, Damage, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge, false);
		if (Player.IsPlayerDead())
			CrumbDeathFromSmash(Player);
		
		FVector TipLoc = KnightComp.Arena.GetAtArenaHeight(Blade.TipLocation);
		FVector BaseLoc = KnightComp.Arena.GetAtArenaHeight(Owner.ActorLocation + Owner.ActorForwardVector * 500.0);
		FVector PlayerArenaLoc = KnightComp.Arena.GetAtArenaHeight(Player.ActorLocation);
		FVector LineLoc;
		float Dummy;
		Math::ProjectPositionOnLineSegment(BaseLoc, TipLoc, PlayerArenaLoc, LineLoc, Dummy);
		FVector StumbleDir = (PlayerArenaLoc - LineLoc).GetNormalized2DWithFallback(-Player.ActorForwardVector);
		KnightComp.StumbleDragon(Player, StumbleDir * Settings.SmashGroundStumbleDistance, 0.0, 0.5, 200.0);				

		// Note that damage and stumble above is in turn crumb synced, so this is really the only part which is affected by crumbing the hit
		if (bDirectHit)
		{
			DirectHitPlayers.AddUnique(Player);
			USummitKnightEventHandler::Trigger_OnSmashGroundAggroDirectHit(Owner, FSummitKnightPlayerParams(Player));
			if (DirectHitPlayers.Num() == 2)
				USummitKnightEventHandler::Trigger_OnSmashGroundAggroDirectHitBoth(Owner);
		}
		else
		{
			NearHitPlayers.AddUnique(Player);
			USummitKnightEventHandler::Trigger_OnSmashGroundAggroNearHit(Owner, FSummitKnightPlayerParams(Player));
		}

		// At start of next telegraph, check if we should switch target
		bCheckTarget = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbDeathFromSmash(AHazePlayerCharacter Player)
	{
		KnightComp.bDeathCouldHaveBeenDashAvoided[Player] = true; 
	}

	void CheckSwitchTarget()
	{
		if (!bCheckTarget)
			return;

		// Switch to the other player if current target is dead or outside arena
		bCheckTarget = false;
		if (!TargetComp.IsValidTarget(TrackingTarget.OtherPlayer))
			return; // ...also other player needs to be a valid target

		if (TargetComp.IsValidTarget(TrackingTarget))
		{
			if (KnightComp.Arena.IsInsideArena(TrackingTarget.ActorLocation, 100.0, 1000.0))
				return; // Stay with current target	
		}

		// Switch target!
		TrackingTarget = TrackingTarget.OtherPlayer; 
	}

	bool IsInTelegraphRange(float Time, int Index) const
	{
		if (Time < TelegraphInfo[Index].TriggerTime)
			return false;
		if (Time > TelegraphInfo[Index].TriggerTime + TelegraphInfo[Index].Duration)
			return false;
		return true;
	}

	bool IsInActionRange(float Time, int Index) const
	{
		if (Time < ActionInfo[Index].TriggerTime)
			return false;
		if (Time > ActionInfo[Index].TriggerTime + ActionInfo[Index].Duration)
			return false;
		return true;
	}

	bool IsInFirstSwingRange() const
	{
		return NumTriggeredImpacts == 0 && ActiveDuration >= (TelegraphInfo[NumTriggeredImpacts].Duration - 0.3);
	}

	bool IsInSecondSwingRange() const
	{
		return NumTriggeredImpacts > 0 && (ActiveDuration - TelegraphInfo[0].Duration) >= (TelegraphInfo[NumTriggeredImpacts].TriggerTime - 0.3);
	}

	UFUNCTION(CrumbFunction)
	void CrumbAborted()
	{
		USummitKnightEventHandler::Trigger_OnSmashGroundAborted(Owner);
	}
}

