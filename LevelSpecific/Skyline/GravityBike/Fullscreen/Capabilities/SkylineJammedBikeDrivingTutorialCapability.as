class USkylineJammedBikeDrivingTutorialCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = -100;

	USkylineJammedBikeComponent JammedBikeComp;

	UHazeUserWidget TutorialPromptWidget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JammedBikeComp = USkylineJammedBikeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		//if (!JammedBikeComp.bHasFinishedAccelerateTutorial)
		//	return false;

		if (JammedBikeComp.bHasFinishedDrivingTutorial)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (JammedBikeComp.bHasFinishedDrivingTutorial)
			return true;

		if (ActiveDuration > 10.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TutorialPromptWidget = Widget::AddFullscreenWidget(JammedBikeComp.TutorialPromptWidget);

		GravityBikeSpline::GetGravityBike().BlockEnemySlowRifleFire.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Widget::RemoveFullscreenWidget(TutorialPromptWidget);

		JammedBikeComp.bHasFinishedDrivingTutorial = true;

		GravityBikeSpline::GetGravityBike().BlockEnemySlowRifleFire.Remove(this);
	}
};