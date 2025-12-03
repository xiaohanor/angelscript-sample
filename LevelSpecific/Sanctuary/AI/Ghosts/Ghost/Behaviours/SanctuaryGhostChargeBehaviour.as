class USanctuaryGhostChargeBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(SanctuaryGhostCommonTags::SanctuaryGhostDarkPortalBlock);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	USanctuaryGhostSettings GhostSettings;
	UBasicAIHealthComponent HealthComp;

	FBasicAIAnimationActionDurations AttackDuration;
	FVector AttackTargetLocation;
	FVector AttackStartLocation;
	float MinAttackDot = -1.0;
	AHazeActor Target;
	FVector RecoveryDirection;
	TArray<AHazeActor> AvailableTargets;
	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		GhostSettings = USanctuaryGhostSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MinAttackDot = Math::Cos(Math::DegreesToRadians(GhostSettings.ChargeMaxAngleDegrees));
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
#if EDITOR
		MinAttackDot = Math::Cos(Math::DegreesToRadians(GhostSettings.ChargeMaxAngleDegrees));
#endif
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		if (!Owner.ActorLocation.IsWithinDist(TargetLoc, GhostSettings.ChargeRange))
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetLoc, GhostSettings.ChargeMinRange))
			return false;
		FVector ToTargetDir = (TargetLoc - Owner.ActorLocation).GetSafeNormal2D();
		if (Owner.ActorForwardVector.DotProduct(ToTargetDir) < MinAttackDot)
			return false;
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (PlayerTarget != nullptr)
		{
			FVector ViewYawDir = FRotator(0.0, PlayerTarget.ViewRotation.Yaw, 0.0).Vector();
			if (ViewYawDir.DotProduct(-ToTargetDir) < 0.7)
				return false;
		}

		if (!TargetComp.HasVisibleTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())		
			return false;
		if(!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this))
			return false;
		if(!GentCostComp.IsTokenAvailable(GhostSettings.ChargeGentlemanCost))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	
		Target = TargetComp.Target;
		AttackTargetLocation = Target.ActorLocation + Target.ActorVelocity * 1.5; // Simple prediction

		AttackDuration.Telegraph = GhostSettings.ChargeTelegraphDuration;
		AttackDuration.Anticipation = GhostSettings.ChargeAnticipationDuration; 
		AttackDuration.Action = GhostSettings.ChargeHitDuration; 
		AttackDuration.Recovery = GhostSettings.ChargeRecoveryDuration;
		AttackStartLocation = Owner.ActorLocation;
		FVector ToTarget = (AttackTargetLocation - AttackStartLocation);
		float TargetDistance = Math::Max(ToTarget.Size(), 1.0);
		FVector AttackMove = (ToTarget / TargetDistance) * Math::Max(TargetDistance, 400.0) * GhostSettings.ChargeTravelFactor;
		AnimComp.RequestAction(LocomotionFeatureAISanctuaryTags::GhostKnightAttack, SubTagSanctuaryGhostKnightAttack::ChargeHit, EBasicBehaviourPriority::Medium, this, AttackDuration, AttackMove);

		// We can only hit our designated target
		AvailableTargets.Empty(1);
		AvailableTargets.Add(TargetComp.Target);
	}
		
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, GhostSettings.ChargeTokenCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ToTarget = (Target.ActorCenterLocation - Owner.ActorCenterLocation);
		if (AttackDuration.IsBeforeAction(ActiveDuration) && (RecoveryDirection.DotProduct(ToTarget - RecoveryDirection * 200.0) > 0.0))
			DestinationComp.RotateTowards(Target.ActorCenterLocation);
		
		if (AttackDuration.IsInActionRange(ActiveDuration))
		{
			// Check if we're hitting anything
			for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
			{
				// Hit is decided on target control side 
				if (AvailableTargets[i].HasControl() && TargetComp.IsChargeHit(AvailableTargets[i], GhostSettings.ChargeRadius, 0.2))
					CrumbHitTarget(AvailableTargets[i]);
			}
		}

		if (AttackDuration.IsInRecoveryRange(ActiveDuration) && AvailableTargets.Num() > 0)
			AnimComp.RequestSubFeature(SubTagSanctuaryGhostKnightAttack::ChargeMiss, this);

		if (ActiveDuration > AttackDuration.GetTotal())
			Cooldown.Set(GhostSettings.ChargeCooldown);

		if ((AvailableTargets.Num() == 0) && TargetComp.IsValidTarget(Target))
		{
			// When there is nothing more to hit we don't want to plow through target.
			FVector ToTargetDir = ToTarget.GetSafeNormal2D();
			
			// Break when close
			float BreakForce = Owner.ActorVelocity.DotProduct(ToTargetDir) * 1.0;
			if (BreakForce > 0.0)
			 	DestinationComp.AddCustomAcceleration(-ToTargetDir * BreakForce);			
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbHitTarget(AHazeActor Victim)
	{
		// We only strike each target once
		AvailableTargets.Remove(Victim);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Victim);
		if (Player != nullptr)
		{
			Player.DamagePlayerHealth(GhostSettings.ChargeDamage);

			if (GhostSettings.ChargeKnockdownDistance > 0.0)
			{
				FKnockdown Knockdown;
				Knockdown.Move = Owner.ActorVelocity.ConstrainToPlane(Victim.ActorUpVector).GetSafeNormal() * GhostSettings.ChargeKnockdownDistance;
				//Knockdown.Move += Victim.ActorUpVector * GhostSettings.ChargeKnockdownDistance * 0.2; // Anim does not have Z root motion for now
				Knockdown.Duration = GhostSettings.ChargeKnockdownDuration;
				Player.ApplyKnockdown(Knockdown);
			}
			else if (GhostSettings.ChargeStumbleDistance > 0.0)
			{
				FStumble Stumble;
				Stumble.Move = Owner.ActorVelocity.ConstrainToPlane(Victim.ActorUpVector).GetSafeNormal() * GhostSettings.ChargeStumbleDistance; 
				Stumble.Duration = GhostSettings.ChargeStumbleDuration;
				Player.ApplyStumble(Stumble);
			}
		}


		//Owner.TriggerEffectEvent(...::OnChargeHit, F...ChargeHitParams(Target));
	}
}