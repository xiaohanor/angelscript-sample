struct FSolarFlareButtonMashDeactivationParams
{
	bool bWasNaturalDeactivation;
}

class USolarFlareButtonMashLaunchCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UButtonMashComponent ButtonMash;
	USolarFlareButtonMashComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USolarFlareButtonMashComponent::Get(Player);
		ButtonMash = UButtonMashComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bCanButtonMash)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSolarFlareButtonMashDeactivationParams& DeactivationParams) const
	{
		if (!UserComp.bCanButtonMash)
		{
			DeactivationParams.bWasNaturalDeactivation = true;
			return true;
		}
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated() 
	{
		FButtonMashSettings Settings;
		Settings.ButtonAction = ActionNames::Interaction;
		Settings.Difficulty = EButtonMashDifficulty::Medium;
		Settings.Duration = 4.5;
		Settings.Mode = EButtonMashMode::ButtonMash;
		Settings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
		Settings.WidgetAttachComponent = Player.RootComponent;
		if (Player.IsMio())
			Settings.WidgetPositionOffset = FVector(70, -90, 250);
		else	
			Settings.WidgetPositionOffset = FVector(70, 90, 250);
		
		Player.StartButtonMash(Settings, this);
		Player.SetButtonMashAllowCompletion(this, false);
		Player.SetButtonMashGainMultiplier(this, 0.4);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSolarFlareButtonMashDeactivationParams Params)
	{
		Player.StopButtonMash(this);

		if (Params.bWasNaturalDeactivation)
			UserComp.Launcher.UpdateProgress(Player, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::Interaction))
		{
			Player.PlayForceFeedback(UserComp.Launcher.ForceFeedback, false, true, this);
		}
		
		if (UserComp.Launcher != nullptr)
			UserComp.Launcher.UpdateProgress(Player, ButtonMash.GetButtonMashProgress(this));
	}
};