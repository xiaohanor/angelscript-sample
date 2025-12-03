
class UMainMenuStateWidget : UHazeUserWidget
{
	default bIsFocusable = true;

	bool bIsActive = false;
	private bool bExitWasSnap = false;

	UPROPERTY()
	float FadeInDelay = 0.0;
	UPROPERTY()
	float FadeInDuration = 0.5;
	UPROPERTY()
	float FadeOutDuration = 0.2;
	UPROPERTY()
	bool bShowMenuBackground = false;
	UPROPERTY()
	FText MenuBackgroundTitle;
	UPROPERTY()
	bool bShowButtonBarBackground = false;

	private float AddTimer = 0.0;
	private float RemoveTimer = 0.0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	AMainMenu MainMenu;

	void OnTransitionEnter(EMainMenuState PreviousState, bool bSnap)
	{
		BP_OnTransitionEnter(PreviousState, bSnap);

		if (bSnap)
		{
			bIsActive = true;
		}
		else
		{
			AddTimer = FadeInDuration + FadeInDelay;
			SetStateFadeOpacity(0.0);
		}
	}

	void SetStateFadeOpacity(float Opacity)
	{
		SetRenderOpacity(Opacity);
	}

	bool CanFadeInState() const
	{
		return true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnTransitionEnter(EMainMenuState PreviousState, bool bSnap) {}

	void OnTransitionExit(EMainMenuState NextState, bool bSnap)
	{
		BP_OnTransitionExit(NextState, bSnap);
		bIsActive = false;
		bExitWasSnap = bSnap;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnTransitionExit(EMainMenuState NextState, bool bSnap) {}
	
	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// Fade in as we get added
		if (AddTimer > 0.0 && CanFadeInState() && !MainMenu.bIsFadingCamera)
		{
			AddTimer -= InDeltaTime;

			float StateOpacity;
			if (AddTimer < FadeInDuration)
				StateOpacity = 1.0 - (AddTimer / FadeInDuration);
			else
				StateOpacity = 1.0;

			SetStateFadeOpacity(StateOpacity);
			bIsActive = (StateOpacity > 0.5);
		}

		// Fade out as we get removed
		if (RemoveTimer > 0.0)
		{
			RemoveTimer -= InDeltaTime;
			SetStateFadeOpacity(Math::Min(RemoveTimer / FadeOutDuration, RenderOpacity));
			if (RemoveTimer <= 0.0)
				FinishRemovingWidget();
		}
	}

	UFUNCTION(BlueprintOverride)
	void RemoveFromScreen()
	{
		if (bExitWasSnap)
		{
			FinishRemovingWidget();
		}
		else
		{
			SetWidgetZOrderInLayer(100);
			SetVisibility(ESlateVisibility::HitTestInvisible);
			RemoveTimer = FadeOutDuration;
			AddTimer = -1.0;
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		// If the console is up, don't eat the key input
		if (Console::IsConsoleActive() || Console::IsConsoleKey(Event.Key))
			return FEventReply::Unhandled();

		// Allow the owner to give input normally, they are using the UI
		if (MainMenu.IsOwnerInput(Event))
			return FEventReply::Unhandled();

		// Don't handle input from invalid identities at this point
		if (MainMenu.IsInvalidInput(Event))
			return FEventReply::Unhandled();

		// Don't absorb certain special keys
		if (Event.Key == EKeys::Escape || Event.Key == EKeys::Gamepad_Special_Left || Event.Key == EKeys::Tab)
			return FEventReply::Unhandled();

		// Don't absorb if focus is something outside of the game (ie console)
		if (Widget::IsSlateUserFocusOutsideGame(int(Event.UserIndex)))
			return FEventReply::Unhandled();

		// By default we ignore all input from users that aren't the main menu's owner,
		// certain widgets such as the local lobby will override this behavior.
		return FEventReply::Handled();
	}
};