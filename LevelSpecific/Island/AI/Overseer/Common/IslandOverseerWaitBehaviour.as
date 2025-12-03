
class UIslandOverseerWaitBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;

	float Duration = 1;

	UIslandOverseerWaitBehaviour(float WaitDuration)
	{
		Duration = WaitDuration;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Duration)
			return true;
		return false;
	}
}