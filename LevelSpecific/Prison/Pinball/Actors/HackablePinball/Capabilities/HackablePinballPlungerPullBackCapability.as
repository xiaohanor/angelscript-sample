struct FPinballPlungerDelayedActivate
{
	float GameTime;
	bool bActive;

	FPinballPlungerDelayedActivate(float InGameTime, bool bInActive)
	{
		GameTime = InGameTime;
		bActive = bInActive;
	}
}

class UHackablePinballPlungerPullBackCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(Pinball::Tags::Pinball);
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	AHackablePinball Flipper;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Drone::GetSwarmDronePlayer();
		Flipper = Cast<AHackablePinball>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Flipper.HijackableTarget.IsHijacked())
			return false;

		if(GetAttributeFloat(AttributeNames::MoveForward) > -0.5)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (!Flipper.HijackableTarget.IsHijacked())
			return true;

		if(GetAttributeFloat(AttributeNames::MoveForward) > -0.5)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Pinball::GetManager().StartPlungerPullBack();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Pinball::GetManager().StopPlungerPullBack();
	}
}