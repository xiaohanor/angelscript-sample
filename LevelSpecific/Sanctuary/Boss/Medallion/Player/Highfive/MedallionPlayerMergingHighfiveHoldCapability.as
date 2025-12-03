class UMedallionPlayerMergingHighfiveHoldCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(MedallionTags::MedallionTag);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	UMedallionPlayerReferencesComponent RefsComp;
	UMedallionPlayerComponent MedallionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HighfiveComp.IsHighfiveJumping())
			return false;
		if (HighfiveComp.bHighfiveResolveTriggered)
			return false;
		if (HighfiveComp.IsInHighfiveFail())
			return false;
		if (!HighfiveComp.CanCompleteHighfive())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HighfiveComp.bHighfiveResolveTriggered)
			return true;
		if (HighfiveComp.IsInHighfiveFail())
			return true;
		if (!HighfiveComp.CanCompleteHighfive())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FButtonMashSettings MashSettings;
		MashSettings.Mode = EButtonMashMode::ButtonHold;
		MashSettings.Duration = MedallionConstants::Highfive::HighfiveHoldDuration;
		MashSettings.ButtonAction = MedallionConstants::Highfive::HighfiveButton;
		MashSettings.WidgetAttachComponent = MedallionComp.MedallionActor.ButtonMashAttachComp;
		Player.StartButtonMash(MashSettings, MedallionTags::MedallionHighfiveHoldInstigator);
		Player.SetButtonMashAllowCompletion(MedallionTags::MedallionHighfiveHoldInstigator, false);
		Player.BlockCapabilities(n"Death", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopButtonMash(MedallionTags::MedallionHighfiveHoldInstigator);
		Player.UnblockCapabilities(n"Death", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsActioning(MedallionConstants::Highfive::HighfiveButton))
		{
			FHazeFrameForceFeedback FF;
			FF.RightTrigger = 1.0;
			FF.RightMotor = 0.5;
			Player.SetFrameForceFeedback(FF);
		}

		HighfiveComp.HighfiveHoldAlpha = Player.GetButtonMashProgress(MedallionTags::MedallionHighfiveHoldInstigator);
	}
};