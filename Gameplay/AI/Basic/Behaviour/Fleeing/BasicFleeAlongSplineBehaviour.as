class UBasicFleeAlongSplineBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIFleeingComponent FleeComp;
	UHazeSplineComponent Spline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FleeComp = UBasicAIFleeingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!FleeComp.bWantsToFlee)
			return false;
		if (FleeComp.SplineOptions.IsEmpty())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return !FleeComp.bWantsToFlee;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Spline = FleeComp.SplineOptions.UseBestSpline(Owner, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if(Owner.IsActorDisabled())
			FleeComp.CompleteFlight();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveAlongSpline(Spline, BasicSettings.FleeAcceleration);
		if (DestinationComp.IsAtSplineEnd(Spline, 100.0))
		{
			FleeComp.CompleteFlight();
			DeactivateBehaviour();				
		}
	}
}
