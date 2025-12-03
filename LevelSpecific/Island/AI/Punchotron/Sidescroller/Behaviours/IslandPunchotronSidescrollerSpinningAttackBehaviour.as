class UIslandPunchotronSidescrollerSpinningAttackBehaviour : UBasicBehaviour
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
	
	private const float TelegraphFraction = 0.55;
	private const float AnticipationFraction = 0.05;
	private const float ActionFraction = 0.3;
	private const float RecoveryFraction = 0.1;
	private float MovementDuration;


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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.SpinningAttackMaxRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.SpinningAttackMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		if (!IslandPunchotron::IsOnGround(Owner.ActorLocation, 20.0, PathingSettings.bIgnorePathfinding))
			return false;
		if ( Math::Abs(Owner.ActorLocation.Z - TargetComp.Target.ActorLocation.Z) > 300)
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
		

		FBasicAIAnimationActionDurations AttackDurations;
		AttackDurations.Telegraph =  Settings.SpinningAttackDuration * TelegraphFraction;
		AttackDurations.Anticipation = Settings.SpinningAttackDuration * AnticipationFraction;
		AttackDurations.Action = Settings.SpinningAttackDuration *  ActionFraction;
		AttackDurations.Recovery = Settings.SpinningAttackDuration * RecoveryFraction;
		AnimComp.RequestAction(FeatureTagIslandPunchotron::SpinAttack, EBasicBehaviourPriority::Medium, this, AttackDurations);
			
		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
		CurrentTargetLocation = FVector::ZeroVector;

		MovementDuration = AttackDurations.Action;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.SpinningAttackDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AttackComp.bIsAttacking = false;
		// Attack specific cooldown
		Cooldown.Set(Settings.SpinningAttackCooldown + Math::RandRange(-Settings.SpinningAttackCooldownDeviationRange, Settings.SpinningAttackCooldownDeviationRange));
		// Cooldown between each attack variant
		CooldownComp.SetCooldown(Owner.Class, Settings.GlobalAttackCooldown + Math::RandRange(-Settings.GlobalAttackCooldownDeviationRange, Settings.GlobalAttackCooldownDeviationRange));
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		AnimComp.ClearFeature(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// Activate hitbox during time window
		if (ActiveDuration > Settings.SpinningAttackDuration * (TelegraphFraction + AnticipationFraction) &&
			ActiveDuration < Settings.SpinningAttackDuration * (TelegraphFraction + AnticipationFraction + ActionFraction) )
		{
			FVector ImpactLocation;
			ImpactLocation = Owner.ActorCenterLocation;
			for (AHazePlayerCharacter Player : Game::Players)
			{	
				if (!Player.HasControl())
					continue;
				if (HasHitPlayer[Player])
					continue;
							
				if (ImpactLocation.IsWithinDist(Player.ActorLocation, Settings.SidescrollerSpinningAttackHitRadius))
				{
					HasHitPlayer[Player] = true;
					Player.DealTypedDamage(Owner, Settings.SpinningAttackDamage, EDamageEffectType::ObjectSmall, EDeathEffectType::ObjectSmall);

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
			Debug::DrawDebugSphere(ImpactLocation, Settings.SidescrollerSpinningAttackHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
#endif
		}

		UpdateMovement(DeltaTime);

#if EDITOR
		// Draw attack ranges
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.SpinningAttackMaxRange, FLinearColor::DPink, Duration = 3.0);
		}
#endif

	}

	private void UpdateMovement(const float DeltaTime)
	{	
		if (ActiveDuration < TelegraphFraction * Settings.SpinningAttackDuration)
		{
			if (TargetComp.HasValidTarget())
				DestinationComp.RotateTowards(TargetComp.Target.ActorLocation);
			return;
		}

		if (ActiveDuration < Settings.SpinningAttackDuration * (TelegraphFraction + AnticipationFraction + ActionFraction))
		{
  			if (CurrentTargetLocation.IsZero())
			{
				UpdateTargetLocation();
				return;
			}

			if (PathingSettings.bIgnorePathfinding)
				DestinationComp.MoveTowardsIgnorePathfinding(CurrentTargetLocation, Settings.SpinningAttackMoveSpeed);
			else
				DestinationComp.MoveTowards(CurrentTargetLocation, Settings.SpinningAttackMoveSpeed);
		}
	}

	FVector CurrentTargetLocation;
	private void UpdateTargetLocation()
	{
		if (!TargetComp.HasValidTarget())
			return;

		FVector TargetLocation = TargetComp.Target.ActorLocation;
		if (!PathingSettings.bIgnorePathfinding)
		{
			FVector NavmeshLocation;
			if (Pathfinding::FindNavmeshLocation(CurrentTargetLocation, 10, 500, NavmeshLocation))
				TargetLocation = NavmeshLocation;
		}
		else
		{
			FVector GroundLocation;
			if (IslandPunchotron::GetGroundLocation(CurrentTargetLocation, 500, GroundLocation))
				CurrentTargetLocation = GroundLocation;
		}


		FVector MoveDir = (TargetLocation - Owner.ActorLocation).GetSafeNormal2D();
		float Sign = Math::Sign(MoveDir.X);
		Sign = Math::IsNearlyEqual(Sign, 0) ? 1.0 : Sign;
		CurrentTargetLocation = Owner.ActorLocation;
		CurrentTargetLocation.X += Sign * MovementDuration * Settings.SpinningAttackMoveSpeed; // this may be in the ground or up in the air.
	}
	
}

