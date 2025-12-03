
class UBasicCircleStrafeBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	bool bStrafeLeft = false;
	bool bTriedBothDirections = false;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Math::Min(BasicSettings.CircleStrafeEnterRange, BasicSettings.CircleStrafeMaxRange)))
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.CircleStrafeMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.CircleStrafeMaxRange))
			return true;
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, BasicSettings.CircleStrafeMinRange))
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bStrafeLeft = Math::RandBool();
		bTriedBothDirections = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector Side = Owner.ActorUpVector.CrossProduct(TargetLoc - OwnLoc);
		Side = Side.GetClampedToSize(DestinationComp.MinMoveDistance, DestinationComp.MinMoveDistance + 80.0);
		if (bStrafeLeft)
			Side *= -1.0;
		float CircleDist = OwnLoc.Distance(TargetLoc);
		FVector CircleOffset = (OwnLoc + Side - TargetLoc).GetClampedToMaxSize(CircleDist);
		FVector StrafeDest = TargetLoc + CircleOffset;
		DestinationComp.MoveTowards(StrafeDest, BasicSettings.CircleStrafeSpeed);

		DestinationComp.RotateTowards(TargetComp.Target);
		
		if (DoChangeDirection(StrafeDest))
		{
			if (bTriedBothDirections)
				Cooldown.Set(2.0); // Stuck, try again in a while
			bStrafeLeft = !bStrafeLeft;
			bTriedBothDirections = true;
		}
	}
	
	private bool DoChangeDirection(FVector StrafeDest)
	{
		if(DestinationComp.MoveFailed())
			return true;

		FVector StrafeDestNavMesh;
		FVector PathStrafeDest = StrafeDest + (StrafeDest - Owner.ActorLocation).GetSafeNormal() * Radius;
		if(!Pathfinding::FindNavmeshLocation(PathStrafeDest, 0.0, 100.0, StrafeDestNavMesh))
			return true;

		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, StrafeDestNavMesh))
			return true;

		return false;
	}
}