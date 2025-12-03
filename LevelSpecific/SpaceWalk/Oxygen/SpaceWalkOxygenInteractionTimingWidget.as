class USpaceWalkOxygenInteractionTimingWidget : UHazeUserWidget
{
	UPROPERTY(EditAnywhere)
	FLinearColor MioRangeColor = PlayerColor::Mio;
	UPROPERTY(EditAnywhere)
	FLinearColor ZoeRangeColor = PlayerColor::Zoe;

	UPROPERTY(BindWidget)
	UImage RangeHighlight;
	UPROPERTY(BindWidget)
	UWidget PendulumContainer;

	UPROPERTY(BindWidget)
	UImage BarActive;

	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation LeftPress;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation RightPress;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Enter;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Success;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Fail;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Finish;

	bool bIsFailed;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		UMaterialInstanceDynamic RangeMaterial = RangeHighlight.GetDynamicMaterial();
		RangeMaterial.SetVectorParameterValue(n"Color", FLinearColor::Transparent);

		UMaterialInstanceDynamic BarMaterial = BarActive.GetDynamicMaterial();
		BarMaterial.SetScalarParameterValue(n"StartPercentage", 0.5);
		BarMaterial.SetScalarParameterValue(n"EndPercentage", 0.5);

		PlayAnimation(Enter, 0.0, PlaybackSpeed = 0.0);
	}

	void StartPumping()
	{
		StopAllAnimations();
		PlayAnimation(Enter, 0.0);
	}

	void PushLeft()
	{
		PlayAnimation(LeftPress);
	}

	void PushRight()
	{
		PlayAnimation(RightPress);
	}

	void PumpSuccess()
	{
		PlayAnimation(Success);
	}

	void PumpFail()
	{
		PlayAnimation(Fail);
	}
	
	void InteractionCompleted()
	{
		PlayAnimation(Finish);
		UpdateCompletion(1.0);
	}

	void UpdateSuccessWindow(EHazePlayer ActivePlayer, float SuccessPoint, float WindowSizePct)
	{
		if (bIsFailed)
			return;

		UMaterialInstanceDynamic RangeMaterial = RangeHighlight.GetDynamicMaterial();

		float StartPct;
		float EndPct;

		float StartAngle = 0.287;
		float Margin = 0.0;

		if (ActivePlayer == EHazePlayer::Mio)
		{
			RangeMaterial.SetVectorParameterValue(n"Color", MioRangeColor);

			if (SuccessPoint < 1.0)
				StartPct = StartAngle - (StartAngle * 2.0) * (SuccessPoint - Margin);
			else
				StartPct = StartAngle - (StartAngle * 2.0) * SuccessPoint;
			EndPct = StartAngle - (StartAngle * 2.0) * (SuccessPoint - WindowSizePct + Margin);
		}
		else
		{
			RangeMaterial.SetVectorParameterValue(n"Color", ZoeRangeColor);

			if (SuccessPoint < 1.0)
				EndPct = -StartAngle + (StartAngle * 2.0) * (SuccessPoint - Margin);
			else
				EndPct = -StartAngle + (StartAngle * 2.0) * SuccessPoint;
			StartPct = -StartAngle + (StartAngle * 2.0) * (SuccessPoint - WindowSizePct + Margin);
		}

		RangeMaterial.SetScalarParameterValue(n"StartPercentage", StartPct);
		RangeMaterial.SetScalarParameterValue(n"EndPercentage", EndPct);
	}

	void UpdateTiming(EHazePlayer ActivePlayer, float TimingPct, bool bWouldBeSuccess)
	{
		float Angle;
		if (ActivePlayer == EHazePlayer::Mio)
			Angle = 100 - TimingPct * 200;
		else
			Angle = -100 + TimingPct * 200;

		PendulumContainer.SetRenderTransformAngle(Angle);
	}

	void UpdateCompletion(float CompletionPct)
	{
		UMaterialInstanceDynamic BarMaterial = BarActive.GetDynamicMaterial();

		float StartAngle = 0.285;
		BarMaterial.SetScalarParameterValue(n"StartPercentage", -StartAngle);
		BarMaterial.SetScalarParameterValue(n"EndPercentage", -StartAngle + CompletionPct * StartAngle * 2.0);
	}

	void UpdateFailedState(bool bFailed)
	{
		bIsFailed = bFailed;
		if (bIsFailed)
		{
			UMaterialInstanceDynamic RangeMaterial = RangeHighlight.GetDynamicMaterial();
			RangeMaterial.SetVectorParameterValue(n"Color", FLinearColor::Transparent);
		}
	}
}