
class USkylineGeckoEvadeBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, GetRange()))
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
		if (!TargetComp.HasValidTarget())
			return;

		// Move away from target until at proper distance or duration is up
		FVector OwnLoc = Owner.ActorLocation;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector AwayFromTarget = (OwnLoc - TargetLoc).ConstrainToPlane(Owner.ActorUpVector);
		FVector AwayLoc = OwnLoc + AwayFromTarget.GetSafeNormal() * (DestinationComp.MinMoveDistance + 80.0);

		if(Navigation::NavOctreeLineTrace(OwnLoc, AwayLoc))
		{
			Cooldown.Set(0.5);
			return;
		}

		DestinationComp.MoveTowards(AwayLoc, BasicSettings.EvadeMoveSpeed);
		DestinationComp.RotateTowards(TargetComp.Target);

		if (ActiveDuration > BasicSettings.EvadeMinDuration)
		{
			if (!OwnLoc.IsWithinDist(TargetLoc, GetRange()))
			{
				Cooldown.Set(0.5);
				return;
			}

			if (ActiveDuration > BasicSettings.EvadeMaxDuration)
			{
				Cooldown.Set(2.0);
				return;
			}
		}
	}

	private float GetRange() const
	{
		float EvadeRange = BasicSettings.EvadeRange;
		auto AreaComp = USkylineGeckoAreaPlayerComponent::GetOrCreate(TargetComp.Target);
		if(AreaComp.SameArea(Owner))
			EvadeRange /= 2;
		return EvadeRange;
	}
}