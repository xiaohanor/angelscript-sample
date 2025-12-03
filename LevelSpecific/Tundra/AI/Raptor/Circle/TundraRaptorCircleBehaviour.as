
class UTundraRaptorCircleBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	default CapabilityTags.Add(TundraRaptorTags::TundraRaptorCircle);
	
	UTundraRaptorCircleComponent CircleComp;

	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CircleComp = UTundraRaptorCircleComponent::GetOrCreate(Owner);
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!Owner.ActorLocation.IsWithinDist(CircleComp.CurrentCircleLocation, Math::Min(BasicSettings.CircleStrafeEnterRange, BasicSettings.CircleStrafeMaxRange)))
			return false;
		if (Owner.ActorLocation.IsWithinDist(CircleComp.CurrentCircleLocation, BasicSettings.CircleStrafeMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (!Owner.ActorLocation.IsWithinDist(CircleComp.CurrentCircleLocation, BasicSettings.CircleStrafeMaxRange))
			return true;
		if (Owner.ActorLocation.IsWithinDist(CircleComp.CurrentCircleLocation, BasicSettings.CircleStrafeMinRange))
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = CircleComp.CurrentCircleLocation;
		FVector Side = Owner.ActorUpVector.CrossProduct(TargetLoc - OwnLoc);
		Side = Side.GetClampedToSize(DestinationComp.MinMoveDistance, DestinationComp.MinMoveDistance + 80.0);
		if (CircleComp.bStrafeLeft)
			Side *= -1.0;
		float CircleDist = OwnLoc.Distance(TargetLoc);
		FVector CircleOffset = (OwnLoc + Side - TargetLoc).GetClampedToMaxSize(CircleDist);
		FVector StrafeDest = TargetLoc + CircleOffset;
		DestinationComp.MoveTowards(StrafeDest, BasicSettings.CircleStrafeSpeed);
		DestinationComp.RotateTowards(TargetLoc);
	}
}