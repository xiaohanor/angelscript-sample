class USolarFlarePowerMeterCoverInteractionCapability : UInteractionCapability
{
	ASolarFlarePowerMeterCover Cover;

	UInteractionComponent InteractionComp;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		InteractionComp = Params.Interaction;
		Cover = Cast<ASolarFlarePowerMeterCover>(Params.Interaction.Owner);
		Player.ActivateCamera(Cover.StaticCamera, 2.0, this);

		FButtonMashSettings Settings;
		Settings.ButtonAction = ActionNames::Interaction;
		Settings.Difficulty = EButtonMashDifficulty::Medium;
		Settings.Mode = EButtonMashMode::ButtonMash;
		Settings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
		Settings.WidgetAttachComponent = Player.RootComponent;
		Player.StartButtonMash(Settings, this);
		Player.SetButtonMashAllowCompletion(this, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		Player.StopButtonMash(this);
		Player.DeactivateCamera(Cover.StaticCamera, 2.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Cover.SetButtonMashProgress(InteractionComp, Player.GetButtonMashProgress(this));
	}
}