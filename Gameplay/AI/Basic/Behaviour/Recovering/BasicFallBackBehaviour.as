class UBasicFallBackBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move away from target until at proper distance or duration is up
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector AwayLoc = OwnLoc + (OwnLoc - TargetLoc).GetSafeNormal() * (DestinationComp.GetMinMoveDistance() + 80.0);
		DestinationComp.MoveTowards(AwayLoc, BasicSettings.EvadeMoveSpeed);
		DestinationComp.RotateTowards(TargetComp.Target);

		if (ActiveDuration > BasicSettings.EvadeMinDuration)
		{
			if (!OwnLoc.IsWithinDist(TargetLoc, BasicSettings.EvadeRange))
			{
				DeactivateBehaviour();
				return;
			}

			if (ActiveDuration > BasicSettings.EvadeMaxDuration)
			{
				DeactivateBehaviour();
				return;
			}
		}
	}
}