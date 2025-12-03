class UPlayerDragonSignalCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"PlayerDragonSignalInputting");

	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerDragonSignalComponent UserComp;

	bool bShowTutorial;
	bool bInputting;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UPlayerDragonSignalComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (UserComp.bSignalEnabled)
		{
			if (!IsActioning(ActionNames::PrimaryLevelAbility) && !bShowTutorial)
			{
				bShowTutorial = true;
				UserComp.ShowSignalTutorialPrompt();
			}
			else if (IsActioning(ActionNames::PrimaryLevelAbility) && bShowTutorial)
			{
				bShowTutorial = false;
				UserComp.RemoveSignalTutorialPrompt();
			}
		}
		else if (!UserComp.bSignalEnabled && bShowTutorial)
		{
			bShowTutorial = false;
			UserComp.RemoveSignalTutorialPrompt();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bSignalEnabled)
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (UserComp.bSignalSuccessful)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bSignalEnabled)
			return true;

		if (WasActionStopped(ActionNames::PrimaryLevelAbility))
			return true;
		
		if (UserComp.bSignalSuccessful)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FHazeSlotAnimSettings Settings;
		Settings.BlendTime = 1.0;
		Player.PlaySlotAnimation(UserComp.SignalAnimSequence, Settings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopSlotAnimationByAsset(UserComp.SignalAnimSequence, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			if (Player.OtherPlayer.IsAnyCapabilityActive(n"PlayerDragonSignalInputting"))
			{
				UserComp.SelectedWeakpoint.CrumbActivateAttackCheck();
				UserComp.CrumbSignalSuccessful();
				UPlayerDragonSignalComponent OtherUser = UPlayerDragonSignalComponent::Get(Player.OtherPlayer);
				OtherUser.CrumbSignalSuccessful();
			}
		}
	}
};