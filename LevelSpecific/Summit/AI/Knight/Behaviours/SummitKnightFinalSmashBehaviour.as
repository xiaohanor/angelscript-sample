class USummitKnightFinalSmashBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	
	FBasicAIAnimationActionDurations StartDurations;
	float RecoverDuration;
	bool bRecovering;

	USummitKnightComponent KnightComp;
	USummitKnightHelmetComponent Helmet;
	UTeenDragonRollAutoAimComponent RollAutoAimComp;
	USummitKnightAnimationComponent KnightAnimComp;
	UTeenDragonRollComponent PlayerRollComp;
	USummitKnightSceptreComponent Sceptre;
	TArray<USummitKnightBladeComponent> Blades;
	AHazePlayerCharacter TrackedPlayer;
	UBoxComponent SmashHelpCollision;
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityOnPlayerComp;
	USummitKnightPlayerRollToHeadComponent PlayerRollToHeadComp;
	UTeenDragonAcidAutoAimComponent AcidAutoAim;

	// We slide mesh forward some ways to reach arena
	UHazeSkeletalMeshComponentBase Mesh;
	FVector MeshLoc;

	TArray<USummitKnightBladeComponent> CheckImpactForBlades;

	bool bStartedSheets = false;
	FVector FocusLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		RollAutoAimComp = UTeenDragonRollAutoAimComponent::Get(Owner);
		Helmet = USummitKnightHelmetComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		SmashHelpCollision = UBoxComponent::Get(Owner, n"SmashHelpCollision");
		RequestCapabilityOnPlayerComp = UHazeRequestCapabilityOnPlayerComponent::Get(Owner);
		PlayerRollToHeadComp = USummitKnightPlayerRollToHeadComponent::GetOrCreate(Game::Zoe);
		AcidAutoAim = UTeenDragonAcidAutoAimComponent::Get(Owner);

		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		Owner.GetComponentsByClass(Blades);
		RollAutoAimComp.Disable(this);

		AcidAutoAim.Disable(n"SmashVulnerabilityBehaviour");

		auto KnightOwner = Cast<AAISummitKnight>(Owner);
		Mesh = KnightOwner.Mesh;
		KnightOwner.OnHeadDamagedByDragon.AddUFunction(this, n"OnHeadDamagedByDragon");

		FocusLocation = Owner.ActorLocation + Owner.ActorForwardVector * 5000.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > StartDurations.GetTotal() + Settings.FinalSmashStuckDuration + RecoverDuration)	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		bRecovering = false;

		StartDurations.Telegraph = Settings.FinalSmashTelegraphDuration;
		StartDurations.Anticipation = Settings.FinalSmashAnticipationDuration;
		StartDurations.Action = Settings.FinalSmashActionDuration;
		StartDurations.Recovery = Settings.FinalSmashRemainingDuration;
		// KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::PhaseTwo, SummitKnightSubTagsPhaseTwo::FinalSmash, StartDurations);
		// AnimComp.RequestAction(SummitKnightFeatureTags::PhaseTwo, SummitKnightSubTagsPhaseTwo::FinalSmash, EBasicBehaviourPriority::Medium, this, StartDurations);
		// RecoverDuration = KnightAnimComp.GetFinalizedTotalDuration(SummitKnightFeatureTags::PhaseTwo, SummitKnightSubTagsPhaseTwo::FinalRailRecover, Settings.FinalSmashRecoverDuration);
		
		Sceptre.Unequip();
		Blades[0].Equip();
		Blades[1].Equip();

		FVector OwnLoc = Owner.ActorLocation;
		TrackedPlayer = Game::Mio;
		if (OwnLoc.DistSquared2D(Game::Mio.ActorLocation) > OwnLoc.DistSquared2D(Game::Zoe.ActorLocation))
			TrackedPlayer = Game::Zoe;

		CheckImpactForBlades = Blades;
		KnightComp.CritterSpawner.DeactivateSpawner();

		// Allow player to react when successful jump to head is detected
		if (!bStartedSheets)		
			RequestCapabilityOnPlayerComp.StartInitialSheetsAndCapabilities(Game::Zoe, this);
		bStartedSheets = true;
		PlayerRollComp = UTeenDragonRollComponent::Get(Game::Zoe);

		RollAutoAimComp.Enable(this);
		AcidAutoAim.Enable(n"SmashVulnerabilityBehaviour");

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

		RollAutoAimComp.Disable(this);
		AcidAutoAim.Disable(n"SmashVulnerabilityBehaviour");
		Helmet.bCanRegrow = true;

		if (SmashHelpCollision.IsCollisionEnabled())
			SmashHelpCollision.AddComponentCollisionBlocker(Owner);
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
			SlideLoc.X = Math::EaseInOut(MeshLoc.X, Settings.FinalSmashSlideForwardDistance, Alpha, 3.0);
			Mesh.RelativeLocation = SlideLoc;
		}

		if (!bRecovering && (ActiveDuration > StartDurations.GetTotal() + Settings.FinalSmashStuckDuration))
		{
			// Start recovering
			bRecovering = true;
			//AnimComp.RequestFeature(SummitKnightFeatureTags::PhaseTwo, SummitKnightSubTagsPhaseTwo::FinalSmashRecover, EBasicBehaviourPriority::Medium, this, RecoverDuration);
		}

		if (bRecovering)
		{
			// Slide mesh back
			float Alpha = (ActiveDuration - (StartDurations.GetTotal() + Settings.FinalRailSmashStuckDuration)) / RecoverDuration;
			FVector SlideLoc = MeshLoc;
			SlideLoc.X = Math::EaseInOut(Settings.FinalSmashSlideForwardDistance, MeshLoc.X, Alpha, 3.0);
			Mesh.RelativeLocation = SlideLoc;
		}

		if (ShouldDragonJumpToHead())
		{
			if (PlayerRollToHeadComp.HasControl())
				CrumbStartJumpToHead();			
		}
		
		if (StartDurations.IsInActionRange(ActiveDuration))
		{
			// Check for blade impacts
			for (int i = CheckImpactForBlades.Num() - 1; i >= 0; i--)
			{
				// Check aginst offset value because swords actually slide through surface while being rotated in this anim				
				USummitKnightBladeComponent Blade = CheckImpactForBlades[i];
				if (Blade.TipLocation.Z < KnightComp.GetArenaHeight() - 1200.0) 
				{
					//USummitKnightEventHandler::Trigger_OnBladeImpact(Owner, FSummitKnightBladeImpactParams(Blade, KnightComp));
					CheckImpactForBlades.RemoveAtSwap(i);
					
					FVector ImpactLocation = KnightComp.GetArenaLocation(Blade.TipLocation);
					for (AHazePlayerCharacter Player : Game::Players)
					{
						if (Player.HasControl() && ImpactLocation.IsWithinDist2D(Player.ActorLocation, Settings.FinalSmashHitRadius))
							CrumbHitPlayer(Player, ImpactLocation);		
					}
#if EDITOR
					// Owner.bHazeEditorOnlyDebugBool = true
					if (Owner.bHazeEditorOnlyDebugBool)
					{
						Debug::DrawDebugCapsule(ImpactLocation, 2000.0, Settings.FinalSmashHitRadius, Owner.ActorRotation, FLinearColor::Red, 20.0, 3.0);			
					}
#endif		
				}	
			}
		}

		if (!bRecovering)
		{
			if ((ActiveDuration > StartDurations.PreActionDuration) && !SmashHelpCollision.IsCollisionEnabled())
			{
				// Place collision helper so player won't be able to accidentally roll over edge below knight
				SmashHelpCollision.RemoveComponentCollisionBlocker(Owner);
				SmashHelpCollision.RelativeLocation = FVector(3500.0, 0.0, 0.0);
				SmashHelpCollision.RelativeRotation = FRotator(0.0, 9.0, 0.0);	
				SmashHelpCollision.BoxExtent = FVector(100.0, 800.0, 1200.0);
			}
		}
		else if (SmashHelpCollision.IsCollisionEnabled())
		{
			// Turn off helper collision
			SmashHelpCollision.AddComponentCollisionBlocker(Owner);
		}
	}

	bool ShouldDragonJumpToHead()
	{
		if (bRecovering)
			return false;
		if (ActiveDuration < StartDurations.GetPreRecoveryDuration())
			return false;
		if (Helmet.bCollision)
		 	return false; // Helmet is intact
		if (PlayerRollToHeadComp.Type != EKnightPlayerRollToHeadType::None)
			return false; // Already jumping
		if (PlayerRollComp == nullptr)
			return false;
		if (!PlayerRollComp.IsRolling())
			return false;
		if (PlayerRollComp.KnockbackParams.IsSet())
			return false; // Bbeing knocked back after completed jump or other wall impact
		AActor Roller = PlayerRollComp.Owner;
		if (Roller.ActorForwardVector.DotProduct(Helmet.WorldLocation - (Owner.ActorForwardVector * 500.0) - Roller.ActorLocation) < 0.0)
			return false; // Rolling away from us
		if (!Roller.ActorLocation.IsWithinDist2D(Helmet.WorldLocation, 800.0))
			return false; // Too far away
		return true;		
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartJumpToHead()
	{
		PlayerRollToHeadComp.Type = EKnightPlayerRollToHeadType::JumpToHead;
		PlayerRollToHeadComp.KnightMesh = Mesh;
		PlayerRollToHeadComp.bWillSmash = !Helmet.bCollision;

		if (!Helmet.bCollision)
		{
			// Make sure helmet won't recover during jump
			Helmet.TakeDamage(1.0);
			Helmet.bCanRegrow = false;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitPlayer(AHazePlayerCharacter Player, FVector ImpactLocation)
	{
		Player.DamagePlayerHealth(Settings.FinalSmashDamage); 

		FVector HitDir = (Player.ActorLocation - ImpactLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
		FVector StumbleMove = HitDir * Settings.FinalSmashStumbleDistance;
		KnightComp.StumbleDragon(Player, StumbleMove, 0.0);

		FSummitKnightProjectileDamageParams DamageEventParams;
		DamageEventParams.Player = Player; 
		DamageEventParams.Damage = Settings.GenericAttackShockwaveDamage; 
		DamageEventParams.Direction = HitDir;
		USummitKnightProjectileDamageEventHandler::Trigger_OnPlayerDamage(Owner, DamageEventParams);
	}

	UFUNCTION()
	private void OnHeadDamagedByDragon()
	{
		// This will trigger the crumbed HeadDamagedCapability
		auto StageComp = USummitKnightStageComponent::Get(Owner);
		StageComp.SetPhase(ESummitKnightPhase::HeadDamage, 1);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (bStartedSheets)
			RequestCapabilityOnPlayerComp.StopInitialSheetsAndCapabilities(Game::Zoe, this);
		bStartedSheets = false;
	}
}

