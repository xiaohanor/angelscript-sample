UCLASS(Abstract)
class USkylinePhoneCallWidget : USkylinePhoneGameWidget
{
	UPROPERTY(BindWidget)
	UImage Accept;

	UPROPERTY(BindWidget)
	UImage Decline;

	UPROPERTY(BindWidget)
	UTextBlock TimeText;

	float CallAcceptedTime;

	FOnSkylinePhoneInputResponseSignature OnCallAccepted;
	FOnSkylinePhoneInputResponseSignature OnCallDeclined;

	void OnGameStarted() override
	{
		Super::OnGameStarted();
		Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::PhoneCall);
	}

	void OnClick(FVector2D CursorPos) override
	{
		Super::OnClick(CursorPos);
		
		if(IsWidgetHovered(Accept) && Accept.IsVisible())
		{
			Accept.SetVisibility(ESlateVisibility::Hidden);
			TimeText.SetVisibility(ESlateVisibility::Visible);
			Cast<UCanvasPanelSlot>(Decline.Slot).SetPosition(FVector2D(0, Cast<UCanvasPanelSlot>(Decline.Slot).Position.Y));
			CallAcceptedTime = Time::GameTimeSeconds;
			Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::PhoneAnswered);
			OnCallAccepted.Broadcast();
		}
		else if(IsWidgetHovered(Decline))
		{
			OnCallDeclined.Broadcast();
			GameComplete();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		const float InterpSpeed = 1;
		const float ScaleTarget = 1.2;

		if(IsWidgetHovered(Accept))
		{
			Accept.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Accept.GetRenderTransform().Scale.X, ScaleTarget, InDeltaTime, InterpSpeed));
		}
		else
		{
			Accept.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Accept.GetRenderTransform().Scale.X, 1, InDeltaTime, InterpSpeed));

			if(IsWidgetHovered(Decline))
			{
				Decline.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Decline.GetRenderTransform().Scale.X, ScaleTarget, InDeltaTime, InterpSpeed));
			}
			else
			{
				Decline.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Decline.GetRenderTransform().Scale.X, 1, InDeltaTime, InterpSpeed));
			}
		}

		if(TimeText.IsVisible())
		{
			float CallLength = Time::GetGameTimeSince(CallAcceptedTime);
			const int Minutes = Math::FloorToInt(CallLength / 60);
			const int Seconds = Math::FloorToInt(CallLength - Minutes * 60);
			FString SecondsString = (Seconds < 10 ? "0" : "") + f"{Seconds}";
			FText Text = FText::FromString(f"0{Minutes}:{SecondsString}");
			TimeText.SetText(Text);
		}
	}
}