class UJetskiDriverAccelerationTutorialCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UJetskiDriverComponent DriverComp;
	UJetskiDriverTutorialComponent TutorialComp;
	AJetskiTutorialActor TutorialActor;

	float TimeHeldAccelerate = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UJetskiDriverComponent::Get(Player);
		TutorialComp = UJetskiDriverTutorialComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FJetskiDriverTutorialActivateParams& Params) const
	{
		if(!TutorialComp.bShouldShowAccelerationTutorial)
			return false;

		if(TutorialComp.TutorialActor == nullptr)
			return false;

		Params.TutorialActor = TutorialComp.TutorialActor;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FJetskiDriverTutorialDeactivateParams& Params) const
	{
		if(!TutorialComp.bShouldShowAccelerationTutorial)
			return true;

		if(TimeHeldAccelerate > 4)
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FJetskiDriverTutorialActivateParams Params)
	{
		TutorialActor = Params.TutorialActor;

		FTutorialPrompt AcceleratePrompt;
		AcceleratePrompt.Action = ActionNames::Accelerate;
		AcceleratePrompt.Text = TutorialActor.TutorialTextAccelerate;
		AcceleratePrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		AcceleratePrompt.MaximumDuration = -1;
		AcceleratePrompt.Mode = ETutorialPromptMode::RemoveWhenPressed;
		Player.ShowTutorialPromptWorldSpace(AcceleratePrompt, this, TutorialActor.RightTutorialLoc, FVector::ZeroVector, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FJetskiDriverTutorialDeactivateParams Params)
	{
		Player.RemoveTutorialPromptByInstigator(this);

		if(Params.bFinished)
			TutorialComp.bShouldShowAccelerationTutorial = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(GetAttributeFloat(ActionNames::Accelerate) > 0.5)
		{
			TimeHeldAccelerate += DeltaTime;
		}
	}
};