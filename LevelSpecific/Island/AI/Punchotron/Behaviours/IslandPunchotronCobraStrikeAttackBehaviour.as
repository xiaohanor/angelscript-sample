class UIslandPunchotronCobraStrikeAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	default CapabilityTags.Add(BasicAITags::Attack);
	default CapabilityTags.Add(n"CobraStrike");

	UGentlemanCostComponent GentCostComp;
	UBasicAIHealthComponent HealthComp;
	UIslandPunchotronAttackComponent AttackComp;
	UIslandPunchotronCooldownComponent CooldownComp;
	UIslandPunchotronPanelTriggerComponent PanelComp;
	UIslandPunchotronSettings Settings;
	UPathfollowingSettings PathingSettings;
	TPerPlayer<bool> HasHitPlayer;
	
	AAIIslandPunchotron Punchotron;

	FBasicAIAnimationActionDurations Durations;

	bool bHasStartedBreaking = false;
	bool bHasStartedBreakingHard = false;
	FVector ChargeStartLocation;

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
		if (AttackComp.AttackState != EIslandPunchotronAttackState::CobraStrikeAttack)
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
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		if(Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.CobraStrikeAttackMinRange))
		 	return false;
		if(!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.CobraStrikeAttackMaxRange))
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
		bHasEndedTelegraphing = false;
		bHasStartedTelegraphing = false;

		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
		CurrentTargetLocation = FVector::ZeroVector;

		Punchotron.AttackDecalComp.Hide();
		Punchotron.AttackDecalComp.Reset();
		Punchotron.AttackTargetDecalComp.Hide();
		Punchotron.AttackTargetDecalComp.Reset();

		Durations.Telegraph = Settings.CobraStrikeAttackTelegraphDuration;
		Durations.Anticipation = Settings.CobraStrikeAttackAnticipationDuration;
		Durations.Action = Settings.CobraStrikeAttackActionDuration;
		Durations.Recovery = Settings.CobraStrikeRecoveryDuration;		

		// Faster turns
		UIslandPunchotronSettings::SetTurnDuration(Owner, Settings.TurnDuration * 0.5, this);

		RequestAnimation();
		UIslandPunchotronEffectHandler::Trigger_OnCobraAttackTelegraphStart(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.CobraStrikeAttackDuration)
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
		float CooldownTime = Settings.CobraStrikeAttackCooldown + Settings.CooldownDuration;
		CooldownComp.SetCooldown(Owner.Class, CooldownTime); // cooldown between each attack variant
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		AnimComp.ClearFeature(this);
		AttackComp.NextAttackState();
		UIslandPunchotronEffectHandler::Trigger_OnSpinningAttackTelegraphingStop(Owner);
		UIslandPunchotronEffectHandler::Trigger_OnJetsStop(Owner);		
		Punchotron.AttackTargetDecalComp.FadeOut(0.25);
		Punchotron.AttackTargetDecalComp.AttachTo(Owner.RootComponent);
		UIslandPunchotronSettings::ClearTurnDuration(Owner, this);
		UIslandPunchotronSettings::ClearGroundFriction(Owner, this);
		bHasStartedBreaking = false;
		bHasStartedBreakingHard = false;
		if (Owner.IsCapabilityTagBlocked(n"DamagePlayerOnTouch"))
			Owner.UnblockCapabilities(n"DamagePlayerOnTouch", this);		
	}

	bool bHasEndedTelegraphing = false;
	bool bHasStartedTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Telegraphing phase / Anticipation phase				
		if (Durations.IsInAnticipationRange(ActiveDuration))
		{
			CobraStrikeTelegraph(DeltaTime);
		}
		if (Durations.IsInActionRange(ActiveDuration) && !bHasEndedTelegraphing) // End of Telegraphing phase
		{
			OnTelegraphEnded();
		}
		// Action phase - activate hitbox during time window
		else if (Durations.IsInActionRange(ActiveDuration))
		{
			CobraStrikeAttack(DeltaTime);
		}
		else if (Durations.IsInRecoveryRange(ActiveDuration))
		{
			// Restore contact damage
			if (Owner.IsCapabilityTagBlocked(n"DamagePlayerOnTouch"))
				Owner.UnblockCapabilities(n"DamagePlayerOnTouch", this);
		}

		UpdateMovement(DeltaTime);

#if EDITOR
		DebugDraw();		
#endif
	}

	void CobraStrikeTelegraph(float DeltaTime)
	{
		if (!bHasStartedTelegraphing)
		{
			UIslandPunchotronEffectHandler::Trigger_OnSpinningAttackTelegraphingStart(Owner, FIslandPunchotronSpinningAttackTelegraphingParams(Punchotron.EyeTelegraphingLocation, TargetComp.Target));
			Punchotron.AttackDecalComp.FadeIn();
			bHasStartedTelegraphing = true;
		}
		Punchotron.AttackDecalComp.LerpWorldLocationTo(TargetComp.Target.ActorLocation, DeltaTime, Settings.CobraStrikeAttackTelegraphDuration * 0.25);
	}

	void OnTelegraphEnded()
	{	
		bHasEndedTelegraphing = true;
		UIslandPunchotronEffectHandler::Trigger_OnSpinningAttackTelegraphingStop(Owner);			
		UIslandPunchotronEffectHandler::Trigger_OnJetsStart(Owner, FIslandPunchotronJetsParams(Punchotron.LeftJetLocation, Punchotron.RightJetLocation));
		
		// Switch to locked target decal
		Punchotron.AttackDecalComp.FadeOut();
		Punchotron.AttackTargetDecalComp.SetWorldLocation(Punchotron.AttackDecalComp.WorldLocation);
		Punchotron.AttackTargetDecalComp.FadeIn(0.5);
		Punchotron.AttackTargetDecalComp.DetachFromParent(true);
		
		if (!Owner.IsCapabilityTagBlocked(n"DamagePlayerOnTouch"))
			Owner.BlockCapabilities(n"DamagePlayerOnTouch", this);
	}

	void CobraStrikeAttack(float DeltaTime)
	{
		FVector ImpactLocation;
		ImpactLocation = Owner.ActorLocation + Owner.ActorForwardVector * Settings.CobraStrikeAttackHitOffset;
		for (AHazePlayerCharacter Player : Game::Players)
		{	
			if (!Player.HasControl())
				continue;
			if (HasHitPlayer[Player])
				continue;
						
			if (ImpactLocation.IsWithinDist(Player.ActorLocation, Settings.CobraStrikeAttackHitRadius))
			{
				HasHitPlayer[Player] = true;
				Player.DealTypedDamage(Owner, Settings.CobraStrikeAttackDamage, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);

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
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Sphere("HitSphere", ImpactLocation, Settings.CobraStrikeAttackHitRadius);
#endif
	}

	private void UpdateMovement(const float DeltaTime)
	{	
		// Telegraph phase - update target location
		if (Durations.IsInTelegraphRange(ActiveDuration) || Durations.IsInAnticipationRange(ActiveDuration))
		{
			if (TargetComp.HasValidTarget())
				DestinationComp.RotateTowards(TargetComp.Target.ActorLocation);
			UpdateTargetLocation(DeltaTime);
			DestinationComp.MoveTowards(CurrentDestinationLocation, Settings.CobraStrikeTelegraphingMoveSpeed);
			ChargeStartLocation = Owner.ActorLocation; // constantly updated until action phase.
		}
		// Action phase
		else if (Durations.IsInActionRange(ActiveDuration))
		{
			float MoveSpeed = Settings.CobraStrikeAttackMoveSpeed;

			// Increased initial acceleration
			if (ActiveDuration < Durations.Telegraph + Durations.Anticipation + 0.1)
				MoveSpeed *= 2.0;

			FVector ToChargeStartLocation = ChargeStartLocation - Owner.ActorLocation;
			float ToChargeStartLocationDist2D = ToChargeStartLocation.Size2D();
			FVector ToDestinationLocation = CurrentDestinationLocation - Owner.ActorLocation;
			float ToDestinationLocationDist2D = ToDestinationLocation.Size2D();			
			
			// If dist to current destination is shorter than to initial location, we may be overshooting soon
			if (ToDestinationLocationDist2D < ToChargeStartLocationDist2D)
			{
				// Start breaking if we have passed the destination location
				if (ToChargeStartLocation.GetSafeNormal2D().DotProduct(ToDestinationLocation.GetSafeNormal2D()) > 0.0)
				{
					CurrentDestinationLocation = Owner.ActorLocation + Owner.ActorForwardVector * 100;
					MoveSpeed = Settings.CobraStrikeAttackMoveSpeed * 0.01;
					if (!bHasStartedBreaking)
					{
						UIslandPunchotronSettings::SetGroundFriction(Owner, Settings.GroundFriction * 3.0, this);
						bHasStartedBreaking = true;
						
						UIslandPunchotronEffectHandler::Trigger_OnCobraAttackBrakeStart(Owner);
					}						

#if !RELEASE
					FTemporalLog TemporalLog = TEMPORAL_LOG(this);				
					TemporalLog.Event("CurrentDestinationLocation changed by overshoot!");
#endif
				}

				if (!bHasStartedBreakingHard)
				{					
					FHazeTraceSettings Trace;
					Trace = Trace::InitChannel(ECollisionChannel::EnemyCharacter);
					FHitResult HitResult;
					HitResult =	Trace.QueryTraceSingle(Owner.ActorCenterLocation, Owner.ActorCenterLocation + Owner.ActorVelocity.GetSafeNormal2D() * 1000);
					if (HitResult.bBlockingHit)
					{
						float Friction = bHasStartedBreaking ? Settings.GroundFriction * 3.5 : Settings.GroundFriction * 10.5;
						UIslandPunchotronSettings::SetGroundFriction(Owner, Friction, this);
						bHasStartedBreakingHard = true;

						UIslandPunchotronEffectHandler::Trigger_OnCobraAttackBrakeStart(Owner);
					}
				}
			}

			DestinationComp.MoveTowardsIgnorePathfinding(CurrentDestinationLocation, MoveSpeed);
		}
	}

	float DestinationOffset = 300.0; // Distance from target to stop movement		
	FVector CurrentTargetLocation;
	FVector CurrentDestinationLocation;
	private void UpdateTargetLocation(const float DeltaTime)
	{
		if (!TargetComp.HasValidTarget())
			return;

		CurrentTargetLocation = TargetComp.Target.ActorLocation; // this may be on the ground or up in the air.
		FVector ToTargetDir = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
		CurrentDestinationLocation = TargetComp.Target.ActorLocation + ToTargetDir * DestinationOffset;
	}
	

	void RequestAnimation()
	{
		AnimComp.RequestFeature(FeatureTagIslandPunchotron::CobraStrike, EBasicBehaviourPriority::Medium, this);
	}

#if EDITOR
	void DebugDraw()
	{
		//Owner.bHazeEditorOnlyDebugBool = true;

		// Draw attack ranges
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			PrintScaled(f"CobraStrikeAttack, ActiveDuration={ActiveDuration:.2} out of " + Settings.CobraStrikeAttackDuration, 0.0, Scale = 2.f);
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.CobraStrikeAttackMaxRange, FLinearColor::DPink, Duration = 3.0);
		}

		// Draw hit sphere
		FVector ImpactLocation;
		ImpactLocation = Owner.ActorLocation + Owner.ActorForwardVector * Settings.CobraStrikeAttackHitOffset;
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSphere(ImpactLocation, Settings.CobraStrikeAttackHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Sphere("CurrentTargetLocation", CurrentTargetLocation, 100, FLinearColor::Red);
		TemporalLog.Sphere("CurrentDestinationLocation", CurrentDestinationLocation, 100, FLinearColor::White);
		TemporalLog.Arrow("Owner.ActorVelocity.", Owner.ActorCenterLocation, Owner.ActorLocation + Owner.ActorVelocity * 5); // Scale length by factor 5.

		if (!TargetComp.HasValidTarget())
			return;		
		FVector ToTargetDir = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
		TemporalLog.Arrow("ToTargetDir", Owner.ActorLocation, Owner.ActorLocation + ToTargetDir * DestinationOffset);
		TemporalLog.Arrow("TargetComp.Target.ActorLocation + ToTargetDir", TargetComp.Target.ActorLocation, TargetComp.Target.ActorLocation + ToTargetDir * DestinationOffset);
	}
}

