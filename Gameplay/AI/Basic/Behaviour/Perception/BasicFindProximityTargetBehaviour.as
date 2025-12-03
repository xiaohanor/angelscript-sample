// Refocus when an target lingers to long nearby and is not the current target
class UBasicFindProximityTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	AHazeActor ProximityTarget;
	float ProximityTime;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(ProximityTime == 0 || Time::GetGameTimeSince(ProximityTime) <= BasicSettings.RetargetOnProximityDuration)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TargetComp.SetTarget(ProximityTarget);

		// This capability should never switch target again for a while
		Cooldown.Set(BasicSettings.RetargetOnProximityDuration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ProximityTime = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;

		AHazeActor Target = TargetComp.FindClosestTarget(BasicSettings.RetargetOnProximityRange);
		if(Target != nullptr && Target != TargetComp.Target)
		{
			if (ProximityTime != 0 && ProximityTarget == Target) 
				return;
			ProximityTarget = Target;
			ProximityTime = Time::GetGameTimeSeconds();
		}
		else
		{
			ProximityTime = 0.0;
		}
	}
}
