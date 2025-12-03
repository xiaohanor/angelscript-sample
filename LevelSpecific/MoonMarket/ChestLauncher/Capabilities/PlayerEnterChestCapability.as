class UPlayerEnterChestCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMoonMarketMimicPlayerComponent LaunchComp;
	AMoonMarketMimic Mimic;

	float AnimTime = 1.5;
	float TurnTime = 1.0;
	float DissappearTime = 1.0;
	bool bWasEaten;
	bool bStartTurning;

	FRotator MimicTargetRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LaunchComp = UMoonMarketMimicPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!LaunchComp.bEntering)
			return false;

		if (LaunchComp.bLaunchReady)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= DissappearTime + TurnTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LaunchComp.bEaten = false;
		bWasEaten = false;
		bStartTurning = false;
		Mimic = LaunchComp.CurrentMimic;
		MimicTargetRot = (-Mimic.ActorForwardVector).Rotation();
		Mimic.BP_PlayMunchingTimeline();

		if(!Mimic.bIsPlayerMimic)
		{
			Player.ActivateCamera(Mimic.CameraStart, 2.0, Mimic);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LaunchComp.bLaunchReady = true;
		LaunchComp.bEntering = false;
		Player.ActivateCamera(Mimic.CameraComp, 2.0, Mimic);

		FTutorialPrompt Prompt;
		Prompt.Action = ActionNames::PrimaryLevelAbility;
		Prompt.DisplayType = ETutorialPromptDisplay::Action;
		Prompt.Text = NSLOCTEXT("BookLauncher", "BookLaunchActivate", "Launch");
		Player.ShowTutorialPrompt(Prompt, LaunchComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / DissappearTime;

		if (ActiveDuration >= DissappearTime && !bWasEaten)
		{
			LaunchComp.bEaten = true;
			bWasEaten = true;
			Player.BlockCapabilities(CapabilityTags::Movement, LaunchComp);
			Player.BlockCapabilities(CapabilityTags::Visibility, LaunchComp);
		}
		
		if (ActiveDuration >= DissappearTime)
		{
			Mimic.ActorRotation = Math::RInterpConstantTo(Mimic.ActorRotation, MimicTargetRot, DeltaTime, 182.0);
		}
	}
};