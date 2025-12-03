
class UBasicFlyingDriftBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	FHazeAcceleratedFloat DriftSpeed;
	FVector FocusDirection;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		DriftSpeed.SnapTo(Owner.ActorVelocity.Size2D());
		FocusDirection = Owner.ActorVelocity.GetSafeNormal();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > BasicSettings.FlyingDriftDuration)
		{
			DeactivateBehaviour();
			return;
		}

		// Keep going in the same direction but slow down over time
		DriftSpeed.AccelerateTo(0.0, BasicSettings.FlyingDriftDuration, DeltaTime);
		if (!Owner.ActorVelocity.IsNearlyZero(10.0))
		{
			FocusDirection = Owner.ActorVelocity.GetSafeNormal();
			float Dist = (DestinationComp.MinMoveDistance + 100.0);
			FVector Dest = Owner.ActorLocation + FocusDirection * Dist;
			if (TargetComp.HasValidTarget())
				Dest.Z = TargetComp.Target.ActorLocation.Z + BasicSettings.FlyingDriftHeight;
			DestinationComp.MoveTowardsIgnorePathfinding(Dest, DriftSpeed.Value); 
		}
		DestinationComp.RotateTowards(Owner.FocusLocation + FocusDirection * 1000.0);
	}
}