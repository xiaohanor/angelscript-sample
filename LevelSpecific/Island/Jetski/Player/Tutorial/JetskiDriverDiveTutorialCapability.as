class UJetskiDriverDiveTutorialCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UJetskiDriverComponent DriverComp;
	UJetskiDriverTutorialComponent TutorialComp;
	AJetskiTutorialActor TutorialActor;

	float TimeHeldDive = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UJetskiDriverComponent::Get(Player);
		TutorialComp = UJetskiDriverTutorialComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FJetskiDriverTutorialActivateParams& Params) const
	{
		if(!TutorialComp.bShouldShowDiveTutorial)
			return false;

		if(!TutorialComp.bShouldShowDiveTutorial)
			return false;

		if(TutorialComp.TutorialActor == nullptr)
			return false;

		Params.TutorialActor = TutorialComp.TutorialActor;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FJetskiDriverTutorialDeactivateParams& Params) const
	{
		if(!TutorialComp.bShouldShowDiveTutorial)
			return true;

		if(TimeHeldDive > 1.25)
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

		FTutorialPrompt DivePrompt;
		DivePrompt.Action = ActionNames::WeaponAim;
		DivePrompt.Text = TutorialActor.TutorialTextDive;
		DivePrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		DivePrompt.MaximumDuration = -1;
		DivePrompt.Mode = ETutorialPromptMode::RemoveWhenPressed;
		Player.ShowTutorialPromptWorldSpace(DivePrompt, this, TutorialActor.LeftTutorialLoc, FVector::ZeroVector, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FJetskiDriverTutorialDeactivateParams Params)
	{
		Player.RemoveTutorialPromptByInstigator(this);

		if(Params.bFinished)
			TutorialComp.bShouldShowDiveTutorial = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(IsActioning(ActionNames::WeaponAim))
		{
			TimeHeldDive += DeltaTime;
		}
	}
};