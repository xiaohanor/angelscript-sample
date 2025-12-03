class UPlayerRespawnMashOverlayWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UCanvasPanel FullscreenPanel;

	UPROPERTY(BindWidget)
	UCanvasPanel PlayerPanel;

	UPROPERTY(BindWidget)
	UCanvasPanel MashPanel;

	UPROPERTY(BindWidget)
	UWidget ShapePanel;

	UPROPERTY(BindWidget)
	UWidget TipContainer;

	UPROPERTY(BindWidget)
	URespawnMenuShapeWidget RespawnShape;
	
	UPROPERTY(BindWidget)
	UImage ProgressBar;

	UPROPERTY(BindWidget)
	UInputButtonWidget InputButton;

	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation PulseAnimation;

	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation LoopingPulseAnimation;
	
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Enter;

	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Complete;

	UPROPERTY(BindWidget)
	UBackgroundBlur BlurBackground;

	UPROPERTY(BindWidget)
	UWidget MashIndicatorWidget;

	UPROPERTY(BindWidget)
	UWidget HoldIndicatorWidget;

	bool bIsRespawnMashActive = false;
	bool bIsWaitingForRespawn = false;
	bool bIsRespawning = false;
	UMaterialInstanceDynamic Material;
	float ShowDelay = 0.0;

	bool bShowAtTopOfScreenInFullscreen = true;
	bool bIsBossHealthBarActive = false;

	bool bShownWaitingShape = false;
	bool bShownRespawnMash = false;
	bool bShownWaitComplete = false;
	float WaitingTimer = 0.0;
	bool bIsShown = false;
	float CurrentOpacity = 0.0;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		BlurBackground.SetBlurStrength(0.0);
		PlayerPanel.SetRenderOpacity(0.0);
		Material = ProgressBar.GetDynamicMaterial();
		ShowDelay = 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
	}

	void TriggeredRespawn()
	{
		if (!bShownWaitingShape)
			PlayAnimation(Complete);
	}

	UFUNCTION(BlueprintOverride)
	void RemoveFromScreen()
	{
		if (!IsAnimationPlaying(Complete) && (!bShownWaitingShape || bShownWaitComplete))
			FinishRemovingWidget();
	}

	UFUNCTION(BlueprintOverride)
	void OnAnimationFinished(const UWidgetAnimation Animation)
	{
		if (bIsInDelayedRemove && Animation == Complete)
			FinishRemovingWidget();
		if (Animation == Enter && !bIsInDelayedRemove)
			PlayAnimation(LoopingPulseAnimation, NumLoopsToPlay = 0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		FVector2D ViewMin;
		FVector2D ViewMax;
		SceneView::GetPercentageScreenRectFor(Player, ViewMin, ViewMax);

		UCanvasPanelSlot ProgressSlot = Cast<UCanvasPanelSlot>(PlayerPanel.Slot);
		float OpacityTarget = 1.0;

		if (bIsRespawnMashActive)
		{
			MashPanel.Visibility = ESlateVisibility::Visible;
			ShapePanel.Visibility = ESlateVisibility::Visible;
			bShownRespawnMash = true;
		}
		else if (bShownRespawnMash)
		{
			MashPanel.Visibility = ESlateVisibility::Visible;
			ShapePanel.Visibility = ESlateVisibility::Visible;
			OpacityTarget = 0.0;
		}
		else if (!bIsRespawnMashActive && bIsWaitingForRespawn)
		{
			MashPanel.Visibility = ESlateVisibility::Hidden;
			ShapePanel.Visibility = ESlateVisibility::Visible;

			bShownWaitingShape = true;
			WaitingTimer = Math::FInterpTo(WaitingTimer, 0.7, InDeltaTime, 0.25);
			Update(WaitingTimer);
		}
		else if (bShownWaitingShape)
		{
			MashPanel.Visibility = ESlateVisibility::Hidden;
			ShapePanel.Visibility = ESlateVisibility::Visible;

			WaitingTimer = Math::FInterpConstantTo(WaitingTimer, 1.0, InDeltaTime, 3.0);
			Update(WaitingTimer);

			if (WaitingTimer >= 1.0)
			{
				if (!bShownWaitComplete)
				{
					PlayAnimation(Complete);
					bShownWaitComplete = true;
				}

				OpacityTarget = 0.0;
			}
		}
		else
		{
			MashPanel.Visibility = ESlateVisibility::Hidden;
			ShapePanel.Visibility = ESlateVisibility::Hidden;
		}

		if (!bIsRespawning)
			ShowDelay -= InDeltaTime;

		if (ShowDelay <= 0.0)
		{
			CurrentOpacity = Math::FInterpConstantTo(CurrentOpacity, OpacityTarget, InDeltaTime, 5.0);
			BlurBackground.SetBlurStrength(CurrentOpacity * 4.0);

			if (bIsShown && !IsAnimationPlaying(Enter))
			{
				PlayerPanel.SetRenderOpacity(CurrentOpacity);
			}
			else if (OpacityTarget >= 1.0 && ShowDelay < -0.2)
			{
				PlayerPanel.SetRenderOpacity(1.0);
				if (!bIsShown)
				{
					PlayAnimation(Enter);
					bIsShown = true;
				}
			}
			else
			{
				PlayerPanel.SetRenderOpacity(0.0);
			}
		}

		if (SceneView::IsFullScreen() || SceneView::IsPendingFullscreen() || SceneView::GetSplitScreenMode() == EHazeSplitScreenMode::CustomMerge)
		{
			BlurBackground.Visibility = ESlateVisibility::Collapsed;
			PlayerPanel.SetRenderScale(FVector2D(0.9, 0.9));

			if (bShowAtTopOfScreenInFullscreen)
			{
				float AspectRatio = float(SceneView::FullViewportResolution.X) / float(SceneView::FullViewportResolution.Y);
				if (bIsBossHealthBarActive && AspectRatio < 16.0/9.0)
				{
					if (Player.IsMio())
					{
						FAnchors Anchors;
						Anchors.Minimum = FVector2D(0.0, 0.1);
						Anchors.Maximum = Anchors.Minimum;

						ProgressSlot.SetAnchors(Anchors);
						ProgressSlot.SetAlignment(FVector2D(0.0, 0.0));
					}
					else
					{
						FAnchors Anchors;
						Anchors.Minimum = FVector2D(1.0, 0.1);
						Anchors.Maximum = Anchors.Minimum;

						ProgressSlot.SetAnchors(Anchors);
						ProgressSlot.SetAlignment(FVector2D(1.0, 0.0));
					}
				}
				else
				{
					if (Player.IsMio())
					{
						FAnchors Anchors;
						Anchors.Minimum = FVector2D(0.0, 0.0);
						Anchors.Maximum = Anchors.Minimum;

						ProgressSlot.SetAnchors(Anchors);
						ProgressSlot.SetAlignment(FVector2D(0.0, 0.0));
					}
					else
					{
						FAnchors Anchors;
						Anchors.Minimum = FVector2D(1.0, 0.0);
						Anchors.Maximum = Anchors.Minimum;

						ProgressSlot.SetAnchors(Anchors);
						ProgressSlot.SetAlignment(FVector2D(1.0, 0.0));
					}
				}
			}
			else
			{
				if (Player.IsMio())
				{
					FAnchors Anchors;
					Anchors.Minimum = FVector2D(0.0, 1.0);
					Anchors.Maximum = Anchors.Minimum;

					ProgressSlot.SetAnchors(Anchors);
					ProgressSlot.SetAlignment(FVector2D(0.0, 1.0));
				}
				else
				{
					FAnchors Anchors;
					Anchors.Minimum = FVector2D(1.0, 1.0);
					Anchors.Maximum = Anchors.Minimum;

					ProgressSlot.SetAnchors(Anchors);
					ProgressSlot.SetAlignment(FVector2D(1.0, 1.0));
				}
			}
		}
		else
		{
			FAnchors Anchors;
			Anchors.Minimum = (ViewMax + ViewMin) * 0.5;
			Anchors.Maximum = Anchors.Minimum;

			ProgressSlot.SetAnchors(Anchors);
			ProgressSlot.SetAlignment(FVector2D(0.5, 0.5));

			BlurBackground.Visibility = ESlateVisibility::Visible;
			PlayerPanel.SetRenderScale(FVector2D(1.0, 1.0));

			auto BlurSlot = Cast<UCanvasPanelSlot>(BlurBackground.Slot);

			FAnchors BlurAnchors;
			BlurAnchors.Minimum = ViewMin;
			BlurAnchors.Maximum = ViewMax;
			BlurSlot.SetAnchors(BlurAnchors);
		}
	}

	void Initialize()
	{
	}

	void SetState(bool bIsHold, bool bIsAutomatic)
	{
		if (bIsAutomatic)
		{
			HoldIndicatorWidget.Visibility = ESlateVisibility::Hidden;
			MashIndicatorWidget.Visibility = ESlateVisibility::Hidden;
			InputButton.Visibility = ESlateVisibility::Hidden;
		}
		else if (bIsHold)
		{
			HoldIndicatorWidget.Visibility = ESlateVisibility::Visible;
			InputButton.Visibility = ESlateVisibility::Visible;
			MashIndicatorWidget.Visibility = ESlateVisibility::Hidden;
		}
		else
		{
			HoldIndicatorWidget.Visibility = ESlateVisibility::Hidden;
			InputButton.Visibility = ESlateVisibility::Visible;
			MashIndicatorWidget.Visibility = ESlateVisibility::Visible;
		}
	}

	void Update(float Progress)
	{
		Material.SetVectorParameterValue(n"EndColor", Player.GetPlayerUIColor());

		const float Distance = 0.46;
		float Segment = 1.0 / 6.0;

		float PreviousPct = Math::FloorToFloat(Progress / Segment) * Segment;
		float NextPct = PreviousPct + Segment;
		float SegmentAlpha = (Progress - PreviousPct) / Segment;

		Material.SetScalarParameterValue(n"Progress", PreviousPct + SegmentAlpha * Segment);

		FVector2D PreviousPoint = Math::AngleDegreesToDirection(PreviousPct * 360.0);
		FVector2D NextPoint = Math::AngleDegreesToDirection(NextPct * 360.0);
		FVector2D CurrentPoint = Math::Lerp(PreviousPoint, NextPoint, SegmentAlpha);

		FVector2D CurrentPosition = (FVector2D(CurrentPoint.Y, -CurrentPoint.X) * Distance) + FVector2D(0.5, 0.5);

		auto TipSlot = Cast<UCanvasPanelSlot>(TipContainer.Slot);
		TipSlot.SetAnchors(
			FAnchors(
				CurrentPosition.X, CurrentPosition.Y,
				CurrentPosition.X, CurrentPosition.Y,
			)
		);

		RespawnShape.Update(Progress);
	}

	void Pulse()
	{
		PlayAnimation(PulseAnimation);
		UDeathEffect::Trigger_OnRespawnPulseMash(Player);
	}
};

UCLASS(Abstract)
class URespawnMenuShapeWidget : UHazeUserWidget
{
	UPROPERTY(Transient, Meta = (BindWidgetAnim))
	UWidgetAnimation Assembly;

	bool bAnimPlaying = false;

	void Update(float Progress)
	{
		if (!bAnimPlaying)
		{
			bAnimPlaying = true;
			PlayAnimation(Assembly, PlaybackSpeed = 0);
		}

		SetAnimationCurrentTime(Assembly, Progress * Assembly.EndTime);
	}
}