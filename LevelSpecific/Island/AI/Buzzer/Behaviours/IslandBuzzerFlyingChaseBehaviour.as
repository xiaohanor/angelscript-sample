
// Move towards enemy
class UIslandBuzzerFlyingChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandBuzzerSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandBuzzerSettings::GetSettings(Owner);
	}

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
		FVector ChaseLocation = TargetComp.Target.ActorLocation;
		ChaseLocation.Z += Settings.ChaseHeight;

		if (Owner.ActorLocation.IsWithinDist(ChaseLocation, Settings.ChaseMinRange))
		{
			Cooldown.Set(0.5);
			return;
		}

		// Keep moving towards target!
		DestinationComp.MoveTowards(ChaseLocation, Settings.ChaseMoveSpeed);
	}
}