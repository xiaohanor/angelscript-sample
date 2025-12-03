class UStoneBossQTEWeakpointButtonFeedbackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"StoneBossQTEWeakpointButtonFeedbackCapability");

	default TickGroup = EHazeTickGroup::Gameplay;

	UButtonMashComponent PlayerButtonMashComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerButtonMashComp = UButtonMashComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PlayerButtonMashComp.IsButtonMashActive(n"WeakpointQTESecondMashInstigator"))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PlayerButtonMashComp.IsButtonMashActive(n"WeakpointQTESecondMashInstigator"))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Progress = PlayerButtonMashComp.GetButtonMashProgress(n"WeakpointQTESecondMashInstigator");
		Progress *= 2.0;
		PrintToScreen(f"{Progress=}");

		float FFFrequency = 60.0;
		float FFIntensity = 1.0 * Progress;
		FFIntensity = Math::Clamp(FFIntensity, 0.05, 2.0);
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
		FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
		Player.SetFrameForceFeedback(FF);
	}
};