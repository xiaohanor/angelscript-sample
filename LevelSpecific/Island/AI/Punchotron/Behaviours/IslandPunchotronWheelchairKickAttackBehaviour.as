class UIslandPunchotronWheelchairKickAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	default CapabilityTags.Add(BasicAITags::Attack);

	UGentlemanCostComponent GentCostComp;
	UBasicAIHealthComponent HealthComp;
	UIslandPunchotronAttackComponent AttackComp;
	UIslandPunchotronCooldownComponent CooldownComp;
	UIslandPunchotronPanelTriggerComponent PanelComp;
	UIslandPunchotronSettings Settings;
	UPathfollowingSettings PathingSettings;
	TPerPlayer<bool> HasHitPlayer;
	
	AAIIslandPunchotron Punchotron;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
		CooldownComp = UIslandPunchotronCooldownComponent::GetOrCreate(Owner);
		PanelComp = UIslandPunchotronPanelTriggerComponent::GetOrCreate(Owner);
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
		if (AttackComp.AttackState != EIslandPunchotronAttackState::WheelchairKickAttack)
		 	return false;
		if (AttackComp.bIsAttacking)
			return false;
		if (PanelComp.bIsOnPanel)
			return false;
		if (!CooldownComp.IsCooldownOver(Owner.Class))
			return false;
		if (!Cooldown.IsOver())
			return false; 
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.WheelchairKickAttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.WheelchairKickAttackMinRange))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		if (!IslandPunchotron::IsOnGround(Owner.ActorLocation, 40.0, PathingSettings.bIgnorePathfinding))
			return false;
		if (!PathingSettings.bIgnorePathfinding)
		{
			FVector NavmeshLocation;
			if (!Pathfinding::FindNavmeshLocation(TargetComp.Target.ActorLocation, 10.0, 200.0, NavmeshLocation))
				return false;

			if (!Pathfinding::StraightPathExists(Owner.ActorLocation, NavmeshLocation))
				return false;
		}
		return true;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AttackComp.bIsAttacking = true;
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		bHasStartedTelegraphing = false;
		bHasEndedTelegraphing = false;

		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
		CurrentTargetLocation = FVector::ZeroVector;

		Punchotron.AttackDecalComp.Hide();
		Punchotron.AttackDecalComp.Reset();
		Punchotron.AttackTargetDecalComp.Hide();
		Punchotron.AttackTargetDecalComp.Reset();

		RequestAnimation();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.WheelchairKickAttackDuration)
			return true;
		UPlayerGrappleComponent GrappleComp = UPlayerGrappleComponent::Get(TargetComp.Target);
		if (GrappleComp.Data.CurrentGrapplePoint != nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AttackComp.bIsAttacking = false;
		float CooldownTime = Settings.WheelchairKickAttackCooldown + Settings.CooldownDuration;
		CooldownComp.SetCooldown(Owner.Class, CooldownTime); // cooldown between each attack variant
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		AnimComp.ClearFeature(this);
		AttackComp.NextAttackState();
		//UIslandPunchotronEffectHandler::Trigger_OnSpinningAttackTelegraphingStop(Owner); // TODO: fix event name or create new
		Punchotron.AttackTargetDecalComp.FadeOut(0.25);
		Punchotron.AttackTargetDecalComp.AttachTo(Owner.RootComponent);
		if (Owner.IsCapabilityTagBlocked(n"DamagePlayerOnTouch"))
			Owner.UnblockCapabilities(n"DamagePlayerOnTouch", this);
		UIslandPunchotronEffectHandler::Trigger_OnFlameThrowerStop(Owner);
	}

	bool bHasEndedTelegraphing = false;
	bool bHasStartedTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Telegraphing phase
		if (ActiveDuration < Settings.WheelchairKickAttackTelegraphDuration)
		{
			if (!bHasStartedTelegraphing)
			{
				UIslandPunchotronEffectHandler::Trigger_OnWheelchairKickAttackTelegraphingStart(Owner, FIslandPunchotronWheelchairKickAttackTelegraphingParams(Punchotron.EyeTelegraphingLocation, TargetComp.Target, Cast<AHazePlayerCharacter>(TargetComp.Target).CapsuleComponent));
				//Punchotron.AttackDecalComp.FadeIn();
				//UIslandPunchotronEffectHandler::Trigger_OnFlameThrowerStart(Owner, FIslandPunchotronFlameThrowerParams(Punchotron.LeftFlameThrowerLocation, Punchotron.RightFlameThrowerLocation));
				bHasStartedTelegraphing = true;
			}
			Punchotron.AttackDecalComp.LerpWorldLocationTo(TargetComp.Target.ActorLocation, DeltaTime, Settings.WheelchairKickAttackTelegraphDuration * 0.25);
		}
		else if (!bHasEndedTelegraphing)  // End of Telegraphing phase
		{
			bHasEndedTelegraphing = true;
			UIslandPunchotronEffectHandler::Trigger_OnWheelchairKickAttackTelegraphingStop(Owner);
			//UIslandPunchotronEffectHandler::Trigger_OnSpinningAttackTelegraphingStop(Owner); // TODO: fix event name or create new

			// Switch to locked target decal
			Punchotron.AttackDecalComp.FadeOut();
			Punchotron.AttackTargetDecalComp.SetWorldLocation(Punchotron.AttackDecalComp.WorldLocation);
			//Punchotron.AttackTargetDecalComp.FadeIn(0.5);
			Punchotron.AttackTargetDecalComp.DetachFromParent(true);
		}
		// Action phase - activate hitbox during time window
		else if (ActiveDuration > Settings.WheelchairKickAttackTelegraphDuration &&
			ActiveDuration < Settings.WheelchairKickAttackTelegraphDuration + Settings.WheelchairKickAttackActionDuration)
		{
			if (!Owner.IsCapabilityTagBlocked(n"DamagePlayerOnTouch"))
				Owner.BlockCapabilities(n"DamagePlayerOnTouch", this);
			FVector ImpactLocation;
			ImpactLocation = Owner.ActorLocation + Owner.ActorForwardVector * Settings.WheelchairKickAttackHitOffset;
			for (AHazePlayerCharacter Player : Game::Players)
			{	
				if (!Player.HasControl())
					continue;
				if (HasHitPlayer[Player])
					continue;
							
				if (ImpactLocation.IsWithinDist(Player.ActorLocation, Settings.WheelchairKickAttackHitRadius))
				{
					HasHitPlayer[Player] = true;
					Player.DamagePlayerHealth(Settings.WheelchairKickAttackDamage);

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
			{
				Debug::DrawDebugSphere(ImpactLocation, Settings.WheelchairKickAttackHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
			}
#endif
		}
		else
		{
			AnimComp.ClearFeature(this);
		}

		UpdateMovement(DeltaTime);

#if EDITOR
		// Draw attack ranges
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			PrintScaled(f"WheelchairKickAttack, ActiveDuration={ActiveDuration:.2} out of " + Settings.WheelchairKickAttackDuration, 0.0, Scale = 2.f);
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.WheelchairKickAttackMaxRange, FLinearColor::DPink, Duration = 3.0);
		}
#endif

	}

	private void UpdateMovement(const float DeltaTime)
	{	
		if (ActiveDuration < Settings.WheelchairKickAttackTelegraphDuration)
		{
			if (TargetComp.HasValidTarget())
				DestinationComp.RotateTowards(TargetComp.Target.ActorLocation);
			return;
		}

		if (ActiveDuration < Settings.WheelchairKickAttackTelegraphDuration + Settings.WheelchairKickAttackActionDuration)
		{
			UpdateTargetLocation(DeltaTime);

			if (CurrentTargetLocation.IsZero())
				return;

			if (PathingSettings.bIgnorePathfinding)
				DestinationComp.MoveTowardsIgnorePathfinding(CurrentTargetLocation, Settings.WheelchairKickAttackMoveSpeed);
			else
				DestinationComp.MoveTowards(CurrentTargetLocation, Settings.WheelchairKickAttackMoveSpeed);

		}
	}

	// If trying to activate during cooldown, skip to next attack state.
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (AttackComp.AttackState != EIslandPunchotronAttackState::WheelchairKickAttack)
		 	return;

		if (!Cooldown.IsOver())
			AttackComp.NextAttackState();
	}

	FVector CurrentTargetLocation;
	private void UpdateTargetLocation(const float DeltaTime)
	{
		if (!TargetComp.HasValidTarget())
			return;

		CurrentTargetLocation = TargetComp.Target.ActorLocation;
	}
	

	void RequestAnimation()
	{
		//AnimComp.RequestFeature(FeatureTagIslandPunchotron::WheelchairFire, EBasicBehaviourPriority::Medium, this);
		AnimComp.RequestFeature(FeatureTagIslandPunchotron::WheelchairKick, EBasicBehaviourPriority::Medium, this);
	}
}

