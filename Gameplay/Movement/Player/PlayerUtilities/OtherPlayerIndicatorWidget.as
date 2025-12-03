class UOtherPlayerIndicatorWidget : UHazeUserWidget
{
	default bAttachToEdgeOfScreen = true;

	EOtherPlayerIndicatorMode IndicatorMode;

	UPROPERTY(BindWidget)
	UImage MarkerImage;

	UPROPERTY()
	TPerPlayer<FLinearColor> PlayerColors;

	UPROPERTY()
	bool bIsAttachedToEdge = false;

	UPROPERTY()
	float ShowDistance = 6000.0;

	UPROPERTY()
	float ShowFadeDistance = 200.0;

	// Screen space offset at minimum distance
	UPROPERTY()
	float MinDistScreenSpaceOffset = 20.0;

	// Screen space offset at maximum distance
	UPROPERTY()
	float MaxDistScreenSpaceOffset = 20.0;

	// Distance at which the maximum screen space offset is reached
	UPROPERTY()
	float MaxOffsetDist = 10000.0;

	bool bIsFadedOut = false;

	float OffscreenLerp = -1.0;
	float DistanceHideLerp = -1.0;

	float PrevOffset = 0.0;
	float PrevHeadingAngle = 0.0;
	float PrevScreenSpaceOffset = 0.0;

	float AlwaysVisibleLerp = 0.0;
	float HiddenLerp = 1.0;

	float CurrentDistance = 0;

	float IndicatorOpacityMultiplier = 1.0;
	private float CurrentOpacityMultiplier = 1.0;

	UFUNCTION(BlueprintOverride)
	void OnAttachToEdgeOfScreen()
	{
		bIsAttachedToEdge = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDetachFromEdgeOfScreen()
	{
		bIsAttachedToEdge = false;
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		UpdateColor();
	}

	void UpdateColor()
	{
		FSlateColor Color;
		Color.ColorUseRule = ESlateColorStylingMode::UseColor_Specified;
		Color.SpecifiedColor = PlayerColors[Player.OtherPlayer.Player];
		MarkerImage.SetBrushTintColor(Color);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float DeltaTime)
	{
		float PrevDistanceLerp = DistanceHideLerp;
		float PrevOffscreenLerp = OffscreenLerp;
		float PrevAlwaysVisibleLerp = AlwaysVisibleLerp;
		float PrevHiddenLerp = HiddenLerp;

		float PrevOpacityMultiplier = CurrentOpacityMultiplier;
		CurrentOpacityMultiplier = IndicatorOpacityMultiplier;

		DistanceHideLerp = Math::Saturate((CurrentDistance - ShowDistance) / ShowFadeDistance);

		if (IndicatorMode == EOtherPlayerIndicatorMode::AlwaysVisible
			|| IndicatorMode == EOtherPlayerIndicatorMode::AlwaysVisibleEvenFullscreen
			|| IndicatorMode == EOtherPlayerIndicatorMode::AlwaysVisibleBothPlayers)
		{
			AlwaysVisibleLerp = Math::FInterpConstantTo(AlwaysVisibleLerp, 1.0, DeltaTime, 3.0);
		}
		else
		{
			AlwaysVisibleLerp = Math::FInterpConstantTo(AlwaysVisibleLerp, 0.0, DeltaTime, 3.0);
		}

		UCameraSingleton CameraSingleton = Game::GetSingleton(UCameraSingleton);

		bool bShouldBeHidden = false;
		if (IndicatorMode == EOtherPlayerIndicatorMode::Hidden)
			bShouldBeHidden = true;
		if (Player.OtherPlayer.IsPlayerDead())
			bShouldBeHidden = true;

		const bool bIsInFullscreen = SceneView::IsFullScreen() || SceneView::IsPendingFullscreen() || CameraSingleton.HasProjectionBlend();
		if (bIsInFullscreen)
		{
			switch (IndicatorMode)
			{
				case EOtherPlayerIndicatorMode::DefaultEvenFullscreen:
				case EOtherPlayerIndicatorMode::AlwaysVisibleEvenFullscreen:
				case EOtherPlayerIndicatorMode::AlwaysVisibleBothPlayers:
				break;

				default:
					bShouldBeHidden = true;
				break;
			}
		}

		if (bShouldBeHidden)
			HiddenLerp = Math::FInterpConstantTo(HiddenLerp, 0.0, DeltaTime, 3.0);
		else
			HiddenLerp = Math::FInterpConstantTo(HiddenLerp, 1.0, DeltaTime, 3.0);

		bool bCountAsOffScreen = bIsAttachedToEdge && (
			UnattachedScreenPosition.X < -0.01 || UnattachedScreenPosition.X > 1.01
			|| UnattachedScreenPosition.Y < -0.01 || UnattachedScreenPosition.Y > 1.01
			|| bIsWidgetOffScreen);

		if (bCountAsOffScreen)
		{
			if (bIsFadedOut)
				OffscreenLerp = 1.0;
			else
				OffscreenLerp = Math::Saturate(OffscreenLerp + (DeltaTime * 3.0));
		}
		else
		{
			if (bIsFadedOut)
				OffscreenLerp = 0.0;
			else
				OffscreenLerp = Math::Saturate(OffscreenLerp - (DeltaTime * 3.0));
		}

		// If we're attached to the edge and the middle split is fading out, fade out this widget too
		float SplitOpacity = SceneView::GetSplitDividerOpacity();
		if (SplitOpacity != -1.0 && bIsOnEdgeOfScreen)
		{
			CurrentOpacityMultiplier *= SplitOpacity;
		}

		if (PrevDistanceLerp != DistanceHideLerp || PrevOffscreenLerp != OffscreenLerp
			|| PrevAlwaysVisibleLerp != AlwaysVisibleLerp || PrevHiddenLerp != HiddenLerp
			|| PrevOpacityMultiplier != CurrentOpacityMultiplier)
		{
			float HeadingAngle = FVector(EdgeAttachDirection.X, EdgeAttachDirection.Y, 0.0).HeadingAngle();
			PrevHeadingAngle = HeadingAngle;

			float FinalOpacity = Math::Max3(DistanceHideLerp, OffscreenLerp, AlwaysVisibleLerp);
			FinalOpacity = Math::Min(FinalOpacity, HiddenLerp);
			FinalOpacity *= CurrentOpacityMultiplier;

			MarkerImage.SetOpacity(FinalOpacity);
			MarkerImage.SetRenderTransformAngle(
				Math::LerpAngleDegrees(
					90.0,
					Math::RadiansToDegrees(HeadingAngle),
					OffscreenLerp)
			);
		}
		else if (OffscreenLerp > 0.0)
		{
			float HeadingAngle = FVector(EdgeAttachDirection.X, EdgeAttachDirection.Y, 0.0).HeadingAngle();
			if (PrevHeadingAngle != HeadingAngle)
			{
				PrevHeadingAngle = HeadingAngle;
				MarkerImage.SetRenderTransformAngle(
					Math::LerpAngleDegrees(
						90.0,
						Math::RadiansToDegrees(HeadingAngle),
						OffscreenLerp)
				);
			}
		}

		float NewScreenSpaceOffset = 
			Math::Lerp(
				Math::Lerp(MinDistScreenSpaceOffset, MaxDistScreenSpaceOffset, Math::Saturate(CurrentDistance / MaxOffsetDist)),
				0.0,
				OffscreenLerp
			);
		if (NewScreenSpaceOffset != PrevScreenSpaceOffset)
		{
			MarkerImage.SetRenderTranslation(FVector2D(0.0, -NewScreenSpaceOffset));
			PrevScreenSpaceOffset = NewScreenSpaceOffset;
		}
	}
};