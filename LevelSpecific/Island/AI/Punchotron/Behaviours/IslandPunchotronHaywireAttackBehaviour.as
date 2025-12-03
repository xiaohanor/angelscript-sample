class UIslandPunchotronHaywireAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	default CapabilityTags.Add(BasicAITags::Attack);

	UGentlemanCostComponent GentCostComp;
	UBasicAIHealthComponent HealthComp;
	UIslandPunchotronAttackComponent AttackComp;
	UIslandPunchotronCooldownComponent CooldownComp;
	UIslandPunchotronSettings Settings;
	UPathfollowingSettings PathingSettings;
	private TPerPlayer<bool> HasHitPlayer;

	AAIIslandPunchotron Punchotron;

	private const float TelegraphFraction = 0.35;
	private const float AnticipationFraction = 0.0;
	private const float ActionFraction = 0.35;
	private const float RecoveryFraction = 0.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
		CooldownComp = UIslandPunchotronCooldownComponent::GetOrCreate(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Punchotron = Cast<AAIIslandPunchotron>(Owner);

		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
	}
		
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (AttackComp.AttackState != EIslandPunchotronAttackState::HaywireAttack)
			return false;		
		if (!CooldownComp.IsCooldownOver(Owner.Class))
			return false;
		if (!Cooldown.IsOver())
			return false; 
		if (!TargetComp.HasValidTarget())
			return false;
		
		//if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.HaywireMaxAttackRange))
		//	return false;
		//if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.HaywireMinAttackRange))
		//	return false;
		
		// All these checks need to be made in Engage step
		// FVector ToTarget = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation).GetSafeNormal2D();
		// if (Owner.ActorForwardVector.DotProduct(ToTarget) < 0.0) // Don't attack when facing away from the target
		// 	return false;
		// if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
		// 	return false;
		// if (!IslandPunchotron::IsOnGround(Owner.ActorLocation, 40.0, PathingSettings.bIgnorePathfinding))
		// 	return false;

		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AttackComp.bIsAttacking = true;
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		
		FBasicAIAnimationActionDurations AttackDurations;
		AttackDurations.Telegraph =  Settings.HaywireAttackDuration * TelegraphFraction;
		AttackDurations.Anticipation = Settings.HaywireAttackDuration * AnticipationFraction;
		AttackDurations.Action = Settings.HaywireAttackDuration *  ActionFraction;
		AttackDurations.Recovery = Settings.HaywireAttackDuration * RecoveryFraction;
		//AnimComp.RequestAction(FeatureTagIslandPunchotron::HaywireAttack, EBasicBehaviourPriority::Medium, this, AttackDurations);
		AnimComp.RequestFeature(FeatureTagIslandPunchotron::HaywireAttack, EBasicBehaviourPriority::Medium, this);
		
		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.HaywireAttackDuration)
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (HasHitPlayer[Cast<AHazePlayerCharacter>(TargetComp.Target)])
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AttackComp.bIsAttacking = false;
		float CooldownTime = Settings.HaywireAttackCooldown + Settings.CooldownDuration;
		CooldownComp.SetCooldown(Owner.Class, CooldownTime); // cooldown between each attack variant
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		AnimComp.ClearFeature(this);
		AttackComp.NextAttackState();
		Punchotron.AttackTargetDecalComp.FadeOut(0.25);
		if (Owner.IsCapabilityTagBlocked(n"DamagePlayerOnTouch"))
			Owner.UnblockCapabilities(n"DamagePlayerOnTouch", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > 0.6 && ActiveDuration < 0.8)
			UIslandPunchotronEffectHandler::Trigger_OnRightSwipe(Owner, FIslandPunchotronSwipeParams(Punchotron.LeftBladeLocation, Punchotron.RightBladeLocation));
		if (ActiveDuration > 1.1 && ActiveDuration < 1.3)
			UIslandPunchotronEffectHandler::Trigger_OnLeftSwipe(Owner, FIslandPunchotronSwipeParams(Punchotron.LeftBladeLocation, Punchotron.RightBladeLocation));
		if (ActiveDuration > 1.6 && ActiveDuration < 1.8)
			UIslandPunchotronEffectHandler::Trigger_OnRightSwipe(Owner, FIslandPunchotronSwipeParams(Punchotron.LeftBladeLocation, Punchotron.RightBladeLocation));

		if (ActiveDuration > Settings.HaywireAttackDuration * (TelegraphFraction + AnticipationFraction) &&
			ActiveDuration < Settings.HaywireAttackDuration * (TelegraphFraction + AnticipationFraction + ActionFraction) )
		{
			if (!Owner.IsCapabilityTagBlocked(n"DamagePlayerOnTouch"))
				Owner.BlockCapabilities(n"DamagePlayerOnTouch", this);
			FVector ImpactLocation;
			ImpactLocation = Owner.ActorLocation + Owner.ActorForwardVector * Settings.HaywireAttackHitOffset;
			for (AHazePlayerCharacter Player : Game::Players)
			{	
				if (!Player.HasControl())
					continue;
				if (HasHitPlayer[Player])
					continue;
							
				if (ImpactLocation.IsWithinDist(Player.ActorLocation, Settings.HaywireAttackHitRadius))
				{
					HasHitPlayer[Player] = true;
					Player.DealTypedDamage(Owner, Settings.HaywireAttackDamage, EDamageEffectType::ObjectSmall, EDeathEffectType::ObjectSmall);

					float KnockdownDistance = Settings.KnockdownDistance;
					float KnockdownDuration = Settings.KnockdownDuration;;
					if (KnockdownDistance > 0.0)
					{
						FKnockdown Knockdown;
						Knockdown.Move = Owner.ActorForwardVector * KnockdownDistance;
						Knockdown.Duration = KnockdownDuration;
						Player.ApplyKnockdown(Knockdown);
					}
					AttackComp.bEnableTaunt = true;
				}
			}
#if EDITOR
		// Draw hit sphere
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool) 
			Debug::DrawDebugSphere(ImpactLocation, Settings.HaywireAttackHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
#endif
		}

		UpdateMovement();

#if EDITOR
		// Draw attack ranges
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			PrintScaled(f"HaywireAttack, ActiveDuration={ActiveDuration:.2} out of " + Settings.HaywireAttackDuration, 0.0, Scale = 2.f);
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.HaywireMaxAttackRange, FLinearColor::Blue, Duration = 3.0);
		}
#endif

	}

	private void UpdateMovement()
	{	
		if (ActiveDuration < Settings.HaywireAttackDuration * (TelegraphFraction + AnticipationFraction + ActionFraction))
		{
			FVector Destination = TargetComp.Target.ActorLocation;
			if (PathingSettings.bIgnorePathfinding)
			 	DestinationComp.MoveTowardsIgnorePathfinding(Destination, Settings.HaywireAttackMoveSpeed);
			else
			 	DestinationComp.MoveTowards(Destination, Settings.HaywireAttackMoveSpeed);
			 DestinationComp.RotateTowards(Destination);
		}	
	}

	private void SlideAwayFromTarget()
	{
		if (TargetComp.HasValidTarget())
		{
			// Slide away from target if close
			float CloseRange = 50.0;
			if (TargetComp.Target.ActorLocation.IsWithinDist(Owner.ActorLocation, CloseRange))
			 	DestinationComp.AddCustomAcceleration(-Owner.ActorForwardVector * 2000.0);
		}
	}
	
}

