class USkylineTorExitLocationBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MoveComp;
	USkylineTorDamageComponent DamageComp;
	USkylineEnforcerSentencedComponent SentencedComp;
	USkylineTorPhaseComponent PhaseComp;
	USkylineTorExposedComponent ExposedComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	UGravityBladeOpportunityAttackTargetComponent OpportunityAttackComp;
	UGravityBladeGrappleComponent BladeGrappleComp;
	UGravityBladeCombatTargetComponent BladeTargetComp;
	USkylineTorHoverComponent HoverComp;

	FVector ExitLocation;
	FVector CenterLocation;

	bool ReachedLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();				
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		DamageComp = USkylineTorDamageComponent::Get(Owner);
		SentencedComp = USkylineEnforcerSentencedComponent::GetOrCreate(Owner);
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		ExposedComp = USkylineTorExposedComponent::GetOrCreate(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		BladeGrappleComp = UGravityBladeGrappleComponent::Get(Owner);
		BladeTargetComp = UGravityBladeCombatTargetComponent::Get(Owner);
		OpportunityAttackComp = UGravityBladeOpportunityAttackTargetComponent::GetOrCreate(Owner);
		HoverComp = USkylineTorHoverComponent::GetOrCreate(Owner);

		ExitLocation = TListedActors<ASkylineTorDefensivePoint>().Single.ActorLocation;
		CenterLocation = TListedActors<ASkylineTorCenterPoint>().GetSingle().ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(ReachedLocation)
			return false;
		if(HealthComp.CurrentHealth > PhaseComp.GroundedSecondThreshold)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ReachedLocation = true;
		PhaseComp.SetPhase(ESkylineTorPhase::Gecko);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveTowardsIgnorePathfinding(ExitLocation, Math::Clamp(ExitLocation.Dist2D(Owner.ActorLocation), 100, 750));
		DestinationComp.RotateTowards(CenterLocation);

		if(Owner.ActorLocation.Dist2D(ExitLocation) < 100)
			DeactivateBehaviour();
	}
}