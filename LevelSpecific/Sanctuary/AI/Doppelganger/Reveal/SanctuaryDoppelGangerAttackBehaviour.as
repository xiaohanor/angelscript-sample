class USanctuaryDoppelGangerAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UHazeCharacterSkeletalMeshComponent Mesh;
	USanctuaryDoppelgangerSettings DoppelSettings;
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
		DoppelSettings = USanctuaryDoppelgangerSettings::GetSettings(Owner);
		Mesh = UHazeCharacterSkeletalMeshComponent::Get(Owner);
		MinAttackDot = Math::Cos(Math::DegreesToRadians(DoppelSettings.AttackMaxAngleDegrees));
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		#if EDITOR
		MinAttackDot = Math::Cos(Math::DegreesToRadians(DoppelSettings.AttackMaxAngleDegrees));
		#endif
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetLoc, DoppelSettings.AttackRange))
			return false;
		if (Owner.ActorForwardVector.DotProduct((TargetLoc - Owner.ActorLocation).GetSafeNormal2D()) < MinAttackDot)
			return false;
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
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		AttackDuration.Telegraph = DoppelSettings.AttackTelegraphDuration;
		AttackDuration.Anticipation = DoppelSettings.AttackAnticipationDuration; 
		AttackDuration.Action = DoppelSettings.AttackHitDuration; 
		AttackDuration.Recovery = DoppelSettings.AttackRecoveryDuration;
		FVector AttackMovement = (TargetComp.Target.ActorLocation - Owner.ActorLocation) * DoppelSettings.AttackTravelFactor;
		float MinRange = DoppelSettings.AttackRange * 0.1;
		if (AttackMovement.IsNearlyZero(MinRange))
			AttackMovement = AttackMovement.GetSafeNormal() * MinRange;
		AnimComp.RequestAction(LocomotionFeatureAITags::MeleeCombat, SubTagAIMeleeCombat::FinisherAttack, EBasicBehaviourPriority::Medium, this, AttackDuration, AttackMovement);
		bTriggeredImpact = false;
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bTriggeredImpact && AttackDuration.IsInActionRange(ActiveDuration))
		{
			bTriggeredImpact = true;
			FVector ImpactLocation = Mesh.GetSocketLocation(n"RightHand");
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (!Player.HasControl())
					continue;
				float DamageFactor = Damage::GetRadialDamageFactor(Player.ActorCenterLocation, ImpactLocation, DoppelSettings.AttackRadius, DoppelSettings.AttackInnerRadius);
				if (DamageFactor > 0.0)
					CrumbDealDamage(Player);
			}

			USanctuaryDoppelgangerEventHandler::Trigger_AttackImpact(Owner, FDoppelgangerEventAttackImpactParams(ImpactLocation));
		}

		if (ActiveDuration > AttackDuration.GetTotal())
			Cooldown.Set(DoppelSettings.AttackCooldown);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbDealDamage(AHazePlayerCharacter PlayerTarget)
	{
		PlayerTarget.DamagePlayerHealth(DoppelSettings.AttackDamage);		
	}
}

