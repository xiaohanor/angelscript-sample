class UIslandPunchotronSidescrollerHaywireAttackBehaviour : UBasicBehaviour
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

	AAIIslandPunchotronSidescroller Punchotron;
	FBasicAIAnimationActionDurations AttackDurations;
	private const float TelegraphFraction = 0.20;
	private const float AnticipationFraction = 0.05;
	private const float ActionFraction = 0.525;
	private const float RecoveryFraction = 0.15;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
		CooldownComp = UIslandPunchotronCooldownComponent::GetOrCreate(Owner);
		Punchotron = Cast<AAIIslandPunchotronSidescroller>(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);

		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
	}
	
	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (Math::Abs(Owner.ActorCenterLocation.Z - TargetComp.Target.ActorCenterLocation.Z) > 200) // Don't perform attack when on platform above or below player
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.SidescrollerHaywireMaxAttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.SidescrollerHaywireMinAttackRange))
			return false;
		FVector ToTarget = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation).GetSafeNormal2D();
		if (Owner.ActorForwardVector.DotProduct(ToTarget) < 0.0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
#if EDITOR
		if (Cast<AAIIslandPunchotronSidescroller>(Owner).bIsHaywireDisabled)
			return false;
#endif
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		if (!IslandPunchotron::IsOnGround(Owner.ActorLocation, 20.0, PathingSettings.bIgnorePathfinding))
			return false;
		if (!CooldownComp.IsCooldownOver(Owner.Class))
			return false;
		if (AttackComp.bIsAttacking)
			return false;

		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AttackComp.bIsAttacking = true;
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
				
		AttackDurations.Telegraph =  Settings.HaywireAttackDuration * TelegraphFraction;
		AttackDurations.Anticipation = Settings.HaywireAttackDuration * AnticipationFraction;
		AttackDurations.Action = Settings.HaywireAttackDuration *  ActionFraction;
		AttackDurations.Recovery = Settings.HaywireAttackDuration * RecoveryFraction;
		AnimComp.RequestAction(FeatureTagIslandPunchotron::HaywireAttack, EBasicBehaviourPriority::Medium, this, AttackDurations);

		UIslandPunchotronEffectHandler::Trigger_OnSawbladeAttackSwing(Owner);
		
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
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AttackComp.bIsAttacking = false;
		// Attack specific cooldown
		Cooldown.Set(Settings.HaywireAttackCooldown + Math::RandRange(-Settings.HaywireAttackCooldownDeviationRange, Settings.HaywireAttackCooldownDeviationRange));
		// Cooldown between each attack variant
		CooldownComp.SetCooldown(Owner.Class, Settings.GlobalAttackCooldown + Math::RandRange(-Settings.GlobalAttackCooldownDeviationRange, Settings.GlobalAttackCooldownDeviationRange));
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		AnimComp.ClearFeature(this);
		Cooldown.Set(1.0);
		UIslandPunchotronEffectHandler::Trigger_OnEyeTelegraphingStop(Owner);
		bHasStartedEyeTelegraphing = false;
	}

	bool bHasStartedEyeTelegraphing = false;
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AttackDurations.IsInTelegraphRange(ActiveDuration) && !bHasStartedEyeTelegraphing)
		{
			UIslandPunchotronEffectHandler::Trigger_OnEyeTelegraphingStart(Owner, FIslandPunchotronEyeTelegraphingParams(Punchotron.EyeTelegraphingLocation));
			bHasStartedEyeTelegraphing = true;
		}
		else if (ActiveDuration > AttackDurations.Telegraph && bHasStartedEyeTelegraphing)
		{
			UIslandPunchotronEffectHandler::Trigger_OnEyeTelegraphingStop(Owner);
			bHasStartedEyeTelegraphing = false;
		}
		
		if (AttackDurations.IsInActionRange(ActiveDuration))
		{
			FVector ImpactLocation;
			ImpactLocation = Owner.ActorCenterLocation + Owner.ActorForwardVector * Settings.SidescrollerHaywireAttackHitOffset;
			for (AHazePlayerCharacter Player : Game::Players)
			{	
				if (!Player.HasControl())
					continue;
				if (IslandPunchotron::IsPlayerDashing(Player))
					continue;
				if (HasHitPlayer[Player])
					continue;
							
				if (ImpactLocation.IsWithinDist(Player.ActorLocation, Settings.SidescrollerHaywireAttackHitRadius))
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
			Debug::DrawDebugSphere(ImpactLocation, Settings.SidescrollerHaywireAttackHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
#endif
		}

		UpdateMovement();

#if EDITOR
		// Draw attack ranges
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.HaywireMaxAttackRange, FLinearColor::Blue, Duration = 3.0);
		}
#endif

	}

	private void UpdateMovement()
	{		
		if (!AttackDurations.IsInRecoveryRange(ActiveDuration))
		{
			FVector Destination = Owner.ActorLocation + Owner.ActorForwardVector * 100;
			float SpeedScale = 1.0;
			if (TargetComp.HasValidTarget())
			{
				float SqrDistToTarget = (TargetComp.Target.ActorLocation - Owner.ActorLocation).SizeSquared();
				SpeedScale = Math::Clamp(SqrDistToTarget / (Settings.SidescrollerHaywireMaxAttackRange * Settings.SidescrollerHaywireMaxAttackRange), 0.25, 1);
			}
			if (PathingSettings.bIgnorePathfinding)
				DestinationComp.MoveTowardsIgnorePathfinding(Destination, Settings.SidescrollerHaywireAttackMoveSpeed * SpeedScale);
			else
				DestinationComp.MoveTowards(Destination, Settings.SidescrollerHaywireAttackMoveSpeed * SpeedScale);
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

