
// Move towards enemy
class UBasicFlyingChaseBehaviour : UBasicBehaviour
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
		if (TargetComp.Target.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, BasicSettings.ChaseMinRange))
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
		FVector ChaseLocation = TargetComp.Target.ActorLocation;
		ChaseLocation.Z += BasicSettings.FlyingChaseHeight;

		if (Owner.ActorLocation.IsWithinDist(ChaseLocation, BasicSettings.ChaseMinRange))
		{
			Cooldown.Set(BasicSettings.ChaseMinRangeCooldown);
			return;
		}

		// Keep moving towards target!
		DestinationComp.MoveTowards(ChaseLocation, BasicSettings.ChaseMoveSpeed);
	}
}