// Refocus when an target lingers to long nearby and is not the current target
class UEnforcerProximityTargetBehaviour : UBasicBehaviour
{
	// Targeting behaviour need only run on control side, results are replicated
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	AHazePlayerCharacter ProximityTarget;
	float ProximityTime;
	USkylineEnforcerSettings EnforcerSettings;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;

		AHazePlayerCharacter Target = Cast<AHazePlayerCharacter>(TargetComp.FindClosestTarget(EnforcerSettings.EnforcerProximityTargetRange));

		if(Target != nullptr && Target == TargetComp.Target)
		{
			if (ProximityTime != 0 && ProximityTarget == Target.OtherPlayer)
				return;
			ProximityTarget = Target.OtherPlayer;
			ProximityTime = Time::GetGameTimeSeconds();
		}
		else
		{
			ProximityTime = 0.0;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		EnforcerSettings = USkylineEnforcerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(ProximityTime == 0 || Time::GetGameTimeSince(ProximityTime) <= EnforcerSettings.EnforcerRetargetOnProximityDuration)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TargetComp.SetTarget(ProximityTarget);

		// This capability should never switch target again for a while
		Cooldown.Set(EnforcerSettings.EnforcerRetargetOnProximityDuration);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ProximityTime = 0.0;
	}
}
