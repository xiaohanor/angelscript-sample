class UTundraPlayerSwingInteractionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"TundraSwing");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	UTundraPlayerSwingComponent SwingComp;

	bool bCancelPromptShown = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwingComp = UTundraPlayerSwingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SwingComp.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration < 2)
			return false;

		if(WasActionStarted(ActionNames::Cancel))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bCancelPromptShown = false;
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwingComp.bIsActive = false;
		SwingComp.ResetOffset();
		SwingComp.Swing.ExitInteraction(Player);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.RemoveCancelPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bCancelPromptShown && ActiveDuration >= 2)
		{
			bCancelPromptShown = true;
			Player.ShowCancelPrompt(this);
		}
	}
};