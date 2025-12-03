class UEnforcerHoveringGravityWhipBillboardImpactRecoverBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default CapabilityTags.Add(SkylineAICapabilityTags::GravityWhippable);

	USkylineEnforcerSettings EnforcerSettings;
	UBasicAICharacterMovementComponent MoveComp;
	USkylineEnforcerGravityWhipComponent EnforcerGravityWhipComp;
	ASkylineJetpackCombatZoneManager BillboardManager;
	UEnforcerHoveringComponent HoveringComp;


	bool bArrived;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		EnforcerSettings = USkylineEnforcerSettings::GetSettings(Owner);
		EnforcerGravityWhipComp = USkylineEnforcerGravityWhipComponent::GetOrCreate(Owner);
		BillboardManager = TListedActors<ASkylineJetpackCombatZoneManager>().GetSingle();
		HoveringComp = UEnforcerHoveringComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > EnforcerSettings.GravityWhipImpactRecoverDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhipWallImpact, SubTagAIGravityWhipWallImpact::Recover, EBasicBehaviourPriority::Medium, this, EnforcerSettings.GravityWhipImpactRecoverDuration);
		bArrived = false;
		Owner.BlockCapabilities(n"CrowdRepulsion", this);
		UEnforcerJetpackEffectHandler::Trigger_OnLeaveBillboard(Owner, FJetpackBillboardParams(BillboardManager.GetNearestIntactBillboardZone(Owner.ActorLocation)));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.UnblockCapabilities(n"CrowdRepulsion", this);

		// Stop occupying billboard zone
		ASkylineJetpackCombatZone BillboardZone = HoveringComp.TargetBillboardZone.Get();
		HoveringComp.TargetBillboardZone.Clear(BasicAITags::Behaviour);
		if (HoveringComp.TargetBillboardZone.Get() != BillboardZone)
			BillboardZone.CurrentlyOccupiedBy = nullptr; 
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bArrived)
			return;
		
		FVector RecoverLocation = EnforcerGravityWhipComp.ImpactLocation + EnforcerGravityWhipComp.ImpactNormal * EnforcerSettings.GravityWhipImpactRecoverDistance;
		DestinationComp.MoveTowardsIgnorePathfinding(RecoverLocation, EnforcerSettings.GravityWhipImpactRecoverMoveSpeed);
		bArrived = RecoverLocation.IsWithinDist(Owner.ActorLocation, 100);
	}
}