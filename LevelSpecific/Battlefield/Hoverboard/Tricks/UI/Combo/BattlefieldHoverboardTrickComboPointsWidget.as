class UBattlefieldHoverboardTrickComboPointsWidget : UHazeUserWidget
{
	int PointCountShown = 0;
	float TargetPointCount = 0.0;

	UPROPERTY(BindWidget)
	UWidget ScoreOverlay;
	UPROPERTY(BindWidget)
	UTextBlock ScoreText;

	UPROPERTY(BindWidget)
	UCanvasPanel ScoreCanvas;

	UCanvasPanelSlot CanvasPanelSlot;

	UPROPERTY(BindWidget)
	UWidget MultOverlay;
	UPROPERTY(BindWidget)
	UTextBlock MultText;
	UPROPERTY(BindWidget)
	UTextBlock MultTextBG;

	UBattlefieldHoverboardTrickComponent TrickComp;

	FHazeAcceleratedFloat AccPointCountShown;

	UBattlefieldHoverboardTrickSettings Settings;

	bool bHasStartedGoingDown = false;
	int PreviousTrickCount = 0;
	float CurrentMult = 1;
	FHazeAcceleratedFloat AccMult;
	bool bIsDone = false;
	const float RemoveAnimationDuration = 0.65;
	const float FailAnimationDuration = 0.6;
	const float BarTargetHeightOffset = 180;
	const float BarTargetXOffset = 45;
	float ComboFinishedTime;

	FHazeAcceleratedVector2D WidgetPosition;

	ABattlefieldHoverboardVOManager VOManager;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);
		Settings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);

		ScoreText.DynamicFontMaterial.SetVectorParameterValue(n"RightColor", Player.GetPlayerUIColor());
		ScoreText.DynamicFontMaterial.SetVectorParameterValue(n"LeftColor", Settings.Color2[Player]);
		ScoreText.SetRenderOpacity(0);

		MultText.DynamicFontMaterial.SetVectorParameterValue(n"RightColor", Player.GetPlayerUIColor());
		MultText.DynamicFontMaterial.SetVectorParameterValue(n"LeftColor", Settings.Color2[Player]);
		MultText.SetRenderOpacity(0);
		AccMult.SnapTo(1);

		MultTextBG.DynamicFontMaterial.SetVectorParameterValue(n"RightColor", Player.GetPlayerUIColor());
		MultTextBG.DynamicFontMaterial.SetVectorParameterValue(n"LeftColor", Settings.Color2[Player]);

		TrickComp.OnTrickFailed.AddUFunction(this, n"FailTrick");

		CanvasPanelSlot = Cast<UCanvasPanelSlot>(ScoreCanvas.Slot);
	}

	UFUNCTION()
	private void FailTrick()
	{
		OnScoreCountFinished();
	}

	UFUNCTION(BlueprintEvent)
	private void OnIncreaseScore()
	{
	}

	UFUNCTION(BlueprintEvent)
	private void OnIncreaseMult()
	{
	}

	UFUNCTION(BlueprintEvent)
	private void OnPointsReset()
	{
	}

	UFUNCTION(BlueprintEvent)
	private void OnTrickFailed()
	{
	}


	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(TrickComp.CurrentTrickCombo.IsSet() && !bIsDone)
		{
			TickComboSet(InDeltaTime);
		}
		// Combo has ended, make points go down and fade out
		else
		{
			TickNoComboSet(InDeltaTime);
		}
		
		// Python magic: pad number with 0s until 3 numbers
		if(PointCountShown != 0)
		{
			FString PointStr = f"{PointCountShown}";
			ScoreText.SetText(FText::FromString(PointStr));

			if (PointStr.Len() != 0)
			{
				// Calculate render scale for the text based on how long the string is
				float PointScale = Math::Min(1.0, 4.0 / PointStr.Len());
				ScoreOverlay.SetRenderScale(FVector2D(PointScale, PointScale));
			}
		}

		if(!bIsDone)
		{
			AccPointCountShown.AccelerateTo(TargetPointCount, Settings.ComboPointUpdateDuration, InDeltaTime);
			AccMult.Value = CurrentMult;
		}
		else
		{
			AccPointCountShown.AccelerateTo(TargetPointCount, 1, InDeltaTime);
		}

		PointCountShown = Math::RoundToInt(AccPointCountShown.Value);

		FString MultStr = f"x{Math::TruncFloatDecimals(AccMult.Value, 1)}";
		MultText.SetText(FText::FromString(MultStr));
		MultTextBG.SetText(FText::FromString(MultStr));

		// Calculate render scale for the text based on how long the string is
		if (MultStr.Len() != 0)
		{
			float MultScale = Math::Min(1.0, 4.0 / MultStr.Len());
			MultOverlay.SetRenderScale(FVector2D(MultScale, MultScale));
		}
	}

	void OnScoreCountFinished()
	{
		bHasStartedGoingDown = true;

		if(TrickComp.bTrickFailed)
		{
			OnTrickFailed();
			Timer::SetTimer(this, n"RemoveWithNoPoints", FailAnimationDuration);
			return;
		}

		WidgetPosition.SnapTo(CanvasPanelSlot.Position);
		ComboFinishedTime = Time::GameTimeSeconds;
		TargetPointCount = Math::CeilToInt(TargetPointCount * CurrentMult / 5.0) * 5;

		
		bHasStartedGoingDown = true;
		OnPointsReset();
		PreviousTrickCount = 0;

		if(Player.IsPlayerDead())
		{
			Player.RemoveWidget(this);
		}
		else
		{
			Timer::SetTimer(this, n"RemoveAndAwardPoints", RemoveAnimationDuration);
		}
		
		bIsDone = true;
	}

	UFUNCTION()
	void RemoveWithNoPoints()
	{
		Player.RemoveWidget(this);
	}

	UFUNCTION()
	void RemoveAndAwardPoints()
	{
		if (VOManager == nullptr)
			VOManager = TListedActors<ABattlefieldHoverboardVOManager>().GetSingle();

		if (TargetPointCount > 5000.0 && TargetPointCount < 10000.0)
			UBattlefieldHoverboardVOEffectHandler::Trigger_OnBattlefieldCombo5k(VOManager, FBattlefieldHoverboardVOParams(Player));
		else if (TargetPointCount > 10000.0 && TargetPointCount < 20000.0)
			UBattlefieldHoverboardVOEffectHandler::Trigger_OnBattlefieldCombo10k(VOManager, FBattlefieldHoverboardVOParams(Player));
		else if (TargetPointCount > 20000.0)
			UBattlefieldHoverboardVOEffectHandler::Trigger_OnBattlefieldCombo20k(VOManager, FBattlefieldHoverboardVOParams(Player));

		TrickComp.CurrentTotalTrickPoints += TargetPointCount;
		Player.RemoveWidget(this);
	}

	void TickComboSet(float InDeltaTime)
	{
		if(bHasStartedGoingDown)
			return;

		auto CurrentCombo = TrickComp.CurrentTrickCombo.Value;
		TargetPointCount = CurrentCombo.ComboPoints;


		if(TrickComp.CurrentTrickCombo.Value.TrickCount != PreviousTrickCount)
		{
			PreviousTrickCount = TrickComp.CurrentTrickCombo.Value.TrickCount;
			
			if(PreviousTrickCount != 0)
				OnIncreaseScore();
		}

		if(CurrentCombo.ComboMultiplier > CurrentMult)
		{
			CurrentMult = CurrentCombo.ComboMultiplier;
			OnIncreaseMult();
		}

		CurrentMult = CurrentCombo.ComboMultiplier;

		float CurrentOpacity = ScoreText.GetRenderOpacity();
		if(CurrentOpacity < 1.0)
			ScoreText.SetRenderOpacity(Math::FInterpConstantTo(CurrentOpacity, 1, InDeltaTime, 1 / Settings.ComboPointFadeDuration));

		CurrentOpacity = MultText.GetRenderOpacity();
		if(CurrentOpacity < 1.0)
			MultText.SetRenderOpacity(Math::FInterpConstantTo(CurrentOpacity, 1, InDeltaTime, 1 / Settings.MultFadeDuration));
	}

	void TickNoComboSet(float InDeltaTime)
	{
		if(!bHasStartedGoingDown)
		{
			OnScoreCountFinished();
		}

		const float TimeSinceComboEnded = Time::GetGameTimeSince(TrickComp.LastTimeTrickComboCompleted);
		
		AccPointCountShown.AccelerateTo(TargetPointCount, Settings.ComboPointFallDuration, InDeltaTime);
		PointCountShown = Math::RoundToInt(AccPointCountShown.Value);
		
		if(TimeSinceComboEnded > Settings.ComboMultFallDelay)
			MultText.SetRenderOpacity(Math::FInterpConstantTo(MultText.GetRenderOpacity(), 0, InDeltaTime, 1 / Settings.MultFadeDuration));
	}
}