
class UBasicGentlemanWaitBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	UGentlemanComponent GentlemanComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Have we switched (or cleared) target?
		if ((GentlemanComp != nullptr) && (TargetComp.GentlemanComponent != GentlemanComp))
			GentlemanComp.ReleaseToken(GentlemanToken::Attack, Owner);
		GentlemanComp = TargetComp.GentlemanComponent;

		if (GentlemanComp  == nullptr)
			return;

		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.GentlemanRange))
		{
			GentlemanComp.ReleaseToken(GentlemanToken::Attack, Owner);
			return;
		}

		// Go ahead and try to claim the glory!
		GentlemanComp.ClaimToken(GentlemanToken::Attack, Owner, BehaviourComp.WantedGentlemanScore);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (GentlemanComp == nullptr)
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.GentlemanRange))
			return false;
		if (GentlemanComp.CanClaimToken(GentlemanToken::Attack, Owner, BehaviourComp.WantedGentlemanScore))
			return false; 

		// We do not have the score to take action, hold until we do.
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (GentlemanComp == nullptr)
			return true;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.GentlemanRange * 1.2))
			return true;
		if (GentlemanComp.CanClaimToken(GentlemanToken::Attack, Owner, BehaviourComp.WantedGentlemanScore))
		{
			// We're free to take action! Just make sure we don't jitter in an out.
			if (ActiveDuration > 1.0)
				return true;
		}

		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TargetComp.HasValidTarget())
		{
			return;
		}

		// Should we step away from the target?
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		FVector OwnLoc = Owner.ActorLocation;
		if (OwnLoc.IsWithinDist(TargetLoc, BasicSettings.GentlemanStepBackRange))
			DestinationComp.MoveTowards(OwnLoc + (OwnLoc - TargetLoc).GetSafeNormal() * BasicSettings.GentlemanStepBackRange, BasicSettings.GentlemanMoveSpeed);

		// Look at target
		DestinationComp.RotateTowards(TargetComp.Target);
	}
}