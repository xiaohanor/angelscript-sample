
class UBasicGentlemanCircleBehaviour : UBasicGentlemanWaitBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	bool bStrafeLeft = false;
	bool bTriedBothDirections = false;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bStrafeLeft = Math::RandBool();
		bTriedBothDirections = false;
	}

	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
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

		// Should we step away from the target?
		if (CircleDist < BasicSettings.GentlemanStepBackRange)
			StrafeDest += (OwnLoc - TargetLoc).GetSafeNormal() * BasicSettings.GentlemanStepBackRange;

		DestinationComp.MoveTowards(StrafeDest, BasicSettings.GentlemanMoveSpeed);

		DestinationComp.RotateTowards(TargetComp.Target);
		
		if (DestinationComp.MoveFailed())
		{
			if (bTriedBothDirections)
				Cooldown.Set(2.0); // Stuck, try again in a while
			bStrafeLeft = !bStrafeLeft;
			bTriedBothDirections = true;
		}
	}
}