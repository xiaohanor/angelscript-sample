
UCLASS(Abstract)
class UCrosshairContainer : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UCanvasPanel MainCanvas;

	UPROPERTY(BindWidget)
	UCanvasPanel PlayerCanvas;

	UPROPERTY(BindWidget)
	UImage AimDirectionArrow;

	UPROPERTY(BindWidget)
	UWidget CursorWidget;

	UPROPERTY(BindWidget)
	UWidget ReticleDotWidget;

	UPlayerAimingComponent AimComp;
	UCrosshairWidget Crosshair;
	UCanvasPanelSlot CrosshairSlot;
	FAimingResult CurrentTarget;
	FAiming2DCrosshairSettings Crosshair2DSettings;
	FVector AimCenterPosition;

	FVector2D CrosshairScreenPosition;
	bool bCrosshairFollowsTarget = false;

	bool bIsLingering = false;
	bool bIsFadingOut = false;
	float LingerDuration = 0.0;
	float LingerTimer = 0.0;

	float DirectionArrowAlpha = 0.0;
	float NoAimInputTimer = 0.0;
	const float AutoFadeDelay = 0.1;
	const float DirectionFadeDuration = 0.5;

	FHazeAcceleratedVector2D AutoAimPosition;
	USceneComponent CrosshairLockedTarget;
	float CrosshairTargetLockedTime = 0.0;

	void CreateCrosshair(TSubclassOf<UCrosshairWidget> CrosshairWidget)
	{
		if (Crosshair != nullptr)
		{
			Crosshair.RemoveFromParent();
			Crosshair = nullptr;
		}

		PlayerCanvas.Clipping = EWidgetClipping::ClipToBounds;

		Crosshair = Cast<UCrosshairWidget>(
			Widget::CreateWidget(this, CrosshairWidget)
		);
		Crosshair.OverrideWidgetPlayer(Player);
		CrosshairSlot = Cast<UCanvasPanelSlot>(PlayerCanvas.AddChild(Crosshair));
		CrosshairSlot.SetAutoSize(true);
		Crosshair.OnCrosshairShown();

		FSlateColor TintColor;
		TintColor.SpecifiedColor = GetColorForPlayer(Player.Player);
		TintColor.ColorUseRule = ESlateColorStylingMode::UseColor_Specified;
		AimDirectionArrow.SetBrushTintColor(TintColor);

		AutoAimPosition.SnapTo(CrosshairScreenPosition, FVector2D::ZeroVector);

		LingerTimer = 0.0;
		bIsLingering = false;
		bIsFadingOut = false;

		NoAimInputTimer = MAX_flt;

		CrosshairLockedTarget = nullptr;
		CrosshairTargetLockedTime = 0.0;
	}

	void RemoveCrosshair(UCrosshairWidget Widget)
	{
		if (Widget == Crosshair)
		{
			bIsLingering = true;
			Crosshair.OnCrosshairLingerStarted();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (bIsLingering)
		{
			LingerTimer += InDeltaTime;
			if (LingerTimer >= LingerDuration + Crosshair.FadeOutDuration)
			{
				if (Crosshair != nullptr)
				{
					Crosshair.RemoveFromParent();
					Crosshair = nullptr;
				}

				CursorWidget.Visibility = ESlateVisibility::Collapsed;
				AimDirectionArrow.Visibility = ESlateVisibility::Collapsed;
				bIsLingering = false;
			}
			else if (LingerTimer >= LingerDuration)
			{
				if (!bIsFadingOut)
				{
					if (Crosshair != nullptr)
						Crosshair.OnCrosshairFadingOut();
					bIsFadingOut = true;
				}
			}
		}

		float CrosshairAlpha = 1.0;
		if (bIsLingering && LingerTimer >= LingerDuration)
			CrosshairAlpha = 1.0 - Math::Saturate((LingerTimer - LingerDuration) / Crosshair.FadeOutDuration);

		AHazePlayerCharacter ViewPlayer = Player;
		if (SceneView::IsFullScreen() && CurrentTarget.Ray.AimingMode != EAimingMode::Free3DAim)
			ViewPlayer = SceneView::GetFullScreenPlayer();

		// Update the position of the player's canvas on screen
		FVector2D ViewMin, ViewMax;
		SceneView::GetPercentageScreenRectFor(ViewPlayer, ViewMin, ViewMax);

		FAnchors ViewAnchors;
		ViewAnchors.Minimum = ViewMin;
		ViewAnchors.Maximum = ViewMax;

		auto PlayerCanvasSlot = Cast<UCanvasPanelSlot>(PlayerCanvas.Slot);
		PlayerCanvasSlot.Anchors = ViewAnchors;
		PlayerCanvasSlot.Offsets = FMargin();
		PlayerCanvasSlot.Alignment = FVector2D(0.0, 0.0);
		PlayerCanvasSlot.Position = FVector2D(0.0, 0.0);

		bool bCrosshairVisible = true;
		bool bCursorVisible = false;
		bool bReticleDotVisible = false;
		bool bDirectionArrowVisible = true;

		if (Player.IsMio())
		{
			if (AimSettings::CVar_ShowReticleDot_Mio.GetInt() != 0)
				bReticleDotVisible = true;
		}
		else
		{
			if (AimSettings::CVar_ShowReticleDot_Zoe.GetInt() != 0)
				bReticleDotVisible = true;
		}

		if (SceneView::IsFullScreen())
			bReticleDotVisible = false;

		// 2D Modes might change where the crosshair is in screen space
		FVector2D WantedAutoAimPos = CrosshairScreenPosition;
		FVector2D StaticCrosshairPos = CrosshairScreenPosition;
		bool bLerpCrosshairPos = true;
		bool bHasAutoAimTarget = false;

		// Allow the crosshair to disable lerping
		if(Crosshair != nullptr && Crosshair.bDisableLerpCrosshairPos)
			bLerpCrosshairPos = false;

		if (CurrentTarget.Ray.AimingMode == EAimingMode::Cursor2DAim)
		{
			WantedAutoAimPos = CurrentTarget.Ray.CursorPosition;
			StaticCrosshairPos = CurrentTarget.Ray.CursorPosition;
			bLerpCrosshairPos = false;

			bCrosshairVisible = false;
			bReticleDotVisible = false;
			bCursorVisible = Aim2DSettings::CVar_UseSystemCursor.GetInt() == 0;
		}
		else if (CurrentTarget.Ray.AimingMode == EAimingMode::Directional2DAim)
		{
			FVector DirectionalAimTarget = CurrentTarget.Ray.Origin + CurrentTarget.Ray.Direction * Crosshair2DSettings.CrosshairOffset2D;
			bool bAimOnScreen = SceneView::ProjectWorldToViewpointRelativePosition(
				ViewPlayer, DirectionalAimTarget, /*out*/ WantedAutoAimPos
			);

			if (!bAimOnScreen)
				WantedAutoAimPos = FVector2D(0.5, 0.5);

			bLerpCrosshairPos = false;
			bCrosshairVisible = false;
			bReticleDotVisible = false;
		}

		if (CurrentTarget.AutoAimTarget != nullptr)
		{
			// If this isn't a forced auto-aim, we need to recalculate the auto aim target point,
			// because otherwise it will be a frame behind!
			FVector TargetPoint = CurrentTarget.AutoAimTargetPoint;
			if (!AimComp.HasAimingTargetOverride())
			{
				FAimingRay UpdatedRay = AimComp.GetPlayerAimingRay();

				auto AutoAimTarget = Cast<UAutoAimTargetComponent>(CurrentTarget.AutoAimTarget);
				if (AutoAimTarget != nullptr)
				{
					TargetPoint = AutoAimTarget.GetAutoAimTargetPointForRay(UpdatedRay);
					bHasAutoAimTarget = true;
				}
			}

			// Project target into screen space
			bool bAimOnScreen = SceneView::ProjectWorldToViewpointRelativePosition(
				ViewPlayer, TargetPoint, /*out*/ WantedAutoAimPos
			);

			if (!bAimOnScreen)
				WantedAutoAimPos = FVector2D(0.5, 0.5);

			if (CrosshairLockedTarget == CurrentTarget.AutoAimTarget)
			{
				CrosshairTargetLockedTime += InDeltaTime;
			}
			else
			{
				CrosshairLockedTarget = CurrentTarget.AutoAimTarget;
				CrosshairTargetLockedTime = 0.0;
			}
		}
		else
		{
			CrosshairLockedTarget = nullptr;
			CrosshairTargetLockedTime = 0.0;
		}

		// Lerp the position of the crosshair so auto-aim works
		if (bLerpCrosshairPos)
		{
			UPlayerAimingSettings AimSettings = AimComp.PlayerAimingSettings;
			if (WantedAutoAimPos.Equals(AutoAimPosition.Value, AimSettings.CrosshairSnapToDestinationTolerance))
			{
				AutoAimPosition.SnapTo(WantedAutoAimPos, FVector2D::ZeroVector);
			}
			else if (CrosshairLockedTarget != nullptr)
			{
				AutoAimPosition.AccelerateTo(WantedAutoAimPos, Math::Max(AimSettings.CrosshairLerpToTargetDuration - CrosshairTargetLockedTime, 0.0), InDeltaTime);
			}
			else
			{
				AutoAimPosition.AccelerateTo(WantedAutoAimPos, AimSettings.CrosshairLerpToOriginDuration, InDeltaTime);
			}
		}
		else
		{
			AutoAimPosition.SnapTo(WantedAutoAimPos, FVector2D::ZeroVector);
		}

		FVector2D ScreenPos = AutoAimPosition.Value;

		// Don't show cursor while lingering
		if (bIsLingering)
			bCursorVisible = false;

		// Don't show cursor or crosshair while not aiming
		if (Crosshair == nullptr)
		{
			bCursorVisible = false;
			bCrosshairVisible = false;
			bDirectionArrowVisible = false;
		}

		// Don't show anything if the viewpoint is not rendered
		if (!SceneView::IsViewPointRendered(Player))
		{
			bCursorVisible = false;
			bCrosshairVisible = false;
			bReticleDotVisible = false;
			bDirectionArrowVisible = false;
		}

		// Position the crosshair
		if (Crosshair != nullptr)
		{
			FAnchors CrosshairAnchors;
			if (Crosshair.bCrosshairIsOverlay)
			{
				CrosshairAnchors.Minimum = FVector2D(0, 0);
				CrosshairAnchors.Maximum = FVector2D(1, 1);
			}
			else if (bCrosshairFollowsTarget)
			{
				CrosshairAnchors.Minimum = AutoAimPosition.Value;
				CrosshairAnchors.Maximum = AutoAimPosition.Value;
			}
			else
			{
				CrosshairAnchors.Minimum = StaticCrosshairPos;
				CrosshairAnchors.Maximum = StaticCrosshairPos;
			}

			CrosshairSlot.Anchors = CrosshairAnchors;
			CrosshairSlot.Offsets = FMargin();
			CrosshairSlot.Alignment = FVector2D(0.5, 0.5);
			CrosshairSlot.Position = FVector2D(0.0, 0.0);

			if (bCrosshairVisible)
			{
				Crosshair.Visibility = ESlateVisibility::HitTestInvisible;
				Crosshair.SetRenderOpacity(CrosshairAlpha);
			}
			else
			{
				Crosshair.Visibility = ESlateVisibility::Collapsed;
			}

			Crosshair.StaticCrosshairScreenPosition = StaticCrosshairPos;
			Crosshair.AutoAimScreenPosition = AutoAimPosition.Value;
			if (bHasAutoAimTarget)
				Crosshair.AimTargetScreenPosition = WantedAutoAimPos;
			Crosshair.bHasAutoAimTarget = bHasAutoAimTarget;
			Crosshair.OnUpdateCrosshairContainer(InDeltaTime);
		}

		// Position the software cursor if we have it
		if (bCursorVisible)
		{
			CursorWidget.Visibility = ESlateVisibility::HitTestInvisible;

			FAnchors CursorAnchors;
			CursorAnchors.Minimum = StaticCrosshairPos;
			CursorAnchors.Maximum = StaticCrosshairPos;

			float CursorSize = Aim2DSettings::CVar_SoftwareCursorSize.GetFloat();

			FMargin CursorOffset;
			CursorOffset.Left = CursorSize;
			CursorOffset.Top = CursorSize;
			CursorOffset.Right = CursorSize;
			CursorOffset.Bottom = CursorSize;

			auto CursorSlot = Cast<UCanvasPanelSlot>(CursorWidget.Slot);
			CursorSlot.Anchors = CursorAnchors;
			CursorSlot.Offsets = CursorOffset;
			CursorSlot.Alignment = FVector2D(0.5, 0.5);
			CursorSlot.Position = FVector2D(0.0, 0.0);
		}
		else
		{
			CursorWidget.Visibility = ESlateVisibility::Collapsed;
		}

		// We have a directional aim arrow that should be placed around the player when in 2D-mode
		if (CurrentTarget.Ray.AimingMode != EAimingMode::Free3DAim)
		{
			FVector DirectionalAimTarget = CurrentTarget.Ray.Origin + CurrentTarget.Ray.Direction * 10000.0;
			if (bCrosshairFollowsTarget && CurrentTarget.AutoAimTarget != nullptr)
				DirectionalAimTarget = CurrentTarget.AutoAimTargetPoint;

			FVector ArrowCircleCenter = Player.ActorCenterLocation + Player.ActorRotation.RotateVector(Crosshair2DSettings.DirectionOffset);
			FVector ArrowPosition = ArrowCircleCenter + (DirectionalAimTarget - ArrowCircleCenter).GetSafeNormal() * Crosshair2DSettings.CrosshairOffset2D;

			FVector2D ArrowScreenPos;
			bool bArrowOnScreen = SceneView::ProjectWorldToViewpointRelativePosition(
				ViewPlayer, ArrowPosition, /*out*/ ArrowScreenPos
			);

			FVector2D PlayerScreenPos;
			bool bPlayerOnScreen = SceneView::ProjectWorldToViewpointRelativePosition(
				ViewPlayer, ArrowCircleCenter, /*out*/ PlayerScreenPos
			);

			if (bArrowOnScreen && bPlayerOnScreen && bDirectionArrowVisible && Crosshair2DSettings.DirectionalArrowSize > 0)
			{
				FVector2D ExtendedAimPos = PlayerScreenPos + (ScreenPos - PlayerScreenPos) * 5.0;

				AimDirectionArrow.Visibility = ESlateVisibility::HitTestInvisible;
				AimDirectionArrow.RenderTransformAngle = Math::RadiansToDegrees(
					Math::Atan2(ExtendedAimPos.Y - ArrowScreenPos.Y, ExtendedAimPos.X - ArrowScreenPos.X)
				);
				AimDirectionArrow.SetRenderOpacity(CrosshairAlpha * DirectionArrowAlpha);

				FAnchors AimDirAnchors;
				AimDirAnchors.Minimum = ArrowScreenPos;
				AimDirAnchors.Maximum = ArrowScreenPos;

				FMargin AimDirOffset;
				AimDirOffset.Left = Crosshair2DSettings.DirectionalArrowSize;
				AimDirOffset.Top = Crosshair2DSettings.DirectionalArrowSize;
				AimDirOffset.Right = Crosshair2DSettings.DirectionalArrowSize;
				AimDirOffset.Bottom = Crosshair2DSettings.DirectionalArrowSize;

				auto AimDirectionSlot = Cast<UCanvasPanelSlot>(AimDirectionArrow.Slot);
				AimDirectionSlot.Anchors = AimDirAnchors;
				AimDirectionSlot.Offsets = AimDirOffset;
				AimDirectionSlot.Alignment = FVector2D(0.5, 0.5);
				AimDirectionSlot.Position = FVector2D(0.0, 0.0);

				if (CurrentTarget.Ray.bIsGivingAimInput)
					NoAimInputTimer = 0.0;
				else
					NoAimInputTimer += InDeltaTime;

				if (Crosshair2DSettings.bAutoFadeOut && NoAimInputTimer >= AutoFadeDelay)
					DirectionArrowAlpha -= InDeltaTime / DirectionFadeDuration;
				else
					DirectionArrowAlpha += InDeltaTime / DirectionFadeDuration;
				DirectionArrowAlpha = Math::Clamp(DirectionArrowAlpha, 0.0, 1.0);
			}
			else
			{
				AimDirectionArrow.Visibility = ESlateVisibility::Collapsed;
				DirectionArrowAlpha = 0.0;
				NoAimInputTimer = MAX_flt;
			}
		}
		else
		{
			AimDirectionArrow.Visibility = ESlateVisibility::Collapsed;
			DirectionArrowAlpha = 0.0;
			NoAimInputTimer = MAX_flt;
		}

		// We might want to show a small reticle dot as an accessibility option
		if (bReticleDotVisible)
		{
			ReticleDotWidget.Visibility = ESlateVisibility::HitTestInvisible;

			FAnchors ReticleAnchors;
			ReticleAnchors.Minimum = CrosshairScreenPosition;
			ReticleAnchors.Maximum = CrosshairScreenPosition;

			auto ReticleSlot = Cast<UCanvasPanelSlot>(ReticleDotWidget.Slot);
			ReticleSlot.Anchors = ReticleAnchors;
			ReticleSlot.Offsets = FMargin();
			ReticleSlot.Alignment = FVector2D(0.5, 0.5);
			ReticleSlot.Position = FVector2D(0.0, 0.0);
		}
		else
		{
			ReticleDotWidget.Visibility = ESlateVisibility::Collapsed;
		}
	}
};