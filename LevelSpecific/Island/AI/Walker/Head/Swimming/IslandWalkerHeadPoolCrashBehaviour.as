class UIslandWalkerHeadPoolCrashBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerAnimationComponent HeadAnimComp;
	UHazeSkeletalMeshComponentBase Mesh;
	UHazeCapsuleCollisionComponent Collision;
	UHazeMovementComponent MoveComp;
	UIslandWalkerHeadHatchRoot HatchRoot;
	UIslandWalkerHeadHatchShootablePanel ShootablePanel;
	AIslandWalkerArenaLimits Arena;
	AIslandWalkerHeadStumpTarget Stump;
	UIslandWalkerSettings Settings;

	float StartRecoveringTime;
	bool bCrashed;
	bool bRecovering;
	bool bHitAcidSurface;
	bool bHasReachedHeadExtraDuration;
	bool bHasInteractStartExtraDuration;

	float AttackStartTime;
	float ShockWaveTime;
	float RelaxTime;
	int iShockwave = 0;
	TArray<float> ShockwaveDelays;
	float ShockwaveRecovery;

	TArray<AIslandWalkerHeadCrashSite> AvailableSites;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		HeadAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		AHazeCharacter CharOwner = Cast<AHazeCharacter>(Owner);
		Mesh = CharOwner.Mesh;
		Collision = CharOwner.CapsuleComponent;
		ShootablePanel = UIslandWalkerHeadHatchShootablePanel::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		UIslandWalkerHeadStumpRoot::Get(Owner).OnStumpTargetSetup.AddUFunction(this, n"OnStumpSetup");
		HatchRoot = UIslandWalkerHeadHatchRoot::Get(Owner);
		HeadComp.SpawnShockWaves();
		DevTogglesWalker::SlowCrashRecovery.MakeVisible();

		for (AIslandWalkerHeadCrashSite Site : TListedActors<AIslandWalkerHeadCrashSite>())
		{
			if (Site.bUsedWhenAcidPoolFlooded)
				AvailableSites.Add(Site);
		}
	}

	UFUNCTION()
	private void OnStumpSetup(AIslandWalkerHeadStumpTarget Target)
	{
		Stump = Target;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Stump == nullptr)
			return false;
		if (Stump.Health > Settings.HeadSwimmingCrashHealthThreshold)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > StartRecoveringTime + Settings.HeadCrashRecoverDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bCrashed = false;
		bRecovering = false;
		bHitAcidSurface = false;

		HeadComp.CrashDuration = 4.0;
		UAnimSequence CrashAnim = HeadAnimComp.GetRequestedAnimation(FeatureTagWalker::HeadCrash, SubTagWalkerHeadCrash::FallDown);
		if (CrashAnim != nullptr)
			HeadComp.CrashDuration = CrashAnim.GetAnimNotifyStateStartTime(UBasicAIActionAnimNotify);

		Arena = UIslandWalkerComponent::Get(HeadComp.NeckCableOrigin.Owner).ArenaLimits;
		AnimComp.RequestFeature(FeatureTagWalker::HeadCrash, SubTagWalkerHeadCrash::FallDown, EBasicBehaviourPriority::High, this);
		StartRecoveringTime = HeadComp.CrashDuration + Settings.HeadCrashStayDuration;

		if (DevTogglesWalker::SlowCrashRecovery.IsEnabled())
			StartRecoveringTime += 30.0;			

		bHasReachedHeadExtraDuration = false;
		bHasInteractStartExtraDuration = false;
		
		FVector IdealCrashLoc = Owner.ActorLocation;
		IdealCrashLoc += Owner.ActorVelocity * HeadComp.CrashDuration * 0.5;
		IdealCrashLoc += Owner.ActorForwardVector * 2000.0;
		IdealCrashLoc = Arena.GetAtArenaHeight(IdealCrashLoc);
		HeadComp.CrashSite = nullptr;
		float ClosestDistSqr = BIG_NUMBER;
		for (AIslandWalkerHeadCrashSite Site : AvailableSites)
		{
			if (Site.HasNearbyPlayer(400.0))
				continue; // Disqualify sites which are too close to a player	
			float DistSqr = Site.Center.DistSquared2D(IdealCrashLoc);
			if (DistSqr > ClosestDistSqr)
				continue;
			HeadComp.CrashSite = Site;
			ClosestDistSqr = DistSqr;	
		}
		HeadComp.CrashDestination = IdealCrashLoc;
		if (HeadComp.CrashSite != nullptr)
			HeadComp.CrashDestination = HeadComp.CrashSite.GetCrashLocation(IdealCrashLoc); 

		// Never fall too far below pool surface
		HeadComp.MovementFloor.Apply(Arena.GetFloodedPoolSurfaceHeight() - 800.0, this);

		UMovementGravitySettings::SetGravityScale(Owner, 0.0, this, EHazeSettingsPriority::Script);
		UIslandWalkerSettings::SetHeadWobbleAmplitude(Owner, FVector::ZeroVector, this, EHazeSettingsPriority::Gameplay);
		UIslandWalkerSettings::SetHeadWobbleRollAmplitude(Owner, 0.0, this, EHazeSettingsPriority::Gameplay);

		Stump.Health = Settings.HeadSwimmingCrashHealthThreshold;
		Stump.HealthBarComp.ModifyHealth(Stump.Health);
		Stump.ForceFieldComp.PowerDown();
		Stump.IgnoreDamage();

		// Note that we need never hide this again
		ShootablePanel.Show();

		if (Settings.bHeadSwimmingCrashAllowAttacks)
			AttackStartTime = HeadComp.CrashDuration + Settings.HeadCrashAttackInitialPause;	
		else
			AttackStartTime = BIG_NUMBER;
		ShockWaveTime = BIG_NUMBER;
		RelaxTime = BIG_NUMBER;
		iShockwave = 0;
		UAnimSequence AttackAnim = HeadAnimComp.GetRequestedAnimation(FeatureTagWalker::HeadCrash, SubTagWalkerHeadCrash::Attack);
		ShockwaveDelays.Reset(3);
		TArray<FHazeAnimNotifyStateGatherInfo> Actions;
		if ((AttackAnim == nullptr) || !AttackAnim.GetAnimNotifyStateTriggerTimes(UBasicAIActionAnimNotify, Actions))
		{
			ShockwaveDelays.Add(1.0);
			ShockwaveRecovery = 0.0;
		}
		else
		{
			float PrevTime = 0.0;
			for (FHazeAnimNotifyStateGatherInfo Action : Actions)
			{
				ShockwaveDelays.Add(Action.TriggerTime - PrevTime);
				PrevTime = Action.TriggerTime;	
			}			
			ShockwaveRecovery = AttackAnim.ScaledPlayLength - Actions.Last().TriggerTime;
		}

		// Up walkable slope angle for players so we won't slide off easily when on head and it's bucking about. 
		// TODO: Should properly be only when near or if possible only against head.
		UMovementStandardSettings::SetWalkableSlopeAngle(Game::Mio, 85.0, this, EHazeSettingsPriority::Gameplay);
		UMovementStandardSettings::SetWalkableSlopeAngle(Game::Zoe, 85.0, this, EHazeSettingsPriority::Gameplay);

		UIslandWalkerHeadEffectHandler::Trigger_OnStoppedFlying(Owner);
		UIslandWalkerHeadEffectHandler::Trigger_OnStartCrashing(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HeadComp.CrashSite = nullptr;
		Owner.ClearSettingsByInstigator(this);
		Game::Mio.ClearSettingsByInstigator(this);
		Game::Zoe.ClearSettingsByInstigator(this);
		HeadComp.MovementFloor.Clear(this);

		if (!Stump.bStumpDestroyed)
		{
			if (bRecovering)
			{
				// We shook off players before they got a chance to start dealing damage through hatch
				Stump.Health += Settings.HeadCrashRecoverHealth;
				Stump.HealthBarComp.ModifyHealth(Stump.Health);
			}
			Stump.AllowDamage();

			if (!bRecovering)
			{
				// Escape flight or some other forced exit of behaviour
				Stump.ForceFieldComp.PowerUp();
				Stump.ReigniteThrusters();
				UIslandWalkerHeadEffectHandler::Trigger_OnStartedFlying(Owner);
			}
		}
		HeadComp.bHeadShakeOffPlayers = false;

		HatchRoot.DisablePerches();
		HatchRoot.DisableInteracts();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bCrashed && (ActiveDuration > HeadComp.CrashDuration))
		{
			bCrashed = true;
			HatchRoot.EnablePerches();
			HatchRoot.EnableInteracts();
			HeadComp.bHeadShakeOffPlayers = false;
			
			// Swap force field colour now when field is down
			Stump.SwapShieldBreaker();

			UIslandWalkerHeadEffectHandler::Trigger_OnCrashLanding(Owner);
		}

		if (HasControl() && !bRecovering && (ActiveDuration > StartRecoveringTime) && !Stump.bStumpDestroyed)
			CrumbStartRecovering();
		if (bRecovering)
		{
			// Continue recovery, moving up to attack height
			DestinationComp.MoveTowardsIgnorePathfinding(Arena.GetAtArenaHeight(Owner.ActorLocation) + FVector(0.0, 0.0, Settings.FireChaseHeight), 1300.0);
		}
		else if (bCrashed)
		{
			if (!bHasReachedHeadExtraDuration && PlayerIsAtHead())
			{
				bHasReachedHeadExtraDuration = true;
				StartRecoveringTime += Settings.HeadCrashRecoverAtHeadExtraDuration;
			}

			if (!bHasInteractStartExtraDuration && PlayerIsInteracting())
			{
				bHasInteractStartExtraDuration = true;
				StartRecoveringTime += Settings.HeadCrashRecoverInteractedExtraDuration;
			}
		}

		// Start flying along escape spline when anyone starts shooting before we recover
		bool bShooting = false;
		bool bOpening = false;
		for (UIslandWalkerHeadHatchInteractionComponent Comp : HatchRoot.HatchInteractComps)
		{
			if (Comp.State == EWalkerHeadHatchInteractionState::Shooting)
				bShooting = true;	
			else if (Comp.State == EWalkerHeadHatchInteractionState::Opening)
				bOpening = true;
		}
		if (bShooting && HasControl() && !bRecovering)
			CrumbEscape();
	
		// When we've started opening hatch, we delay recovery at least until we've had a chance to see shoot tutorial icon
		if (bOpening)
			StartRecoveringTime = Math::Max(StartRecoveringTime, ActiveDuration + Settings.HatchShowShootTutorialDelay + 2.0);

		if (!bHitAcidSurface && (Arena.GetFloodedSubmergedDepth(Owner) > -80.0))
		{
			bHitAcidSurface = true;
			FIslandWalkerPoolSurfaceParams EffectParams;
			EffectParams.SurfaceLocation = Arena.GetAtFloodedPoolDepth(Owner.ActorLocation + Owner.ActorForwardVector * 350.0, 0.0);
			UIslandWalkerHeadEffectHandler::Trigger_OnCrashThroughAcidSurface(Owner, EffectParams);
		}	

		if (bCrashed && !bRecovering && !bShooting)
		{
			// Allow attacks
			if (HasControl() && (ActiveDuration > AttackStartTime) && (ActiveDuration + 2.0 < StartRecoveringTime))
				CrumbStartAttack();
			if (ActiveDuration > ShockWaveTime)
				LaunchShockwave();
			if (ActiveDuration > RelaxTime)
			{
				RelaxTime = BIG_NUMBER;
				AnimComp.RequestSubFeature(SubTagWalkerHeadCrash::StayCrashed, this);
			}
		}		

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(HeadComp.CrashDestination, HeadComp.CrashDestination + FVector(0.0, 0.0, 200.0), FLinearColor::Blue, 5.0);
			Debug::DrawDebugLine(HeadComp.CrashDestination, Owner.ActorLocation, FLinearColor::Blue, 2.0);
		}
#endif
	}

	bool PlayerIsAtHead()
	{
		FVector TopLocation = Owner.ActorLocation + FVector(0.0, 0.0, 100.0) + Owner.ActorForwardVector * 300.0;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.ActorLocation.IsWithinDist(TopLocation, 350.0))
				return true;
		}
		return false;
	}

	bool PlayerIsInteracting()
	{
		for (UIslandWalkerHeadHatchInteractionComponent Comp : HatchRoot.HatchInteractComps)
		{
			if (Comp.State != EWalkerHeadHatchInteractionState::None)
				return true;	
		}
		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartRecovering()
	{
		// Start recovery
		bRecovering = true;
		HeadComp.CrashSite = nullptr;
		AnimComp.RequestSubFeature(SubTagWalkerHeadCrash::Recover, this);
		Owner.ClearSettingsByInstigator(this);
		Stump.ForceFieldComp.PowerUp();
		Stump.ReigniteThrusters();

		HeadComp.ThrowOffNonInteractingPlayers();

		// Force players out of interaction
		HeadComp.bHeadShakeOffPlayers = true;
		HatchRoot.DisableInteracts();

		UIslandWalkerSettings::SetForceFieldReplenishAmountPerSecond(Owner, 1.0, this);
		UIslandWalkerHeadEffectHandler::Trigger_OnStartedFlying(Owner);
		UIslandWalkerHeadEffectHandler::Trigger_OnStartRecoveringFromCrash(Owner);
	}

	UFUNCTION(CrumbFunction)
	void CrumbEscape()
	{
		HeadComp.State = EIslandWalkerHeadState::Escape;		
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartAttack()
	{
		AttackStartTime = BIG_NUMBER;

		if (!ensure(HeadComp.ShockWaves.IsValidIndex(iShockwave)))
			return;

		if (!ensure(HeadComp.ShockWaves[iShockwave] != nullptr))
			return;

		AnimComp.RequestSubFeature(SubTagWalkerHeadCrash::Attack, this);
		ShockWaveTime = ActiveDuration + ShockwaveDelays[0];
	}

	void LaunchShockwave()
	{
		FVector Epicenter = Arena.GetAtFloodedPoolDepth(Owner.ActorLocation + Owner.ActorForwardVector * 200.0, -40.0);
		HeadComp.ShockWaves[iShockwave].StartShockwave(Epicenter);
		iShockwave++;

		int iWaveMod = iShockwave % ShockwaveDelays.Num();
		ShockWaveTime += ShockwaveDelays[iWaveMod];
		if (iWaveMod == 0)
			ShockWaveTime += ShockwaveRecovery; // We've looped around

		UIslandWalkerHeadEffectHandler::Trigger_OnHeadShockwave(Cast<AHazeActor>(Owner));
	}

}