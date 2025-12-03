
class UIslandZoomotronFlyingCircleStrafeBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	bool bHasSetDirection = false;
	bool bStrafeLeft = false;
	bool bTriedBothDirections = false;

	UBasicAICharacterMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bHasSetDirection = false;
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

		// Select closest direction to front of target
		if (!bHasSetDirection)
		{
			bHasSetDirection = true;
			FVector FromTarget = Owner.ActorLocation - TargetComp.Target.ActorLocation;
			FromTarget.Normalize();
			if (FromTarget.DotProduct(TargetComp.Target.ActorRightVector) < 0)
				bStrafeLeft = true;
			else
				bStrafeLeft = false;
		}

		bTriedBothDirections = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TargetComp.HasValidTarget())
		{
			return;
		}

		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector Side = Owner.ActorUpVector.CrossProduct(TargetLoc - OwnLoc);
		Side = Side.GetClampedToSize(DestinationComp.MinMoveDistance, DestinationComp.MinMoveDistance + 80.0);
		if (bStrafeLeft)
			Side *= -1.0;
		float CircleDist = OwnLoc.Distance(TargetLoc);
		FVector CircleOffset = (OwnLoc + Side - TargetLoc).GetClampedToMaxSize(CircleDist);
		FVector StrafeDest = TargetLoc + CircleOffset;
		StrafeDest.Z = TargetLoc.Z + BasicSettings.FlyingCircleStrafeHeight;
		DestinationComp.MoveTowardsIgnorePathfinding(StrafeDest, BasicSettings.CircleStrafeSpeed);

		DestinationComp.RotateTowards(TargetComp.Target);
		
		if (MoveComp.HasWallContact())
		{
			if (bTriedBothDirections)
				Cooldown.Set(2.0); // Stuck, try again in a while
			bStrafeLeft = !bStrafeLeft;
			bTriedBothDirections = true;
		}
	}
}