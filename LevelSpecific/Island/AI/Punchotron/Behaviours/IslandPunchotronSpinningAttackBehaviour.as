class UIslandPunchotronSpinningAttackBehaviour : UBasicBehaviour
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
	TPerPlayer<bool> HasHitPlayer;
	
	private const float TelegraphFraction = 0.25;
	private const float AnticipationFraction = 0.05;
	private const float ActionFraction = 0.3;
	private const float RecoveryFraction = 0.1;

	AAIIslandPunchotron Punchotron;

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
		if (AttackComp.bIsAttacking)
			return false;
		if (!CooldownComp.IsCooldownOver(Owner.Class))
			return false;
		if (!Cooldown.IsOver())
			return false; 
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.SpinningAttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.SpinningAttackMinRange))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		if (!IslandPunchotron::IsOnGround(Owner.ActorLocation, 40.0, PathingSettings.bIgnorePathfinding))
			return false;

		return true;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AttackComp.bIsAttacking = true;
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		bHasStartedAttackAnimation = false;
		bHasStartedTelegraphing = false;

		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
		CurrentTargetLocation = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.SpinningAttackTelegraphDuration + Settings.SpinningAttackDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AttackComp.bIsAttacking = false;
		float CooldownTime = Settings.SpinningAttackCooldown + Settings.CooldownDuration;
		CooldownComp.SetCooldown(Owner.Class, CooldownTime); // cooldown between each attack variant
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		AnimComp.ClearFeature(this);
		//AttackComp.NextAttackState();
		UIslandPunchotronEffectHandler::Trigger_OnSpinningAttackTelegraphingStop(Owner);
		UIslandPunchotronEffectHandler::Trigger_OnJetsStop(Owner);
	}

	bool bHasStartedAttackAnimation = false;
	bool bHasStartedTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < Settings.SpinningAttackTelegraphDuration)
		{
			if (!bHasStartedTelegraphing)
				UIslandPunchotronEffectHandler::Trigger_OnSpinningAttackTelegraphingStart(Owner, FIslandPunchotronSpinningAttackTelegraphingParams(Punchotron.EyeTelegraphingLocation, TargetComp.Target));
			bHasStartedTelegraphing = true;
		}
		else if (!bHasStartedAttackAnimation)
		{
			RequestAnimation();
			bHasStartedAttackAnimation = true;
			UIslandPunchotronEffectHandler::Trigger_OnSpinningAttackTelegraphingStop(Owner);
			UIslandPunchotronEffectHandler::Trigger_OnJetsStart(Owner, FIslandPunchotronJetsParams(Punchotron.LeftJetLocation, Punchotron.RightJetLocation));
		}

		// Activate hitbox during time window
		if (ActiveDuration > Settings.SpinningAttackTelegraphDuration &&
			ActiveDuration < Settings.SpinningAttackTelegraphDuration + Settings.SpinningAttackDuration)
		{
			FVector ImpactLocation;
			ImpactLocation = Owner.ActorLocation + Owner.ActorForwardVector * Settings.SpinningAttackHitOffset;
			for (AHazePlayerCharacter Player : Game::Players)
			{	
				if (!Player.HasControl())
					continue;
				if (HasHitPlayer[Player])
					continue;
							
				if (ImpactLocation.IsWithinDist(Player.ActorLocation, Settings.SpinningAttackHitRadius))
				{
					HasHitPlayer[Player] = true;
					Player.DamagePlayerHealth(Settings.SpinningAttackDamage);

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
			Debug::DrawDebugSphere(ImpactLocation, Settings.SpinningAttackHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
#endif
		}

		UpdateMovement(DeltaTime);

#if EDITOR
		// Draw attack ranges
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			PrintScaled(f"SpinningAttack, ActiveDuration={ActiveDuration:.2} out of " + Settings.SpinningAttackDuration, 0.0, Scale = 2.f);
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.SpinningAttackMaxRange, FLinearColor::DPink, Duration = 3.0);
		}
#endif

	}

	private void UpdateMovement(const float DeltaTime)
	{	
		if (ActiveDuration < Settings.SpinningAttackTelegraphDuration)
		{
			if (TargetComp.HasValidTarget())
				DestinationComp.RotateTowards(TargetComp.Target.ActorLocation);
		}
		if (ActiveDuration > Settings.SpinningAttackTelegraphDuration)
		{
			UpdateTargetLocation(DeltaTime);

			if (CurrentTargetLocation.IsZero())
				return;

			if (PathingSettings.bIgnorePathfinding)
				DestinationComp.MoveTowardsIgnorePathfinding(CurrentTargetLocation, Settings.SpinningAttackMoveSpeed);
			else
				DestinationComp.MoveTowards(CurrentTargetLocation, Settings.SpinningAttackMoveSpeed);
		}
	}

	FVector CurrentTargetLocation;
	private void UpdateTargetLocation(const float DeltaTime)
	{
		if (!TargetComp.HasValidTarget())
			return;

		CurrentTargetLocation = TargetComp.Target.ActorLocation; // this may be in the ground or up in the air.
		if (!PathingSettings.bIgnorePathfinding)
		{
			FVector NavmeshLocation;
			if (Pathfinding::FindNavmeshLocation(CurrentTargetLocation, 10, 500, NavmeshLocation))
				CurrentTargetLocation = NavmeshLocation;
		}
		else
		{
			FVector GroundLocation;
			if (IslandPunchotron::GetGroundLocation(CurrentTargetLocation, 500, GroundLocation))
				CurrentTargetLocation = GroundLocation;
		}
	}
	

	void RequestAnimation()
	{
		FBasicAIAnimationActionDurations AttackDurations;
		AttackDurations.Telegraph =  Settings.SpinningAttackDuration * TelegraphFraction;
		AttackDurations.Anticipation = Settings.SpinningAttackDuration * AnticipationFraction;
		AttackDurations.Action = Settings.SpinningAttackDuration *  ActionFraction;
		AttackDurations.Recovery = Settings.SpinningAttackDuration * RecoveryFraction;
		//AnimComp.RequestAction(FeatureTagIslandPunchotron::SpinAttack, EBasicBehaviourPriority::Medium, this, AttackDurations);
		AnimComp.RequestFeature(FeatureTagIslandPunchotron::SpinAttack, EBasicBehaviourPriority::Medium, this);
	}
}

