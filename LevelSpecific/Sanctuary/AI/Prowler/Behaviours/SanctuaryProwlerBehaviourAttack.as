class USanctuaryProwlerAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UHazeCharacterSkeletalMeshComponent Mesh;
	USanctuaryProwlerSettings ProwlerSettings;
	FBasicAIAnimationActionDurations AttackDuration;
	bool bTriggeredImpact = false;
	float MinAttackDot = -1.0;
	

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ProwlerSettings = USanctuaryProwlerSettings::GetSettings(Owner);
		Mesh = UHazeCharacterSkeletalMeshComponent::Get(Owner);
		MinAttackDot = Math::Cos(Math::DegreesToRadians(ProwlerSettings.AttackMaxAngleDegrees));
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		#if EDITOR
		MinAttackDot = Math::Cos(Math::DegreesToRadians(ProwlerSettings.AttackMaxAngleDegrees));
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
		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetLoc, ProwlerSettings.AttackRange))
			return false;
		if (Owner.ActorForwardVector.DotProduct((TargetLoc - Owner.ActorLocation).GetSafeNormal2D()) < MinAttackDot)
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
		if(!GentCostComp.IsTokenAvailable(ProwlerSettings.GentlemanCost))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, ProwlerSettings.GentlemanCost);

		AttackDuration.Telegraph = ProwlerSettings.AttackTelegraphDuration;
		AttackDuration.Anticipation = ProwlerSettings.AttackAnticipationDuration; 
		AttackDuration.Action = ProwlerSettings.AttackHitDuration; 
		AttackDuration.Recovery = ProwlerSettings.AttackRecoveryDuration;
		FVector AttackMovement = (TargetComp.Target.ActorLocation - Owner.ActorLocation) * 0.9;
		float MinRange = ProwlerSettings.AttackRange * 0.1;
		if (AttackMovement.IsNearlyZero(MinRange))
			AttackMovement = AttackMovement.GetSafeNormal() * MinRange;
		AnimComp.RequestAction(LocomotionFeatureAITags::MeleeCombat, SubTagAIMeleeCombat::HeavyAttack, EBasicBehaviourPriority::Medium, this, AttackDuration, AttackMovement);
		bTriggeredImpact = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, ProwlerSettings.AttackTokenCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bTriggeredImpact && (ActiveDuration > AttackDuration.Telegraph + AttackDuration.Anticipation))
		{
			bTriggeredImpact = true;
			FVector ImpactLocation = Mesh.GetSocketLocation(n"RightHand");
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (!Player.HasControl())
					continue;

				float DamageFactor = Damage::GetRadialDamageFactor(Player.ActorCenterLocation, ImpactLocation, ProwlerSettings.AttackRadius, ProwlerSettings.AttackInnerRadius);
				if (DamageFactor > 0.0)
					CrumbDealDamage(Player);
			}

			USanctuaryProwlerEventHandler::Trigger_AttackImpact(Owner, FSanctuaryProwlerEventAttackImpactParams(ImpactLocation));
		}

		if (ActiveDuration > AttackDuration.GetTotal())
			Cooldown.Set(ProwlerSettings.AttackCooldown);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbDealDamage(AHazePlayerCharacter PlayerTarget)
	{
		PlayerTarget.DamagePlayerHealth(ProwlerSettings.AttackDamage);
	}
}

