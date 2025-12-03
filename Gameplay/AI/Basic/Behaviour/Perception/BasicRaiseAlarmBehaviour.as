
class UBasicRaiseAlarmBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOrLocalOnly;

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
		if (ActiveDuration > BasicSettings.RaiseAlarmDelay)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		// Let every team member within range know about our target	
		FVector AlarmLoc = Owner.FocusLocation;
		TArray<AHazeActor> TeamMates = BehaviourComp.Team.GetMembers();
		for (AHazeActor TeamMate : TeamMates)
		{
			if (TeamMate == nullptr)
				continue;

			if (TeamMate == Owner)
				continue;

			if (!AlarmLoc.IsWithinDist(TeamMate.FocusLocation, BasicSettings.RaiseAlarmRadius))
				continue;

			UBasicAITargetingComponent MateResponseComp = UBasicAITargetingComponent::Get(TeamMate);
			if (MateResponseComp != nullptr)
				MateResponseComp.RaiseAlarm(TargetComp.Target);
		}

		// Wait a while before raising alarm again
		Cooldown.Set(BasicSettings.RaiseAlarmInterval);
	}
}