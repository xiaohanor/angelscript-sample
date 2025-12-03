struct FSkylineGeckoPassiveBehaviourParams
{
	float Angle;
	float Distance;
}

class USkylineGeckoPassiveBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineGeckoComponent GeckoComp;
	USkylineGeckoConstrainedPlayerComponent TargetConstrainComp;
	float Angle;
	float Distance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GeckoComp = USkylineGeckoComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineGeckoPassiveBehaviourParams& Params) const
	{
		if(!Super::ShouldActivate())
			return false;

		USkylineGeckoConstrainedPlayerComponent ConstrainComp = USkylineGeckoConstrainedPlayerComponent::Get(TargetComp.Target);
		if(ConstrainComp == nullptr)
			return false;

		if(!ConstrainComp.IsConstrainedBy(GeckoComp))
			return false;

		Params.Angle = Math::RandRange(-70, 70);
		Params.Distance = Math::RandRange(400, 1000);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!TargetConstrainComp.IsConstrained())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineGeckoPassiveBehaviourParams Params)
	{
		Super::OnActivated();
		TargetConstrainComp = USkylineGeckoConstrainedPlayerComponent::Get(TargetComp.Target);
		Angle = Params.Angle;
		Distance = Params.Distance;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(TargetConstrainComp.Owner.ActorLocation);
		// FVector Direction = TargetConstrainComp.Owner.ActorForwardVector.RotateAngleAxis(Angle, FVector::UpVector);
		FVector Direction = (Owner.ActorLocation - TargetConstrainComp.Owner.ActorLocation).GetSafeNormal();
		DestinationComp.MoveTowards(TargetConstrainComp.Owner.ActorLocation + Direction * Distance, 500);
	}
}