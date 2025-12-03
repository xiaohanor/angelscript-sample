class UBattlefieldHoverboardTrickTotalPointsWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UWidget ScoreOverlay;
	UPROPERTY(BindWidget)
	UTextBlock ScoreText;
	UPROPERTY(BindWidget)
	UImage BackgroundCircle;
	UPROPERTY(BindWidget)
	UImage BackgroundCircleBlack;

	UBattlefieldHoverboardTrickComponent TrickComp;

	FHazeAcceleratedFloat CurrentTotalScoreVisual;

	UBattlefieldHoverboardTrickSettings Settings;

	ABattlefieldHoverboardVOManager VOManager;

	FHazeAcceleratedVector2D BGCircleMultScale;

	bool bVO25k;
	bool bVO50k;
	bool bVO75k;
	bool bVO100k;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);
		Settings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);
		
		ScoreText.DynamicFontMaterial.SetVectorParameterValue(n"RightColor", Player.GetPlayerUIColor());
		ScoreText.DynamicFontMaterial.SetVectorParameterValue(n"LeftColor", Settings.Color2[Player]);

		UPlayerHealthComponent::Get(Player).OnDeathTriggered.AddUFunction(this, n"OnDeath");

		BGCircleMultScale.SnapTo(FVector2D(1.3, 1.3));
		BackgroundCircle.SetBrushTintColor((Player.GetPlayerUIColor() + Settings.Color2[Player]) / 2);
	}

	UFUNCTION(BlueprintEvent)
	private void OnDeath()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		CurrentTotalScoreVisual.AccelerateTo(TrickComp.CurrentTotalTrickPoints, 0.5, InDeltaTime);
		const int PointCountShown = Math::RoundToInt(CurrentTotalScoreVisual.Value);

		CheckVOLogic();

		FString ScoreStr = f"{PointCountShown}";
		ScoreText.SetText(FText::FromString(ScoreStr));

		if (ScoreStr.Len() != 0)
		{
			float MultScale = Math::Min(1.0, 5.0 / ScoreStr.Len());
			ScoreOverlay.SetRenderScale(FVector2D(MultScale, MultScale));
			FVector2D BGTargetCircleMultScale = FVector2D::UnitVector * Math::Min(1 + Math::Max(ScoreStr.Len(), 3) / 5.0, 3);
			BGCircleMultScale.SpringTo(BGTargetCircleMultScale, 100, 0.6, InDeltaTime);
			BackgroundCircle.SetRenderScale(BGCircleMultScale.Value);
			BackgroundCircleBlack.SetRenderScale(BGCircleMultScale.Value);
		}
	}

	void CheckVOLogic()
	{
		if (VOManager == nullptr)
			VOManager = TListedActors<ABattlefieldHoverboardVOManager>().GetSingle();

		if (!bVO25k && CurrentTotalScoreVisual.Value >= 25000.0 && CurrentTotalScoreVisual.Value < 50000.0)
		{
			bVO25k = true;
			UBattlefieldHoverboardVOEffectHandler::Trigger_OnBattlefieldTotalScore25k(VOManager, FBattlefieldHoverboardVOParams(Player));
		}
		else if (!bVO50k && CurrentTotalScoreVisual.Value >= 50000.0 && CurrentTotalScoreVisual.Value < 75000.0)
		{
			bVO50k = true;
			UBattlefieldHoverboardVOEffectHandler::Trigger_OnBattlefieldTotalScore50k(VOManager, FBattlefieldHoverboardVOParams(Player));
		}
		else if (!bVO75k && CurrentTotalScoreVisual.Value >= 75000.0 && CurrentTotalScoreVisual.Value < 100000.0)
		{
			bVO75k = true;
			UBattlefieldHoverboardVOEffectHandler::Trigger_OnBattlefieldTotalScore75k(VOManager, FBattlefieldHoverboardVOParams(Player));
		}
		else if (!bVO100k && CurrentTotalScoreVisual.Value >= 100000.0)
		{
			bVO100k = true;
			UBattlefieldHoverboardVOEffectHandler::Trigger_OnBattlefieldTotalScore100k(VOManager, FBattlefieldHoverboardVOParams(Player));
		}	
	}
}