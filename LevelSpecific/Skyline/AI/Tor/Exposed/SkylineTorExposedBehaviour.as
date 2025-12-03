class USkylineTorExposedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MoveComp;
	USkylineTorDamageComponent DamageComp;
	USkylineEnforcerSentencedComponent SentencedComp;
	USkylineTorPhaseComponent PhaseComp;
	USkylineTorExposedComponent ExposedComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	UGravityBladeOpportunityAttackTargetComponent OpportunityAttackComp;
	UGravityBladeGrappleComponent BladeGrappleComp;
	UGravityBladeCombatTargetComponent BladeTargetComp;
	USkylineTorHoverComponent HoverComp;
	USkylineTorPlayerCollisionComponent CollisionComp;
	UAnimInstanceSkylineTor AnimInstance;
	ASkylineTor Tor;
	ASkylineTorNoFallArea NoFallArea;

	float StartTime;
	bool FirstBladeHit;
	bool FinishedBladeHit;
	bool bRecovering;
	bool bFinalAttack;
	bool bFinalHammerBlow;
	FBasicAIAnimationActionDurations Durations;
	float FinalBladeHitTime;
	float FinalBladeHitDuration;

	bool bFoundFallLocation;
	FVector FallLocation;
	FVector CenterLocation;
	AHazeActor FallLocationActor;
	FHazeAcceleratedRotator AccHammerRot;
	const FName ExposedInstigator = n"ExposedInstigator";

	FRotator OriginalHammerCompRelativeRotation;
	AHazeActor BladeOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();				
		Tor = Cast<ASkylineTor>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Tor.Mesh.AnimInstance);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		DamageComp = USkylineTorDamageComponent::Get(Owner);
		SentencedComp = USkylineEnforcerSentencedComponent::GetOrCreate(Owner);
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		ExposedComp = USkylineTorExposedComponent::GetOrCreate(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		BladeGrappleComp = UGravityBladeGrappleComponent::Get(Owner);
		BladeTargetComp = UGravityBladeCombatTargetComponent::Get(Owner);
		OpportunityAttackComp = UGravityBladeOpportunityAttackTargetComponent::GetOrCreate(Owner);
		HoverComp = USkylineTorHoverComponent::GetOrCreate(Owner);
		CollisionComp = USkylineTorPlayerCollisionComponent::GetOrCreate(Owner);

		USkylineTorHammerResponseComponent HammerResponse = USkylineTorHammerResponseComponent::GetOrCreate(Owner);
		if (HammerResponse != nullptr)
			HammerResponse.OnHit.AddUFunction(this, n"OnHammerHit");

		// Combat grapple and blade target is only ever active when exposed but since 
		// there currently are multiple exposed behaviours we'll use this custom instigator
		BladeGrappleComp.Disable(ExposedInstigator);
		BladeTargetComp.Disable(ExposedInstigator);

		FallLocationActor = TListedActors<ASkylineTorOpportunityAttackPoint>().GetSingle();
		CenterLocation = TListedActors<ASkylineTorCenterPoint>().GetSingle().ActorLocation;
		NoFallArea = TListedActors<ASkylineTorNoFallArea>().GetSingle();

		UGravityBladeCombatResponseComponent BladeResponse = UGravityBladeCombatResponseComponent::Get(Owner);
		OpportunityAttackComp = UGravityBladeOpportunityAttackTargetComponent::GetOrCreate(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");

		DamageComp.OnFinishingHammerBlowStarted.AddUFunction(this, n"OnFinishingHammerBlowStarted");

		Durations.Recovery = AnimInstance.ExposedEnd.Sequence.PlayLength;
		SkylineTorDevToggleNamespace::StayExposed.MakeVisible();		
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(!IsActive())
			return;
		if(FinalBladeHitTime > SMALL_NUMBER)
			return;
		if(bRecovering)
			return;
		if (DamageComp.bIsPerformingFinishingHammerBlow && !ExposedComp.bFinalExpose) // Prevent changing durations from blade during the finishing hammer blow.
			return;

		if(!FirstBladeHit)
		{
			StartTime = Time::GameTimeSeconds;
			Durations.Action = 3;
			FirstBladeHit = true;
		}

		if(IsGroundedFinishingBladeHit())
		{
			StartTime = Time::GameTimeSeconds;
			Durations.Action = 0.5;
			FinishedBladeHit = true;
		}

		if(bFinalAttack)
		{
			if(HealthComp.CurrentHealth <= 0.125)
			{
				Game::Mio.PlaySlotAnimation(ExposedComp.PlayerFinalJumpSequence, FHazeSlotAnimSettings());
				FinalBladeHitTime = Time::GameTimeSeconds;
				FinalBladeHitDuration = ExposedComp.PlayerFinalJumpSequence.PlayLength;

				BladeOwner = Cast<AHazeActor>(CombatComp.Owner);
				BladeOwner.BlockCapabilities(CapabilityTags::Movement, this);
				BladeOwner.BlockCapabilities(CapabilityTags::MovementInput, this);
				BladeOwner.BlockCapabilities(CapabilityTags::GameplayAction, this);
			}
		}
	}

	UFUNCTION()
	private void OnFinishingHammerBlowStarted()
	{
		if(!IsActive())
			return;

		// Set alloted time for the finishing blow.
		StartTime = Time::GameTimeSeconds;
		Durations.Action = 0.5;
		bFinalHammerBlow = true;
		Durations.Recovery = AnimInstance.ExposedHitEnd.Sequence.PlayLength;
		HoverComp.StopHover(this, EInstigatePriority::High);
	}

	private bool IsGroundedFinishingBladeHit()
	{
		if(FinishedBladeHit)
			return false;
		if(HealthComp.CurrentHealth > PhaseComp.GroundedSecondThreshold)
			return false;
		if(PhaseComp.Phase != ESkylineTorPhase::Grounded)
			return false;
		return true;
	}

	UFUNCTION()
	private void OnHammerHit(float Damage, EDamageType DamageType, AHazeActor HammerInstigator)
	{	
		if(Owner.bIsControlledByCutscene)
			return;
		if(IsBlocked())	
			return;
		if(!ExposedComp.bCanExpose)
			return;

		if(bFinalHammerBlow)
		{
			HoldHammerComp.Hammer.HammerComp.SetMode(ESkylineTorHammerMode::Return);
			AnimComp.RequestSubFeature(SubTagSkylineTorExposed::HitEnd, this);
		}

		if(IsActive())
			return;
		if(ExposedComp.bExpose)
			return;
			
		ExposedComp.bExpose = true;
		ExposedComp.ExposeInstigator = HammerInstigator;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!ExposedComp.bExpose)
			return false;
		if(ExposedComp.ExposeInstigator == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(CancelByDuration())
			return true;
		return false;
	}

	private bool CancelByDuration() const
	{
		if(bFinalAttack)
			return false;
		if(SkylineTorDevToggleNamespace::StayExposed.IsEnabled())
			return false;
		if(Time::GetGameTimeSince(StartTime) < Durations.GetTotal())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Durations.Action = 6;
		StartTime = Time::GameTimeSeconds;
		FirstBladeHit = false;
		FinishedBladeHit = false;
		bRecovering = false;
		bFinalHammerBlow = false;
		bFoundFallLocation = false;

		ExposedComp.bExposed = true;

		// Clear anything from attacks
		USkylineTorEventHandler::Trigger_OnExposedStart(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		BladeGrappleComp.Enable(ExposedInstigator);
		BladeTargetComp.Enable(ExposedInstigator);
		
		if(ExposedComp.bFinalExpose)
		{
			HoldHammerComp.Hammer.HammerComp.SetMode(ESkylineTorHammerMode::Return);
			bFinalAttack = true;
			AnimComp.RequestFeature(FeatureTagSkylineTor::Exposed, SubTagSkylineTorExposed::StartFinal, EBasicBehaviourPriority::Medium, this, Durations.Action);

			for(AHazePlayerCharacter Player : Game::Players)
			{
				UPlayerHealthSettings::SetEnableRespawnTimer(Player, false, this);
				UPlayerHealthSettings::SetRespawnTimer(Player, 0, this);
			}
		}
		else
		{
			bFinalAttack = false;
			AnimComp.RequestFeature(FeatureTagSkylineTor::Exposed, EBasicBehaviourPriority::Medium, this, Durations.Action);
		}

		DamageComp.bDisableRecoil.Apply(true, this);
		DamageComp.bEnableDamage.Apply(true, this);
	
		OriginalHammerCompRelativeRotation = HoldHammerComp.RelativeRotation;
		AccHammerRot.SnapTo(OriginalHammerCompRelativeRotation);

		HoverComp.StopHover(this, EInstigatePriority::High);

		Tor.CapsuleComponent.OverrideCapsuleRadius(180, this);		
		CollisionComp.bEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USkylineTorEventHandler::Trigger_OnExposedStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		USkylineTorEventHandler::Trigger_OnRecallHammerStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		ExposedComp.bExposed = false;
		ExposedComp.bExpose = false;
		ExposedComp.ExposeInstigator = nullptr;
		bFinalHammerBlow = false;

		BladeGrappleComp.Disable(ExposedInstigator);
		BladeTargetComp.Disable(ExposedInstigator);

		OpportunityAttackComp.DisableOpportunityAttack();
		DamageComp.bDisableRecoil.Clear(this);
		DamageComp.bEnableDamage.Clear(this);
		DamageComp.ResetConescutiveHammerHits();

		HoldHammerComp.RelativeRotation = OriginalHammerCompRelativeRotation;
		HoverComp.ClearHover(this);

		if(HoldHammerComp.Hammer.HammerComp.CurrentMode == ESkylineTorHammerMode::Stolen)
			HoldHammerComp.Hammer.HammerComp.SetMode(ESkylineTorHammerMode::Return);

		Tor.CapsuleComponent.ClearCapsuleSizeOverride(this);
		CollisionComp.bEnabled = false;

		if(PhaseComp.Phase == ESkylineTorPhase::Grounded && PhaseComp.SubPhase == ESkylineTorSubPhase::None)
		{
			if(HealthComp.CurrentHealth <= PhaseComp.GroundedThreshold)
				PhaseComp.SetSubPhase(ESkylineTorSubPhase::GroundedSecond);
		}

		if(PhaseComp.Phase == ESkylineTorPhase::Hovering && PhaseComp.SubPhase == ESkylineTorSubPhase::None)
		{
			if(HealthComp.CurrentHealth <= PhaseComp.HoveringThreshold)
				PhaseComp.SetSubPhase(ESkylineTorSubPhase::HoveringSecond);
		}

		if(BladeOwner != nullptr)
		{
			BladeOwner.UnblockCapabilities(CapabilityTags::Movement, this);
			BladeOwner.UnblockCapabilities(CapabilityTags::MovementInput, this);
			BladeOwner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		}

		for(AHazePlayerCharacter Player : Game::Players)
			Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetDead()
	{
		PhaseComp.SetPhase(ESkylineTorPhase::Dead);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!OpportunityAttackComp.IsOpportunityAttackEnabled() && FinalBladeHitTime > SMALL_NUMBER && Time::GetGameTimeSince(FinalBladeHitTime) > FinalBladeHitDuration)
		{
			if(HasControl())	
				CrumbSetDead();
			return;
		}

		if(!bFinalAttack && Time::GetGameTimeSince(StartTime) > Durations.Action && !SkylineTorDevToggleNamespace::StayExposed.IsEnabled())
		{
			bRecovering = true;
			
			if(!bFinalHammerBlow)
				AnimComp.RequestSubFeature(SubTagSkylineTorExposed::End, this);

			if(Time::GetGameTimeSince(StartTime) > Durations.Action + Durations.Recovery * 0.75)
			{
				if(!bFinalHammerBlow && !HoldHammerComp.bAttached)
					DestinationComp.RotateTowards(HoldHammerComp.Hammer);

				if(!HoverComp.bHover)
				{
					BladeGrappleComp.Disable(ExposedInstigator);
					BladeTargetComp.Disable(ExposedInstigator);
					OpportunityAttackComp.DisableOpportunityAttack();
					DamageComp.bDisableRecoil.Clear(this);
					DamageComp.bEnableDamage.Clear(this);

					HoverComp.StartHover(this, EInstigatePriority::High);
					USkylineTorEventHandler::Trigger_OnRecallHammerStart(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
					if (HoldHammerComp.Hammer.HammerComp.CurrentMode == ESkylineTorHammerMode::Stolen)
					{
						// Stumble Zoe
						AHazePlayerCharacter Player = Game::Zoe;
						FStumble Stumble;
						FVector Dir = (Player.ActorForwardVector * -1.0);
						Stumble.Move = Dir * 350;
						Stumble.Duration = 1.0;
						Player.ApplyStumble(Stumble);
					}

					if(!bFinalHammerBlow)
						HoldHammerComp.Hammer.HammerComp.SetMode(ESkylineTorHammerMode::Return);
				}
			}

			return;
		}

		if(bFinalAttack)
		{
			DestinationComp.MoveTowardsIgnorePathfinding(FallLocationActor.ActorLocation, 2000);
			DestinationComp.RotateTowards(FallLocationActor.ActorLocation + FallLocationActor.ActorForwardVector * 500);
		}
		else
		{
			if(!bFoundFallLocation)
			{
				FVector FindLocation = Owner.ActorLocation;
				if(FindLocation.Dist2D(NoFallArea.ActorLocation) < NoFallArea.NoFallRadius)
					FindLocation = NoFallArea.ActorLocation + (FindLocation - NoFallArea.ActorLocation).GetSafeNormal2D() * NoFallArea.NoFallRadius;
				bFoundFallLocation = Pathfinding::FindNavmeshLocation(FindLocation, 1000, 1000, FallLocation);
			}
			
			if(bFoundFallLocation && !Owner.ActorLocation.IsWithinDist2D(FallLocation, 100))
				DestinationComp.MoveTowardsIgnorePathfinding(FallLocation, 1000);

			DestinationComp.RotateTowards(CenterLocation);
		}
	}
}