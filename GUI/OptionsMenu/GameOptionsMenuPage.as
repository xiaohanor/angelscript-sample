class UGameOptionsMenuPage : UOptionsMenuPage
{
	UPROPERTY(BindWidget)
	UWidget PrivacyHeader;
	UPROPERTY(BindWidget)
	UOptionEnumWidget TelemetryOption;
	UPROPERTY(BindWidget)
	UHazeTextWidget TelemetryIdText;
	UPROPERTY(BindWidget)
	UWidget OverrideEntitlementOption;

	bool bShowTelemetryUID = false;
	bool bLeftTriggerDown = false;
	bool bRightTriggerDown = false;

	UFUNCTION(BlueprintPure)
	bool ShouldShowDevOptions() const
	{
#if TEST
		return true;
#else
		return false;
#endif
	}

	UFUNCTION(BlueprintPure)
	bool ShouldShowTelemetryId() const
	{
		return bShowTelemetryUID || ShouldShowDevOptions();
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Super::Construct();

		TelemetryIdText.SetText(FText::FromString(f"(DEV) Telemetry UID: {Telemetry::GetTelemetryPlayerId()}"));

		// Underage players should not be able to change the usage sharing setting
		if (Online::IsIdentityUnderage(Online::GetPrimaryIdentity()))
		{
			PrivacyHeader.Visibility = ESlateVisibility::Collapsed;
			TelemetryOption.Visibility = ESlateVisibility::Collapsed;
			TelemetryIdText.Visibility = ESlateVisibility::Collapsed;
		}

		if (ShouldShowTelemetryId())
			TelemetryIdText.Visibility = ESlateVisibility::HitTestInvisible;
		else
			TelemetryIdText.Visibility = ESlateVisibility::Collapsed;

		if (ShouldShowDevOptions())
			OverrideEntitlementOption.Visibility = ESlateVisibility::Visible;
		else
			OverrideEntitlementOption.Visibility = ESlateVisibility::Collapsed;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.IsControlDown() && InKeyEvent.Key == EKeys::F10)
		{
			bShowTelemetryUID = !bShowTelemetryUID;
			if (bShowTelemetryUID)
				TelemetryIdText.Visibility = ESlateVisibility::HitTestInvisible;
			else
				TelemetryIdText.Visibility = ESlateVisibility::Collapsed;

			return FEventReply::Handled();
		}
		else if (InKeyEvent.Key == EKeys::Gamepad_LeftTrigger)
		{
			if (bRightTriggerDown)
			{
				bLeftTriggerDown = true;
				return FEventReply::Handled();
			}
		}
		else if (InKeyEvent.Key == EKeys::Gamepad_RightTrigger)
		{
			bRightTriggerDown = true;
			return FEventReply::Handled();
		}
		else if (InKeyEvent.Key == EKeys::Gamepad_LeftThumbstick)
		{
			if (bLeftTriggerDown && bRightTriggerDown)
			{
				bShowTelemetryUID = !bShowTelemetryUID;
				if (bShowTelemetryUID)
					TelemetryIdText.Visibility = ESlateVisibility::HitTestInvisible;
				else
					TelemetryIdText.Visibility = ESlateVisibility::Collapsed;
			}
			return FEventReply::Handled();
		}
		else if (
			(InKeyEvent.Key == EKeys::Gamepad_RightThumbstick && bLeftTriggerDown && bRightTriggerDown)
			|| (InKeyEvent.Key == EKeys::F6 && InKeyEvent.IsControlDown())
			)
		{
			UGlobalMenuSingleton MenuSingleton = Game::GetSingleton(UGlobalMenuSingleton);
			MenuSingleton.bDisplayTimer = !MenuSingleton.bDisplayTimer;

			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.Key == EKeys::Gamepad_LeftTrigger)
		{
			bLeftTriggerDown = false;
			return FEventReply::Handled();
		}
		else if (InKeyEvent.Key == EKeys::Gamepad_RightTrigger)
		{
			bRightTriggerDown = false;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}
}