class UMainMenuOptions : UMainMenuStateWidget
{
	default bShowMenuBackground = true;

	UPROPERTY(BindWidget)
	UOptionsMenu OptionsMenu;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		OptionsMenu.OnClosed.AddUFunction(this, n"OnOptionsClosed");
	}

	UFUNCTION()
	private void OnOptionsClosed()
	{
		MainMenu.ReturnToMainMenu();
	}

	void OnTransitionEnter(EMainMenuState PreviousState, bool bSnap) override
	{
		OptionsMenu.NarrateFullMenu();
		Super::OnTransitionEnter(PreviousState, bSnap);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		return FEventReply::Handled().SetUserFocus(OptionsMenu, InFocusEvent.Cause);
	}
};