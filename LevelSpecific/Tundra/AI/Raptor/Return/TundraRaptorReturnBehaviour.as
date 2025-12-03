
class UTundraRaptorReturnBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	FVector StartLocation;
	FRotator StartRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		StartLocation = Owner.ActorLocation;
		StartRotation = Owner.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
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
	void TickActive(float DeltaTime)
	{
		if(Owner.ActorLocation.Distance(StartLocation) > 300)
		{
			DestinationComp.MoveTowards(StartLocation, 1000);
			DestinationComp.RotateTowards(StartLocation);
			return;
		}
		DestinationComp.RotateTowards(Owner.ActorLocation + StartRotation.ForwardVector * 100);
	}
}