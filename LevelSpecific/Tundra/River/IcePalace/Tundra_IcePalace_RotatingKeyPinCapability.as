class UTundra_IcePalace_RotatingKeyPinCapability : UHazePlayerCapability
{
	//default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"TundraKeyPin");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UTundra_IcePalace_RotatingKeyPinComponent KeyPinComp;
	ATundra_IcePalace_RotatingKeyPin KeyPin;
	float Duration = 0.25;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		KeyPinComp = UTundra_IcePalace_RotatingKeyPinComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FRotatingKeyPinActivationParams& ActivationParams) const
	{
		if(KeyPinComp.ActiveKeyPin == nullptr)
			return false;

		ActivationParams.KeyPin = KeyPinComp.ActiveKeyPin;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{		
		if(ActiveDuration >= Duration)
			return true;
		else
			return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FRotatingKeyPinActivationParams ActivationParams)
	{
		KeyPin = ActivationParams.KeyPin;
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(HasControl())
			KeyPin.RotatePin();

		KeyPin = nullptr;
		KeyPinComp.ActiveKeyPin = nullptr;
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}

	void ShowTutorial(bool bShow)
	{
		if(bShow)
		{
			FTutorialPrompt TutPrompt;
			TutPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
			Player.ShowTutorialPrompt(TutPrompt, this);
			Player.ShowCancelPrompt(this);
		}
		else
		{
			Player.RemoveTutorialPromptByInstigator(this);
			Player.RemoveCancelPromptByInstigator(this);
		}
	}
};