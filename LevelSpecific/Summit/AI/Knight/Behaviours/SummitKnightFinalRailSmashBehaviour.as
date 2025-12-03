class USummitKnightFinalRailSmashBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	
	FBasicAIAnimationActionDurations StartDurations;
	float RecoverDuration;
	bool bRecovering;
	bool bStartedSheets = false;

	USummitKnightComponent KnightComp;
	USummitKnightHelmetComponent Helmet;
	USummitKnightAnimationComponent KnightAnimComp;
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityOnPlayerComp;
	USummitKnightSceptreComponent Sceptre;
	TArray<USummitKnightBladeComponent> Blades;
	UTeenDragonAcidAutoAimComponent AcidAutoAim;
	AHazePlayerCharacter TrackedPlayer;

	AHazePlayerCharacter RollingPlayer;
	UTeenDragonRollComponent DragonRollComp;
	USummitKnightPlayerRollToHeadComponent PlayerRollToHeadComp;
	bool bHasRolledUpSword = false;
	float RolledUpSwordCooldown = BIG_NUMBER;
	
	// We slide mesh forward some ways to reach arena
	UHazeSkeletalMeshComponentBase Mesh;
	FVector MeshLoc;

	FVector FocusLocation;

	TArray<USummitKnightBladeComponent> CheckImpactForBlades;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		Helmet = USummitKnightHelmetComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		RequestCapabilityOnPlayerComp = UHazeRequestCapabilityOnPlayerComponent::Get(Owner);		

		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		Owner.GetComponentsByClass(Blades);

		RollingPlayer = Game::Zoe;
		PlayerRollToHeadComp = USummitKnightPlayerRollToHeadComponent::GetOrCreate(RollingPlayer);		

		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		FocusLocation = Owner.ActorLocation + Owner.ActorForwardVector * 5000.0;

		AcidAutoAim = UTeenDragonAcidAutoAimComponent::Get(Owner);
		AcidAutoAim.Disable(n"SmashVulnerabilityBehaviour");
	}

	bool CanDragonRollUpSword()
	{
		if (!Game::Zoe.HasControl())	
			return false;
		if (ActiveDuration < StartDurations.PreRecoveryDuration)		
			return false;
		if (ActiveDuration > StartDurations.GetTotal() + Settings.FinalRailSmashStuckDuration + 0.5)
			return false;
		if (!DragonRollComp.IsRolling())
			return false;
		FVector Velocity = RollingPlayer.ActorVelocity;
		if (Velocity.IsNearlyZero(10.0))
			return false;
		FVector PlayerLoc = RollingPlayer.ActorLocation;
		for (USummitKnightBladeComponent Blade : Blades)
		{
			FVector BladeDir = (Blade.TipLocation - Blade.HiltLocation);
			if (Velocity.DotProduct(BladeDir) > 0.0)
				continue; // We need to roll up blade, not in the same direction
			FVector LocAlongBlade;
			float Dummy;
			Math::ProjectPositionOnLineSegment(Blade.TipLocation, Blade.HiltLocation, PlayerLoc, LocAlongBlade, Dummy);
			if (!RollingPlayer.ActorLocation.IsWithinDist(LocAlongBlade, Settings.FinalRailSmashRollUpSwordRadius))
				continue; // Not there yet
			if (Velocity.DotProduct(LocAlongBlade - PlayerLoc) < 0.0)
				continue; // Rolling away from blade
			// Rollin', rollin', rollin'... Rawhide!
			return true;
		}
		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbDragonRolledUpSword()
	{
		OnDragonRolledUpSword();
	}

	UFUNCTION()
	private void OnDragonRolledUpSword()
	{
		if (!IsActive())
			return;

		bHasRolledUpSword = true;	
		RolledUpSwordCooldown = BIG_NUMBER;

		// Trigger player roll towards head	next tick
		PlayerRollToHeadComp.Type = EKnightPlayerRollToHeadType::RollUpBlades;
		PlayerRollToHeadComp.KnightMesh = Mesh;

		// Trigger hit response if helmet is melted next tick
		if (!Helmet.bCollision)
		{
			// Head will be destroyed!
			USummitKnightStageComponent StageComp = USummitKnightStageComponent::Get(Owner);
			StageComp.SetPhase(ESummitKnightPhase::HeadDamage, 2);
			PlayerRollToHeadComp.bWillSmash = true;

			// Make sure helmet won't recover during roll
			Helmet.TakeDamage(1.0);
			Helmet.bCanRegrow = false;
		}	

		AcidAutoAim.Disable(n"SmashVulnerabilityBehaviour");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > StartDurations.GetTotal() + Settings.FinalRailSmashStuckDuration + RecoverDuration)	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		bRecovering = false;

		StartDurations.Telegraph = Settings.FinalRailSmashTelegraphDuration;
		StartDurations.Anticipation = Settings.FinalRailSmashAnticipationDuration;
		StartDurations.Action = Settings.FinalRailSmashActionDuration;
		StartDurations.Recovery = Settings.FinalRailSmashRemainingDuration;
		// KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::PhaseTwo, SummitKnightSubTagsPhaseTwo::FinalRailSmash, StartDurations);
		// AnimComp.RequestAction(SummitKnightFeatureTags::PhaseTwo, SummitKnightSubTagsPhaseTwo::FinalRailSmash, EBasicBehaviourPriority::Medium, this, StartDurations);
		// RecoverDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::PhaseTwo, SummitKnightSubTagsPhaseTwo::FinalRailRecover, Settings.FinalRailSmashRecoverDuration);
		
		Sceptre.Unequip();
		Blades[0].Equip();
		Blades[1].Equip();

		FVector OwnLoc = Owner.ActorLocation;
		TrackedPlayer = Game::Mio;
		if (OwnLoc.DistSquared2D(Game::Mio.ActorLocation) > OwnLoc.DistSquared2D(Game::Zoe.ActorLocation))
			TrackedPlayer = Game::Zoe;

		CheckImpactForBlades = Blades;
		KnightComp.DeactivateSpawners();
		AcidAutoAim.Enable(n"SmashVulnerabilityBehaviour");

		// Allow player to react when successful roll up on sword is detected
		if (!bStartedSheets)		
			RequestCapabilityOnPlayerComp.StartInitialSheetsAndCapabilities(Game::Zoe, this);
		bStartedSheets = true;
		bHasRolledUpSword = false;
		DragonRollComp = UTeenDragonRollComponent::Get(RollingPlayer);

		// Assume we will not smash head until detected otherwise
		PlayerRollToHeadComp.bWillSmash = false;

		// Helmet will either quickly heal or stay dissolved during attack
		if (Helmet.bCollision)
			Helmet.Regenerate(1.0);
		else
			Helmet.bCanRegrow = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Sceptre.Equip();
		Blades[0].Unequip();
		Blades[1].Unequip();
		if (!bHasRolledUpSword)
			Helmet.bCanRegrow = true;
		AcidAutoAim.Disable(n"SmashVulnerabilityBehaviour");
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (bStartedSheets)
			RequestCapabilityOnPlayerComp.StopInitialSheetsAndCapabilities(Game::Zoe, this);
		bStartedSheets = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < StartDurations.Telegraph)
		{
			DestinationComp.RotateTowards(FocusLocation);	

			// Slide mesh to reach arena
			float Alpha = ActiveDuration / StartDurations.Telegraph;
			FVector SlideLoc = MeshLoc;
			SlideLoc.X = Math::EaseInOut(MeshLoc.X, Settings.FinalRailSmashSlideForwardDistance, Alpha, 3.0);
			Mesh.RelativeLocation = SlideLoc;
		}

		if (!bRecovering && (ActiveDuration > StartDurations.GetTotal() + Settings.FinalRailSmashStuckDuration))
		{
			// Start recovering
			bRecovering = true;
			//AnimComp.RequestFeature(SummitKnightFeatureTags::PhaseTwo, SummitKnightSubTagsPhaseTwo::FinalRailRecover, EBasicBehaviourPriority::Medium, this, RecoverDuration);
		}
		if (bRecovering)
		{
			// Slide mesh back
			float Alpha = (ActiveDuration - (StartDurations.GetTotal() + Settings.FinalRailSmashStuckDuration)) / RecoverDuration;
			FVector SlideLoc = MeshLoc;
			SlideLoc.X = Math::EaseInOut(Settings.FinalRailSmashSlideForwardDistance, MeshLoc.X, Alpha, 3.0);
			Mesh.RelativeLocation = SlideLoc;
		}

		if (!bRecovering && (ActiveDuration > StartDurations.Telegraph + StartDurations.Anticipation + StartDurations.Action))
		{
			Blades[0].EnableRollSpline();	
			Blades[1].EnableRollSpline();	
		}
		else
		{
			Blades[0].DisableRollSpline();	
			Blades[1].DisableRollSpline();	
		}

		if (StartDurations.IsInActionRange(ActiveDuration))
		{
			// Check for blade impacts
			for (int i = CheckImpactForBlades.Num() - 1; i >= 0; i--)
			{
				USummitKnightBladeComponent Blade = CheckImpactForBlades[i];
				if (Blade.TipLocation.Z < KnightComp.GetArenaHeight())
				{
					//USummitKnightEventHandler::Trigger_OnBladeImpact(Owner, FSummitKnightBladeImpactParams(Blade, KnightComp));
					CheckImpactForBlades.RemoveAtSwap(i);

					FVector ImpactLocation = KnightComp.GetArenaLocation(Blade.TipLocation);
					FVector HiltLocation = KnightComp.GetArenaLocation(Blade.HiltLocation);
					for (AHazePlayerCharacter Player : Game::Players)
					{
						if (!Player.HasControl())
							continue;

						// Note that any player between both swords will get absolutely clobbered
						// If we don't want that, only allow each player to get hit once
						FVector BladeLineLoc;
						float Dummy;
						Math::ProjectPositionOnLineSegment(ImpactLocation, HiltLocation, Player.ActorLocation, BladeLineLoc, Dummy);
						if (BladeLineLoc.IsWithinDist2D(Player.ActorLocation, Settings.FinalRailSmashHitRadius))
							CrumbHitPlayer(Player, BladeLineLoc);		
					}
#if EDITOR
					// Owner.bHazeEditorOnlyDebugBool = true
					if (Owner.bHazeEditorOnlyDebugBool)
					{
						Debug::DrawDebugCapsule((ImpactLocation + HiltLocation) * 0.5, ImpactLocation.Dist2D(HiltLocation) * 0.5, Settings.FinalRailSmashHitRadius, FRotator::MakeFromZX((ImpactLocation - Owner.ActorLocation).GetSafeNormal2D(), FVector::UpVector), FLinearColor::Red, 20.0, 3.0);			
					}
#endif		
				}	
			}
		}

		if (bHasRolledUpSword)
		{
			// Player has rolled up once, can they try again?
			if (ActiveDuration > RolledUpSwordCooldown)
				bHasRolledUpSword = false;
 			else if (PlayerRollToHeadComp.KnightMesh == nullptr)
				RolledUpSwordCooldown = ActiveDuration + 1.0;			
		}
		// Check if player should start rolling up sword
		if (!bHasRolledUpSword && CanDragonRollUpSword())
			CrumbDragonRolledUpSword(); 
	}

	//UFUNCTION(CrumbFunction)
	void CrumbHitPlayer(AHazePlayerCharacter Player, FVector ImpactLocation)
	{
		// TODO: Network this: Damage and stumble are both networked internally, but hit effect is not
		Player.DamagePlayerHealth(Settings.FinalRailSmashDamage); 

		FVector HitDir = (Player.ActorLocation - ImpactLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
		FVector StumbleMove = HitDir * Settings.FinalRailSmashStumbleDistance;
		KnightComp.StumbleDragon(Player, StumbleMove, 0.0);

		FSummitKnightProjectileDamageParams DamageEventParams;
		DamageEventParams.Player = Player; 
		DamageEventParams.Damage = Settings.GenericAttackShockwaveDamage; 
		DamageEventParams.Direction = HitDir;
		USummitKnightProjectileDamageEventHandler::Trigger_OnPlayerDamage(Owner, DamageEventParams);
	}
}

