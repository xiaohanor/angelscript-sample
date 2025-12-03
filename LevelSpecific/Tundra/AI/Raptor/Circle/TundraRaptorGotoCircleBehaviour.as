
class UTundraRaptorGotoCircleBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	default CapabilityTags.Add(TundraRaptorTags::TundraRaptorCircle);

	UTundraRaptorCircleComponent CircleComp;
	FVector Dir;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CircleComp = UTundraRaptorCircleComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		FVector ChaseLocation = GetLocation();
		if(Owner.ActorLocation.IsWithinDist(ChaseLocation, 25))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Dir = (CircleComp.CurrentCircleLocation - Owner.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ChaseLocation = GetLocation();
		if (Owner.ActorLocation.IsWithinDist(ChaseLocation, 25))
		{
			Cooldown.Set(0.5);
			return;
		}

		// Keep moving towards target!
		DestinationComp.MoveTowards(ChaseLocation, BasicSettings.ChaseMoveSpeed);
		DestinationComp.RotateTowards(ChaseLocation);
	}

	private FVector GetLocation() const
	{
		float Range = (BasicSettings.CircleStrafeMinRange + BasicSettings.CircleStrafeMaxRange) / 2;
		FVector ChaseLocation = CircleComp.CurrentCircleLocation + Dir * Range;
		ChaseLocation.Z += BasicSettings.FlyingChaseHeight;
		return ChaseLocation;
	}
}