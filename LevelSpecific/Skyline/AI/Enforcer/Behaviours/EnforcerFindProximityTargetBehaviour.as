// Refocus when an target lingers to long nearby and is not the current target
class UEnforcerFindProximityTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UBasicAIControlSideSwitchComponent ControlSideSwitchComp;
	AHazeActor ProximityTarget;
	float ProximityTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ControlSideSwitchComp = UBasicAIControlSideSwitchComponent::Get(Owner);
	}

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

		bool bNewTarget = (ProximityTarget != TargetComp.Target);
		TargetComp.SetTarget(ProximityTarget);
		if (bNewTarget)
			CrumbChangeTarget(ProximityTarget);

		// This capability should never switch target again for a while
		Cooldown.Set(BasicSettings.RetargetOnProximityDuration);
	}

	UFUNCTION(CrumbFunction)
	void CrumbChangeTarget(AHazeActor Target)
	{
		// Match control side with target
		ControlSideSwitchComp.WantedController = Target;

		// Since this may trigger a control side switch we should make sure cooldown is set on both sides
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
