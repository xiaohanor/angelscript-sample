class USummitKnightMobileEndSlamAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightSceptreComponent Sceptre;
	TArray<USummitKnightBladeComponent> Blades;
	USummitKnightMobileCrystalBottom CrystalBottom;
	UBasicAIHealthComponent HealthComp;
	USummitKnightSettings Settings;

	FVector Destination;
	FBasicAIAnimationActionDurations EnterDurations;
	float StartExitTime;
	float ExitCompleteTime;
	bool bExiting;
	float TargetSpeed;
	FHazeAcceleratedFloat Speed;

	float AllowStunTime;
	float StunDuration;
	float StunExitDuration;

	bool bStuckInGround = false;
	float TriggerShockwaveTime = BIG_NUMBER;
	bool bLaunchedShockwave = false;
	bool bShockwaveExpired = false;
	float StartSwordPulloutTime = BIG_NUMBER;
	float FreeBladeTime = BIG_NUMBER;

	bool bStoppedAnimMovement = false;
	float BackAwayTime;

	bool bSpawnObstacles = true;
	int NumSpawnedObstacles;
	FAreaDenialZoneObstacleSpawnParameters ObstacleParams;

	TArray<AHazePlayerCharacter> HitPlayers; 

	USummitKnightMobileEndSlamAttackBehaviour(bool bSummonObstacles)
	{
		bSpawnObstacles = bSummonObstacles;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		KnightComp = USummitKnightComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::Get(Owner);
		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		Owner.GetComponentsByClass(Blades);
		CrystalBottom = USummitKnightMobileCrystalBottom::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
		KnightComp.SpawnTorusShockWave();

		// Randomize starting obstacle variants. This is replicated along with other obstacle spawn params.
		ObstacleParams.MetalVariant = Math::RandRange(0, 5);
		ObstacleParams.CrystalVariant = Math::RandRange(0, 5);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FAreaDenialZoneObstacleSpawnParameters& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;

		OutParams = GetObstacleSpawnParameters();	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FKnightSlamDeactivationParams& OutParams) const
	{
		if (Super::ShouldDeactivate() || (ActiveDuration > ExitCompleteTime))
		{
			OutParams.bSpawnObstacles = bLaunchedShockwave;
			OutParams.SetupHackTeleport(Owner.ActorLocation, KnightComp.Arena);
			return true;
		} 
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FAreaDenialZoneObstacleSpawnParameters Params)
	{
		Super::OnActivated();
		ObstacleParams = Params;
		Destination = KnightComp.Arena.Center;
		if (TargetComp.HasValidTarget())
			Destination = KnightComp.Arena.GetClampedToArena(TargetComp.Target.ActorLocation, 1000.0);
		Destination -= (Owner.ActorLocation - Destination).GetSafeNormal2D() * 800.0;		

		bStuckInGround = false;

		// Always jump forward, trust that we've rotated correctly by the time movement starts
		FVector Move = Owner.ActorForwardVector * (Destination - Owner.ActorLocation).Size2D(); 
		Move.Z = Settings.SlamEnterHeight;

		EnterDurations.Telegraph = Settings.SlamEnterTelegraphDuration;
		EnterDurations.Anticipation = Settings.SlamEnterAnticipationDuration;
		EnterDurations.Action = Settings.SlamEnterActionDuration;
		EnterDurations.Recovery = Settings.SlamEnterRecoveryDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::SlamAttack, SummitKnightSubTagsSlamAttack::Enter, EnterDurations);
		AnimComp.RequestAction(SummitKnightFeatureTags::SlamAttack, SummitKnightSubTagsSlamAttack::Enter, EBasicBehaviourPriority::Medium, this, EnterDurations, Move, true);

		StartExitTime = EnterDurations.GetTotal() + Settings.SlamMhDuration;
		TriggerShockwaveTime = EnterDurations.PreActionDuration;
		bLaunchedShockwave = false;
		bShockwaveExpired = false;

		FBasicAIAnimationActionDurations ExitDurations;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::SlamAttack, SummitKnightSubTagsSlamAttack::Exit, ExitDurations);
		BackAwayTime = StartExitTime + ExitDurations.PreActionDuration;
		bStoppedAnimMovement = false;

		StartSwordPulloutTime = StartExitTime;
		FreeBladeTime = StartExitTime + ExitDurations.PreActionDuration;

		bExiting = false;
		float ExitDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::SlamAttack, SummitKnightSubTagsSlamAttack::Exit, Settings.SlamExitDuration);
		ExitCompleteTime = StartExitTime + ExitDuration;

		KnightComp.bCanBeStunned.Apply(false, this);
		HealthComp.ClearStunned();
		AllowStunTime = EnterDurations.PreActionDuration;
		StunDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::SlamAttack, SummitKnightSubTagsSlamAttack::Stun, Settings.SlamStunDuration); 

		TargetSpeed = Owner.ActorLocation.Dist2D(Destination) / Math::Max(0.1, EnterDurations.Anticipation);
		Speed.SnapTo(0.0);

		Sceptre.Unequip();
		Blades[0].Equip();
		Blades[1].Equip();

		NumSpawnedObstacles = 0;
		HitPlayers.Reset(2);

		if (HealthComp.IsStunned())
			CrystalBottom.Shatter();
		CrystalBottom.Retract(this);

		UBasicAIMovementSettings::SetTurnDuration(Owner, 2.5, this);;
		USummitKnightSettings::SetSmashCrystalPlayerStumbleDistance(Owner, 4000.0, this);

		USummitKnightEventHandler::Trigger_OnSlamAggroTelegraph(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FKnightSlamDeactivationParams Params)
	{
		Super::OnDeactivated();
		KnightComp.bCanBeStunned.Clear(this);
		CrystalBottom.Deploy(this);

		Owner.ClearSettingsByInstigator(this);

		if (Params.bSpawnObstacles)
		{
			// Spawn any remaining obstacles (unlikely but might happen on remote or due to interrupting behaviour)
			for (int i = NumSpawnedObstacles; i < ObstacleParams.Zones.Num(); i++)
			{
				SpawnObstacle();
			}
		}

		if (Params.bHackTeleportToArena)
			Owner.SmoothTeleportActor(Params.HackTeleportLocation, Owner.ActorRotation, this, 1.0);

		if (bLaunchedShockwave && !bShockwaveExpired && (HitPlayers.Num() == 0) && !KnightComp.TorusShockWave.HitAnything())
			USummitKnightEventHandler::Trigger_OnSlamAggroMiss(Owner);
		USummitKnightEventHandler::Trigger_OnSlamAggroEnd(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Turn towards destination before jump
		if (EnterDurations.IsInTelegraphRange(ActiveDuration) && !Destination.IsWithinDist2D(Owner.ActorLocation, 200.0))
			DestinationComp.RotateTowards(Destination);

		// Move to destination using animation movement, then stop, then back away to outskirts of arena
		if (!bStoppedAnimMovement && (ActiveDuration > EnterDurations.GetTotal() - 0.5))
		{
			// Stop requesting animation movement, switch to regular movement		
			bStoppedAnimMovement = true;
			AnimComp.ClearFeature(this);
			AnimComp.RequestFeature(SummitKnightFeatureTags::SlamAttack, SummitKnightSubTagsSlamAttack::Mh, EBasicBehaviourPriority::Medium, this);
		}
		if ((ActiveDuration > EnterDurations.PreActionDuration) && (ActiveDuration < BackAwayTime))
		{
			// Always make sure we end up at arena height
			DestinationComp.MoveTowardsIgnorePathfinding(KnightComp.Arena.GetAtArenaHeight(Owner.ActorLocation), 1000.0);
		}
		if (ActiveDuration > BackAwayTime)
		{
			Speed.AccelerateTo(1000.0, 4.0, DeltaTime);
			if (KnightComp.Arena.IsInsideArena(KnightComp.Arena.GetAtArenaHeight(Owner.ActorLocation), 600.0))
				DestinationComp.MoveTowardsIgnorePathfinding(KnightComp.Arena.GetAtArenaHeight(Owner.ActorLocation + Owner.ActorForwardVector * 1000.0), Speed.Value);
		}

		if (!bStuckInGround && EnterDurations.IsInActionRange(ActiveDuration))
		{
			bStuckInGround = true;
			Speed.SnapTo(0.0);
			USummitKnightSettings::SetFriction(Owner, 40.0, this);			
			USummitKnightEventHandler::Trigger_OnSlamImpact(Owner, FSummitKnightBladeImpactParams(Blades[0], KnightComp));
		}
		else if (bStuckInGround && ActiveDuration > StartExitTime)
		{
			bStuckInGround = false;
			USummitKnightSettings::ClearFriction(Owner, this);			
		}

		if(ActiveDuration > StartSwordPulloutTime)
		{ 
			StartSwordPulloutTime = BIG_NUMBER;
			USummitKnightEventHandler::Trigger_OnSlamStartSwordPullout(Owner, FSummitKnightBladeImpactParams(Blades[0], KnightComp));
		}

		if (ActiveDuration > FreeBladeTime)
		{
			FreeBladeTime = BIG_NUMBER;
			USummitKnightEventHandler::Trigger_OnSlamFreeSword(Owner, FSummitKnightBladeImpactParams(Blades[0], KnightComp));
		}

		if (!bExiting && (ActiveDuration > StartExitTime))	
		{
			// Start exit animation
			bExiting = true;
			AnimComp.RequestSubFeature(SummitKnightSubTagsSlamAttack::Exit, this, ExitCompleteTime - StartExitTime);
		}

		if (ActiveDuration > AllowStunTime)
		{
			// Deploy crystal bottom and allow stun when we've attacked
			KnightComp.bCanBeStunned.Clear(this);
			if (!CrystalBottom.bDeployed && Owner.ActorVelocity.IsNearlyZero(50.0))
				CrystalBottom.Deploy(this); 

			if (HasControl() && HealthComp.IsStunned())
			{
				// We've been hit by tail dragon, trigger stun and exit
				CrumbStunned(); 
			}
		}

		if (ActiveDuration > ObstacleParams.SpawnTime)
			SpawnObstacle();

		if ((ActiveDuration > TriggerShockwaveTime) && HasControl())
			CrumbTriggerShockwave(GetShockwaveEpicenter());

		if (bLaunchedShockwave && !bShockwaveExpired && KnightComp.TorusShockWave.IsExpiring())
		{
			bShockwaveExpired = true;
			if ((HitPlayers.Num() == 0) && !KnightComp.TorusShockWave.HitAnything())
				USummitKnightEventHandler::Trigger_OnSlamAggroMiss(Owner);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbStunned()
	{
		KnightComp.bCanBeStunned.Apply(false, this);
		float ExitStunDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::HurtReaction, NAME_None, Settings.SlamExitStunDuration);
		AnimComp.RequestFeature(SummitKnightFeatureTags::HurtReaction, EBasicBehaviourPriority::Medium, this, ExitStunDuration);
		AllowStunTime = BIG_NUMBER;
		bExiting = true;
		ExitCompleteTime = ActiveDuration + ExitStunDuration;

		UAnimSequence StunnedAnim = KnightAnimComp.GetRequestedAnimation(SummitKnightFeatureTags::SlamAttack, SummitKnightSubTagsSlamAttack::Stun);
		FreeBladeTime = ActiveDuration + StunnedAnim.GetAnimNotifyStateStartTime(UBasicAIActionAnimNotify);

		HealthComp.ClearStunned();
		CrystalBottom.Shatter();
		CrystalBottom.Retract(this);
	}

 	FVector GetShockwaveEpicenter() const
	{
		return KnightComp.Arena.GetAtArenaHeight((Blades[0].HiltLocation + Blades[1].HiltLocation) * 0.5);
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerShockwave(FVector Location)
	{
		bLaunchedShockwave = true;
		TriggerShockwaveTime = BIG_NUMBER;
		
		FKnightTorusShockwaveSettings Torus;
		Torus.StartRadius = Settings.SlamShockwaveStartRadius;
		Torus.EndRadius = Settings.SlamShockwaveEndRadius;
		Torus.ExpansionSpeed = Settings.SlamShockwaveExpansionSpeed;
		Torus.Damage = Settings.SlamShockwaveDamage;
		Torus.DamageHeight = Settings.SlamShockwaveDamageHeight;
		Torus.DamageWidth = Settings.SlamShockwaveDamageWidth;
		Torus.StumbleForce = Settings.SlamShockwaveStumbleForce;
		KnightComp.TorusShockWave.StartShockwave(KnightComp, Location, Torus);

		// Kill any player underneath knight
		FVector TipLoc = KnightComp.Arena.GetAtArenaHeight(Owner.ActorLocation + Owner.ActorForwardVector * 1200.0);
		FVector BaseLoc = KnightComp.Arena.GetAtArenaHeight(Owner.ActorLocation);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;
			if (Player.ActorLocation.Z > KnightComp.Arena.Center.Z + 1000.0)
				continue;
			FVector AtArenaLoc = KnightComp.Arena.GetAtArenaHeight(Player.ActorLocation);
			if (!AtArenaLoc.IsInsideTeardrop2D(BaseLoc, TipLoc, 600.0, 900.0))
				continue;
			CrumbHitPlayer(Player);
		}
		KnightComp.SmashObstaclesInTeardrop(BaseLoc, TipLoc, 600.0, 900.0);
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitPlayer(AHazePlayerCharacter Player)
	{
		// Splat!
		Player.DealTypedDamage(Owner, 1.0, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge, false);		
		HitPlayers.AddUnique(Player);
		KnightComp.bDeathCouldHaveBeenDashAvoided[Player] = true;

		USummitKnightEventHandler::Trigger_OnSlamAggroDirectHit(Owner, FSummitKnightPlayerParams(Player));
		if (HitPlayers.Num() == 2)
			USummitKnightEventHandler::Trigger_OnSlamAggroDirectHitBoth(Owner);
	}

	FAreaDenialZoneObstacleSpawnParameters GetObstacleSpawnParameters() const
	{
		FAreaDenialZoneObstacleSpawnParameters Params;
		if (!bSpawnObstacles)
		{
			Params.SpawnTime = BIG_NUMBER;
			return Params;
		}

		// Random selection of zones for now
		TArray<ASummitKnightAreaDenialZone> Zones = TListedActors<ASummitKnightAreaDenialZone>().Array;
		Zones.Shuffle();
		for (ASummitKnightAreaDenialZone Zone : Zones)
		{
			if (Zone.HasActiveObstacle())
				continue; // Already in use

			Params.Zones.Add(Zone);
			if (Params.Zones.Num() >= Settings.EndSlamNumObstacles)
				break; // We've got enough zones
		}

		if (Params.Zones.Num() == 0)
		{
			Params.Reset(Settings.EndSlamNumObstacles);
		}
		else
		{
			Params.SpawnTime = 2.0 + Settings.SlamSummonObstaclesDelay;
			float SpawnDuration = Settings.SlamSummonObstaclesDuration;
			UAnimSequence Anim = KnightAnimComp.GetRequestedAnimation(SummitKnightFeatureTags::SlamAttack, SummitKnightSubTagsSlamAttack::Enter);
			TArray<FHazeAnimNotifyStateGatherInfo> ActionInfo;
			if (ensure(Anim != nullptr) && Anim.GetAnimNotifyStateTriggerTimes(UBasicAIActionAnimNotify, ActionInfo) && (ActionInfo.Num() > 0))
				Params.SpawnTime = ActionInfo[0].TriggerTime + Settings.SlamSummonObstaclesDelay;

			Params.SpawnInterval = SpawnDuration / Math::Max(1.0, float(Params.Zones.Num() - 1));

			// Variants are randomized on setup and then incremented. This ensures they get replicated to remote.
			Params.MetalVariant = ObstacleParams.MetalVariant;
			Params.CrystalVariant = ObstacleParams.CrystalVariant;
		}

		return Params;
	}	

	void SpawnObstacle()
	{
		if (ensure(ObstacleParams.Zones.IsValidIndex(NumSpawnedObstacles)))
		{
			// Start with metal obstacles as they hinder tail dragon, then alternate
			if (NumSpawnedObstacles % 2 == 0)
			{
				ObstacleParams.Zones[NumSpawnedObstacles].MetalObstacle.SpawnObstacle(ObstacleParams.MetalVariant, Owner);
				ObstacleParams.MetalVariant++;
			}
			else
			{
				ObstacleParams.Zones[NumSpawnedObstacles].CrystalObstacle.SpawnObstacle(ObstacleParams.CrystalVariant);
				ObstacleParams.CrystalVariant++;
			}
		}

		NumSpawnedObstacles++;
		if (ObstacleParams.Zones.IsValidIndex(NumSpawnedObstacles))
			ObstacleParams.SpawnTime += ObstacleParams.SpawnInterval;
		else
			ObstacleParams.SpawnTime = BIG_NUMBER;
	}
}

