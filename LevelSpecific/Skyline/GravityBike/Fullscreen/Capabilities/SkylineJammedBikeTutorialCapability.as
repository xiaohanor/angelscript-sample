class USkylineJammedBikeTutorialCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -100;

	USkylineJammedBikeComponent JammedBikeComp;

	float SetupTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JammedBikeComp = USkylineJammedBikeComponent::Get(Owner);
		SetupTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (JammedBikeComp.bHasFinishedAccelerateTutorial)
			return false;

		if (Time::GetGameTimeSince(SetupTime) < 4.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (JammedBikeComp.bHasFinishedAccelerateTutorial)
			return true;
		
		if (IsActioning(ActionNames::Accelerate))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TimeDilation::StartWorldTimeDilationEffect(JammedBikeComp.TimeDilationEffect, this);

		Player.ShowTutorialPrompt(JammedBikeComp.TutorialPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TimeDilation::StopWorldTimeDilationEffect(this);
		JammedBikeComp.bHasFinishedAccelerateTutorial = true;

		Player.RemoveTutorialPromptByInstigator(this);
	}
};