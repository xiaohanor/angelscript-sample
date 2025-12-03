UCLASS(Abstract)
class USkylinePhoneRulesWidget : USkylinePhoneGameWidget
{
	UPROPERTY(BindWidget)
	UTextBlock ClickableText;

	UPROPERTY(BindWidget)
	UVerticalBox VerticalBox;

	UPROPERTY(BindWidget)
	USkylinePhoneCheckBox Check1;

	UPROPERTY(BindWidget)
	USkylinePhoneCheckBox Check2;

	UPROPERTY(BindWidget)
	USkylinePhoneCheckBox Check3;

	UPROPERTY(BindWidget)
	UTextBlock MustHave;

	UPROPERTY(BindWidget)
	UTextBlock MustAccept;

	UPROPERTY(BindWidget)
	UTextBlock MustRead;

	UPROPERTY(BindWidget)
	UCanvasPanel TermsAndConditions;

	UPROPERTY(BindWidget)
	UTextBlock RuleText;

	UPROPERTY(BindWidget)
	UOverlay Next;

	UPROPERTY(BindWidget)
	UOverlay Accept;

	UPROPERTY(BindWidget)
	UOverlay Deactivate;

	
	UPROPERTY(meta=(MultiLine=true))
	TArray<FText> TermsTexts;
	int RuleIndex = 0;

	bool bTermsRead = false;
	TArray<USkylinePhoneCheckBox> Checks;

	FOnSkylinePhoneInputResponseSignature OnInputRejected;
	FOnSkylinePhoneInputResponseSignature OnInputAccepted;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		FVector2D VerticalBoxPos = Cast<UCanvasPanelSlot>(VerticalBox.Slot).Position;
		const FVector2D Size = FVector2D::UnitVector * Check1.SizeBox.WidthOverride;
		const float XPos = VerticalBoxPos.X + Cast<UVerticalBoxSlot>(Check1.Parent.Slot).Padding.Left + Size.X / 2;

		Check1.Position = FVector2D(XPos, VerticalBoxPos.Y - Size.Y - Size.Y / 2);
		Check2.Position = FVector2D(XPos, VerticalBoxPos.Y + Size.Y / 2);
		Check3.Position = FVector2D(XPos, VerticalBoxPos.Y + Size.Y * 3 - Size.Y / 2);

		Checks.Add(Check1);
		Checks.Add(Check2);
		Checks.Add(Check3);

		if(!Phone.bPhoneCalled)
		{
			Timer::SetTimer(this, n"CallPhone", 3);
		}
	}

	void OnGameStarted() override
	{
		Super::OnGameStarted();
		Phone.BroadcastGameEvent(ESkylinePhoneGameEvent::TermsConditions);
	}

	UFUNCTION()
	private void CallPhone()
	{
		Phone.bPhoneCalled = true;
		GameComplete();
	}

	void OnClick(FVector2D CursorPos) override
	{
		Super::OnClick(CursorPos);
		
		if(TermsAndConditions.IsVisible())
		{
			if(Next.IsVisible() && IsWidgetHovered(Next))
			{
				RuleIndex++;
				RuleText.SetText(TermsTexts[RuleIndex]);

				if(RuleIndex + 1 == TermsTexts.Num())
				{
					Next.SetVisibility(ESlateVisibility::Hidden);
					Accept.SetVisibility(ESlateVisibility::Visible);
				}
			}
			else if(Accept.IsVisible() && IsWidgetHovered(Accept))
			{
				bTermsRead = true;
				TermsAndConditions.SetVisibility(ESlateVisibility::Hidden);
			}
		}
		else
		{
			Check1.ClearOutlineRed();
			Check2.ClearOutlineRed();
			MustHave.SetVisibility(ESlateVisibility::Hidden);
			MustAccept.SetVisibility(ESlateVisibility::Hidden);
			MustRead.SetVisibility(ESlateVisibility::Hidden);

			if(IsWidgetHovered(Check1.Position, Check1.Size * 1.2))
			{
				Check1.Check();
			}
			else if(IsWidgetHovered(Check2.Position, Check2.Size * 1.2))
			{
				Check2.Check();
			}
			else if(IsWidgetHovered(Check3.Position, Check3.Size * 1.2))
			{
				Check3.Check();
			}
			else if(IsWidgetHovered(Deactivate))
			{
				if(!Check1.bIsChecked)
				{
					MustHave.SetVisibility(ESlateVisibility::Visible);
					Check1.SetOutlineRed();
					Phone.PlayFailForceFeedback();
					OnInputRejected.Broadcast();
					return;
				}

				if(!Check2.bIsChecked)
				{
					MustAccept.SetVisibility(ESlateVisibility::Visible);
					Check2.SetOutlineRed();
					Phone.PlayFailForceFeedback();
					OnInputRejected.Broadcast();
					return;
				}

				if(!bTermsRead)
				{
					MustRead.SetVisibility(ESlateVisibility::Visible);
					Check2.SetOutlineRed();
					Phone.PlayFailForceFeedback();
					OnInputRejected.Broadcast();
					return;
				}

				OnInputAccepted.Broadcast();
				Phone.PlaySuccessForceFeedback();
				GameComplete();
			}
			else if(IsWidgetHovered(ClickableText))
			{
				TermsAndConditions.SetVisibility(ESlateVisibility::Visible);

				RuleIndex = 0;
				RuleText.SetText(TermsTexts[RuleIndex]);

				Next.SetVisibility(ESlateVisibility::Visible);
				Accept.SetVisibility(ESlateVisibility::Hidden);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(TermsAndConditions.IsVisible())
		{
			ScaleRulesButtons(InDeltaTime);
		}
		else
		{
			ScaleHoveredWidgets(InDeltaTime);
		}
	}

	void ScaleRulesButtons(float DeltaTime)
	{
		const float InterpSpeed = 1;
		const float ScaledButtonSize = 1.15;


		if(IsWidgetHovered(Next))
		{
			Next.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Next.GetRenderTransform().Scale.X, ScaledButtonSize, DeltaTime, InterpSpeed));
		}
		else
		{
			Next.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Next.GetRenderTransform().Scale.X, 1, DeltaTime, InterpSpeed));

			if(IsWidgetHovered(Accept))
			{
				Accept.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Accept.GetRenderTransform().Scale.X, ScaledButtonSize, DeltaTime, InterpSpeed));
			}
			else
			{
				Accept.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Accept.GetRenderTransform().Scale.X, 1, DeltaTime, InterpSpeed));
			}
		}
	}

	void ScaleHoveredWidgets(float DeltaTime)
	{
		const float InterpSpeed = 1;
		const float ScaledBoxSize = 1.15;

		if(IsWidgetHovered(ClickableText))
		{
			ClickableText.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(ClickableText.GetRenderTransform().Scale.X, 1.06, DeltaTime, InterpSpeed));
		}
		else
		{
			ClickableText.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(ClickableText.GetRenderTransform().Scale.X, 1, DeltaTime, InterpSpeed));

			if(IsWidgetHovered(Deactivate))
			{
				Deactivate.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Deactivate.GetRenderTransform().Scale.X, ScaledBoxSize, DeltaTime, InterpSpeed));
			}
			else
			{
				Deactivate.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Deactivate.GetRenderTransform().Scale.X, 1, DeltaTime, InterpSpeed));

				for(auto Checkbox : Checks)
				{
					float SelectedMult = Checkbox.bIsChecked ? 0.9 : 1;

					if(IsWidgetHovered(Checkbox.Position, Checkbox.Size * 1.2))
					{
						Checkbox.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Checkbox.GetRenderTransform().Scale.X, ScaledBoxSize * SelectedMult, DeltaTime, InterpSpeed));
					}
					else
					{
						Checkbox.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Checkbox.GetRenderTransform().Scale.X, 1 * SelectedMult, DeltaTime, InterpSpeed));
					}
				}
			}
		}
	}

	void NextPage()
	{

	}
}