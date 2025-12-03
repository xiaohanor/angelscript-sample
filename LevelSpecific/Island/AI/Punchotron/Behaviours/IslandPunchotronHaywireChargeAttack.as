class UIslandPunchotronHaywireChargeAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	default CapabilityTags.Add(BasicAITags::Attack);

	UIslandPunchotronCooldownComponent CooldownComp;
	UIslandPunchotronAttackComponent AttackComp;
	UIslandPunchotronPanelTriggerComponent PanelComp;
	UBasicAIHealthComponent HealthComp;

	UIslandPunchotronSettings Settings;
	UPathfollowingSettings PathingSettings;
	private TPerPlayer<bool> HasHitPlayer;

	AAIIslandPunchotron Punchotron;

	private const float TelegraphFraction = 0.35;
	private const float AnticipationFraction = 0.0;
	private const float ActionFraction = 0.35;
	private const float RecoveryFraction = 0.35;

	float AttackActivatedTime = 0.0;
	bool bIsAttackActivated = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		CooldownComp = UIslandPunchotronCooldownComponent::GetOrCreate(Owner);
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
		PanelComp = UIslandPunchotronPanelTriggerComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
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
		if (!TargetComp.HasValidTarget())
			return false;
		if (AttackComp.AttackState != EIslandPunchotronAttackState::HaywireAttack)
			return false;
		if (PanelComp.bIsOnPanel)
			return false;
		if (AttackComp.bIsAttacking)
			return false;
		if (!CooldownComp.IsCooldownOver(Owner.Class)) // check global cooldown
			return false;		
		if(!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.HaywireEngageMaxRange))
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
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (AttackActivatedTime > 0 && Time::GameTimeSeconds > AttackActivatedTime + Settings.HaywireAttackDuration)
			return true;
		UPlayerGrappleComponent GrappleComp = UPlayerGrappleComponent::Get(TargetComp.Target);
		if (GrappleComp.Data.CurrentGrapplePoint != nullptr)
			return true;
		return false;
	}

	FBasicAIAnimationActionDurations AttackDurations;
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bHasStartedTelegraphing = false;
		AttackComp.bIsAttacking = true;

		Punchotron.AttackDecalComp.Hide();
		Punchotron.AttackDecalComp.Reset();
		Punchotron.AttackTargetDecalComp.Hide();
		Punchotron.AttackTargetDecalComp.Reset();

		AttackDurations.Telegraph =  Settings.HaywireAttackDuration * TelegraphFraction;
		AttackDurations.Anticipation = Settings.HaywireAttackDuration * AnticipationFraction;
		AttackDurations.Action = Settings.HaywireAttackDuration *  ActionFraction;
		AttackDurations.Recovery = Settings.HaywireAttackDuration * RecoveryFraction;

		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
		AttackActivatedTime = 0.0;
		bIsAttackActivated = false;
		if (ActivatedSwings.Num() == 0)
		{
			ActivatedSwings.Reserve(3);
			ActivatedSwings.Add(false);
			ActivatedSwings.Add(false);
			ActivatedSwings.Add(false);
		}
		ActivatedSwings[0] = false;
		ActivatedSwings[1] = false;
		ActivatedSwings[2] = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AttackComp.bIsAttacking = false;
		UIslandPunchotronEffectHandler::Trigger_OnHaywireAttackTelegraphingStop(Owner);
		UIslandPunchotronEffectHandler::Trigger_OnJetsStop(Owner);
		Punchotron.AttackDecalComp.FadeOut();
		Punchotron.AttackTargetDecalComp.SetWorldLocation(Punchotron.AttackDecalComp.WorldLocation);

		float CooldownTime = Settings.HaywireAttackCooldown + Settings.CooldownDuration;
		CooldownComp.SetCooldown(Owner.Class, CooldownTime); // cooldown between each attack variant
		AnimComp.ClearFeature(this);
		AttackComp.NextAttackState();
		Punchotron.AttackTargetDecalComp.FadeOut(0.25);
		if (Owner.IsCapabilityTagBlocked(n"DamagePlayerOnTouch"))
			Owner.UnblockCapabilities(n"DamagePlayerOnTouch", this);
	}

	FVector CurrentDestinationLocation;
	bool bHasStartedTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateTargetDecals(DeltaTime);
		// Keep moving towards decals
		UpdateDestinationLocation();
		
		if (AttackActivatedTime > 0.0)
			HandleAttackPhase(DeltaTime);
		else
			HandleEngagePhase(DeltaTime);
	}

	void HandleEngagePhase(float DeltaTime)
	{
		// Telegraphing and activate search light
		if (ActiveDuration < Settings.HaywireEngageTelegraphDuration)
		{
			DestinationComp.RotateTowards(TargetComp.Target);
			DestinationComp.MoveTowards(TargetComp.Target.ActorLocation, Settings.HaywireTelegraphingMoveSpeed);
			return;
		}
		else if (ActiveDuration < Settings.HaywireEngageTelegraphDuration + Settings.HaywireEngageAnticipationDuration)
		{
			if (!bHasStartedTelegraphing && Owner.ActorForwardVector.DotProduct( (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D()) > 0)
			{
				UIslandPunchotronEffectHandler::Trigger_OnHaywireAttackTelegraphingStart(Owner, FIslandPunchotronHaywireAttackTelegraphingParams(Punchotron.EyeTelegraphingLocation, TargetComp.Target, Punchotron.AttackDecalComp));
				UIslandPunchotronPlayerEffectHandler::Trigger_OnHaywireAttackTelegraphingStart(Game::Mio, FIslandPunchotronHaywireAttackTelegraphingPlayerEventData(Punchotron, Punchotron.EyeTelegraphingLocation, TargetComp.Target));
				UIslandPunchotronPlayerEffectHandler::Trigger_OnHaywireAttackTelegraphingStart(Game::Zoe, FIslandPunchotronHaywireAttackTelegraphingPlayerEventData(Punchotron, Punchotron.EyeTelegraphingLocation, TargetComp.Target));
				Punchotron.AttackDecalComp.FadeIn();
				bHasStartedTelegraphing = true;				
			}
			DestinationComp.RotateTowards(TargetComp.Target);
			DestinationComp.MoveTowards(TargetComp.Target.ActorLocation, Settings.HaywireTelegraphingMoveSpeed);
			return;
		}
		// Swing away!
		else if (!bIsAttackActivated)
		{
			UIslandPunchotronEffectHandler::Trigger_OnHaywireAttackTelegraphingStop(Owner);
			UIslandPunchotronPlayerEffectHandler::Trigger_OnHaywireAttackTelegraphingStop(Game::Mio, FIslandPunchotronHaywireAttackTelegraphingPlayerEventData(Punchotron, Punchotron.EyeTelegraphingLocation, TargetComp.Target));
			UIslandPunchotronPlayerEffectHandler::Trigger_OnHaywireAttackTelegraphingStop(Game::Zoe, FIslandPunchotronHaywireAttackTelegraphingPlayerEventData(Punchotron, Punchotron.EyeTelegraphingLocation, TargetComp.Target));
			AttackActivatedTime = Time::GameTimeSeconds;
			bIsAttackActivated = true;
			AnimComp.RequestFeature(FeatureTagIslandPunchotron::HaywireAttack, EBasicBehaviourPriority::Medium, this);
		}
		
		if (!PathingSettings.bIgnorePathfinding)
			DestinationComp.MoveTowards(CurrentDestinationLocation, Settings.HaywireEngageMoveSpeed);
		else
			DestinationComp.MoveTowardsIgnorePathfinding(CurrentDestinationLocation, Settings.HaywireEngageMoveSpeed);
	}

	void UpdateTargetDecals(float DeltaTime)
	{
		if (IslandPunchotron::IsPlayerDashing(Cast<AHazePlayerCharacter>(TargetComp.Target)))
			return;

		// Move search light decal and target decal
		Punchotron.AttackDecalComp.LerpWorldLocationTo(TargetComp.Target.ActorLocation + TargetComp.Target.ActorVelocity * 0.3, DeltaTime, Settings. HaywireEngageTelegraphDuration * 0.25);
		Punchotron.AttackTargetDecalComp.SetWorldLocation(Punchotron.AttackDecalComp.WorldLocation);
	}

	void UpdateDestinationLocation()
	{
		FVector CurrentTargetLocation = Punchotron.AttackTargetDecalComp.WorldLocation;		
		if (HasHitPlayer[Cast<AHazePlayerCharacter>(TargetComp.Target)])
		{
			CurrentTargetLocation = Owner.ActorLocation + Owner.ActorForwardVector * 200; // Keep sliding on once target is downed.
		}
		CurrentDestinationLocation = CurrentTargetLocation;    
		if (!PathingSettings.bIgnorePathfinding)
		{
			FVector NavmeshLocation;
			if (Pathfinding::FindNavmeshLocation(CurrentDestinationLocation, 10, 500, NavmeshLocation))
				CurrentDestinationLocation = NavmeshLocation;
		}
		else
		{
			FVector GroundLocation;
			if (IslandPunchotron::GetGroundLocation(CurrentDestinationLocation, 500, GroundLocation))
				CurrentDestinationLocation = GroundLocation;
		}		
	}

	void HandleAttackPhase(float DeltaTime)
	{
		ActivateSwingEffects();
		HandleDamageDealing();
		UpdateAttackMovement(DeltaTime);

#if EDITOR
		DrawAttackRange();
#endif
	}


	TArray<bool> ActivatedSwings;
	void ActivateSwingEffects()
	{
		if (IsInTimeInterval(AttackActivatedTime, 0.6, 0.7) || (!ActivatedSwings[0] && IsPast(AttackActivatedTime + 0.4)) )
		{
			UIslandPunchotronEffectHandler::Trigger_OnRightSwipe(Owner, FIslandPunchotronSwipeParams(Punchotron.LeftBladeLocation, Punchotron.RightBladeLocation));
			ActivatedSwings[0] = true;
		}
		if (IsInTimeInterval(AttackActivatedTime, 0.9, 1.0) || (!ActivatedSwings[0] && IsPast(AttackActivatedTime + 0.8)) )
		{
			UIslandPunchotronEffectHandler::Trigger_OnLeftSwipe(Owner, FIslandPunchotronSwipeParams(Punchotron.LeftBladeLocation, Punchotron.RightBladeLocation));
			ActivatedSwings[1] = true;
		}
		if (IsInTimeInterval(AttackActivatedTime, 1.3, 1.4) || (!ActivatedSwings[0] && IsPast(AttackActivatedTime + 1.2)) )
		{
			UIslandPunchotronEffectHandler::Trigger_OnRightSwipe(Owner, FIslandPunchotronSwipeParams(Punchotron.LeftBladeLocation, Punchotron.RightBladeLocation));
			ActivatedSwings[2] = true;
		}
	}

	void HandleDamageDealing()
	{
		if (IsInTimeInterval(AttackActivatedTime, 0.5, 1.75))
		{
			if (!Owner.IsCapabilityTagBlocked(n"DamagePlayerOnTouch"))
				Owner.BlockCapabilities(n"DamagePlayerOnTouch", this);
			FVector ImpactLocation;
			ImpactLocation = Owner.ActorCenterLocation + Owner.ActorForwardVector * Settings.HaywireAttackHitOffset;
			for (AHazePlayerCharacter Player : Game::Players)
			{	
				if (!Player.HasControl())
					continue;
				if (HasHitPlayer[Player])
					continue;
				if (IslandPunchotron::IsPlayerDashing(Player))
				 	continue;
							
				if (ImpactLocation.IsWithinDist(Player.ActorCenterLocation, Settings.HaywireAttackHitRadius))
				{
					HasHitPlayer[Player] = true;					
					Player.DealTypedDamage(Owner, Settings.HaywireAttackDamage, EDamageEffectType::ObjectSmall, EDeathEffectType::ObjectSmall);

					float KnockdownDistance = Settings.KnockdownDistance;
					float KnockdownDuration = Settings.KnockdownDuration;
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
	}

	void UpdateAttackMovement(float DeltaTime)
	{
		if (!AttackDurations.IsInRecoveryRange(Time::GameTimeSeconds - AttackActivatedTime))
		{
			float Speed = Settings.HaywireEngageMoveSpeed * 0.6;
			if (HasHitPlayer[Cast<AHazePlayerCharacter>(TargetComp.Target)])
			{
				float Friction = Settings.GroundFriction * 3.0;
				float FrictionFactor = Math::Pow(Math::Exp(-Friction), DeltaTime);
				Speed = Owner.ActorVelocity.Size2D() * FrictionFactor;
			}

			if (PathingSettings.bIgnorePathfinding)
			 	DestinationComp.MoveTowardsIgnorePathfinding(CurrentDestinationLocation, Speed);
			else
				DestinationComp.MoveTowards(CurrentDestinationLocation, Speed);
			
			if (!HasHitPlayer[Cast<AHazePlayerCharacter>(TargetComp.Target)])
				DestinationComp.RotateTowards(TargetComp.Target.ActorLocation);
		}
	}

	bool IsInTimeInterval(float Time, float A, float B)
	{
		if (Time::GameTimeSeconds < Time + A)
			return false;
		if (Time::GameTimeSeconds > Time + B)
			return false;
		return true;
	}

	bool IsPast(float Time)
	{
		if (Time::GameTimeSeconds > Time)
			return true;
		return false;
	}


#if EDITOR
	void DrawAttackRange()
	{
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			PrintScaled(f"HaywireAttack, ActiveDuration={ActiveDuration:.2} out of " + Settings.HaywireAttackDuration, 0.0, Scale = 2.f);
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.HaywireMaxAttackRange, FLinearColor::Blue, Duration = 3.0);
		}
	}
#endif

}
