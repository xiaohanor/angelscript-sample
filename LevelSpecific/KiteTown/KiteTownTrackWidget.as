UCLASS(Abstract)
class UKiteTownTrackWidget : UHazeUserWidget
{
	AKiteTownRubberbandingManager Manager;

	UPROPERTY(BindWidget)
	URetainerBox TrackRetainer;
	UPROPERTY(BindWidget)
	UKiteTownTrackDisplay TrackDisplay;

	UPROPERTY(BindWidget)
	UWidget MioWidget;
	UPROPERTY(BindWidget)
	UWidget ZoeWidget;
	UPROPERTY(BindWidget)
	UWidget GoalWidget;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		Manager = KiteTown::GetRubberBandingManager();

		// Don't render on phase during the game, only render the track once
		TrackRetainer.SetRenderingPhase(9999, 1);
	}

	void UpdateWidgetPos(UWidget Widget, FVector WorldPos, bool bRotateOnTrack, float AddedRotation)
	{
		if (Manager == nullptr)
			return;

		UHazeSplineComponent Spline = Manager.RaceSplineActor.Spline;

		FVector RelativePos = Spline.WorldTransform.InverseTransformPosition(WorldPos);
		FVector2D LocalPos = TrackDisplay.SplineRelativeLocationToScreenPos(RelativePos);
		FVector2D AbsPos = TrackRetainer.CachedGeometry.LocalToAbsolute(LocalPos);
		FVector2D CanvasPos = CachedGeometry.AbsoluteToLocal(AbsPos);

		auto WidgetSlot = Cast<UCanvasPanelSlot>(Widget.Slot);
		FMargin Offsets = WidgetSlot.GetOffsets();
		Offsets.Left = CanvasPos.X;
		Offsets.Top = CanvasPos.Y;
		WidgetSlot.SetOffsets(Offsets);

		if (bRotateOnTrack)
		{
			float RotationOnTrack = TrackDisplay.GetScreenRotationOnTrack(RelativePos);
			Widget.SetRenderTransformAngle(RotationOnTrack + AddedRotation);
		}
	}

	FVector GetWorldLocationOnTrack(FVector WorldPos)
	{
		if (Manager == nullptr)
			return WorldPos;

		UHazeSplineComponent Spline = Manager.RaceSplineActor.Spline;
		return Spline.GetClosestSplineWorldLocationToWorldLocation(WorldPos);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (Manager == nullptr)
			return;

		UHazeSplineComponent Spline = Manager.RaceSplineActor.Spline;
		UpdateWidgetPos(
			MioWidget,
			GetWorldLocationOnTrack(Game::Mio.ActorLocation),
			true, 90
		);
		UpdateWidgetPos(
			ZoeWidget,
			GetWorldLocationOnTrack(Game::Zoe.ActorLocation),
			true, -90
		);
		UpdateWidgetPos(
			GoalWidget,
			Spline.GetRelativeLocationAtSplineDistance(Spline.SplineLength),
			false, 0
		);

		auto TrackSlot = Cast<UCanvasPanelSlot>(TrackRetainer.Slot);
		FMargin TrackOffsets = TrackSlot.GetOffsets();
		FAnchors TrackAnchors = TrackSlot.GetAnchors();
		FVector2D TrackAlignment = TrackSlot.GetAlignment();

		if (SceneView::IsPendingFullscreen() && !SceneView::IsFullScreen())
		{
			SetRenderOpacity(
				Math::FInterpConstantTo(GetRenderOpacity(), 0.0, InDeltaTime, 6)
			);
		}
		else
		{
			SetRenderOpacity(
				Math::FInterpConstantTo(GetRenderOpacity(), 1.0, InDeltaTime, 6)
			);

			if (SceneView::IsFullScreen())
			{
				if (SceneView::GetFullScreenPlayer() == Game::Mio)
				{
					TrackAnchors = FAnchors(0, 1);
					TrackAlignment = FVector2D(0, 1);
					TrackOffsets.Left = 50;
					TrackOffsets.Top = -50;
				}
				else
				{
					TrackAnchors = FAnchors(1, 1);
					TrackAlignment = FVector2D(1, 1);
					TrackOffsets.Left = -50;
					TrackOffsets.Top = -50;
				}
			}
			else
			{
				TrackAnchors = FAnchors(0.5, 0.5);
				TrackAlignment = FVector2D(0.5, 0.5);
				TrackOffsets.Left = 0;
				TrackOffsets.Top = 0;
			}
		}

		TrackSlot.SetOffsets(TrackOffsets);
		TrackSlot.SetAnchors(TrackAnchors);
		TrackSlot.SetAlignment(TrackAlignment);

	}
}

class UKiteTownTrackDisplay : UHazeUserWidget
{
	AKiteTownRubberbandingManager Manager;

	const float TrackRotation = -90;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool bIsDesignTime)
	{
#if EDITOR
		if (Manager == nullptr && !Editor::IsPlaying() && bIsDesignTime)
		{
			FScopeDebugEditorWorld EditorScope;
			Manager = KiteTown::GetRubberBandingManager();
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Manager = KiteTown::GetRubberBandingManager();
	}

	FVector2D SplineRelativeLocationToScreenPos(FVector RelativeLocation)
	{
		if (Manager == nullptr)
			return FVector2D();
		if (Manager.RaceSplineActor == nullptr)
			return FVector2D();

		UHazeSplineComponent Spline = Manager.RaceSplineActor.Spline;
		int SampleCount = 500;

		FVector MinPos = Spline.ComputedSpline.Bounds.Min;
		FVector MaxPos = Spline.ComputedSpline.Bounds.Max;
		FVector PosSize = MaxPos - MinPos;

		float TrackPadding = 10;
		FVector2D ScreenStart = FVector2D(TrackPadding, TrackPadding);
		FVector2D ScreenEnd = CachedGeometry.LocalSize - FVector2D(TrackPadding, TrackPadding);

		FVector RelativePos = RelativeLocation;

		FVector PctPos = (RelativePos - MinPos) / PosSize;
		PctPos = PctPos * 2.0 - FVector(1, 1, 1);
		PctPos = PctPos.RotateAngleAxis(TrackRotation, FVector::UpVector);
		PctPos = (PctPos + FVector(1, 1, 1)) * 0.5;

		FVector2D ScreenPos;
		ScreenPos.X = Math::Lerp(ScreenStart.X, ScreenEnd.X, PctPos.X);
		ScreenPos.Y = Math::Lerp(ScreenStart.Y, ScreenEnd.Y, PctPos.Y);
		return ScreenPos;
	}

	float GetScreenRotationOnTrack(FVector RelativeLocation)
	{
		if (Manager == nullptr)
			return 0;
		if (Manager.RaceSplineActor == nullptr)
			return 0;

		UHazeSplineComponent Spline = Manager.RaceSplineActor.Spline;

		float SplineDist = Spline.GetClosestSplineDistanceToRelativeLocation(RelativeLocation);
		FVector2D PrevPos = SplineRelativeLocationToScreenPos(Spline.GetRelativeLocationAtSplineDistance(SplineDist - 100));
		FVector2D NextPos = SplineRelativeLocationToScreenPos(Spline.GetRelativeLocationAtSplineDistance(SplineDist + 100));

		return Math::DirectionToAngleDegrees(NextPos - PrevPos) - 90;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		if (Manager == nullptr)
			return;
		if (Manager.RaceSplineActor == nullptr)
			return;

		UHazeSplineComponent Spline = Manager.RaceSplineActor.Spline;
		int SampleCount = 500;

		FVector MinPos = Spline.ComputedSpline.Bounds.Min;
		FVector MaxPos = Spline.ComputedSpline.Bounds.Max;
		FVector PosSize = MaxPos - MinPos;

		float TrackPadding = 10;
		FVector2D ScreenStart = FVector2D(TrackPadding, TrackPadding);
		FVector2D ScreenEnd = CachedGeometry.LocalSize - FVector2D(TrackPadding, TrackPadding);

		float SplineLength = Spline.SplineLength;
		FVector2D PrevScreenPos;

		float ThicknessMultiplier = WidgetLayout::GetViewportScale();
		float Step = SplineLength / SampleCount;
		for (int i = 0; i < SampleCount; ++i)
		{
			FVector RelativePos = Spline.GetRelativeLocationAtSplineDistance(i * Step);
			FVector PctPos = (RelativePos - MinPos) / PosSize;

			PctPos = PctPos * 2.0 - FVector(1, 1, 1);
			PctPos = PctPos.RotateAngleAxis(TrackRotation, FVector::UpVector);
			PctPos = (PctPos + FVector(1, 1, 1)) * 0.5;

			FVector2D ScreenPos;
			ScreenPos.X = Math::Lerp(ScreenStart.X, ScreenEnd.X, PctPos.X);
			ScreenPos.Y = Math::Lerp(ScreenStart.Y, ScreenEnd.Y, PctPos.Y);

			if (i != 0)
			{
				FVector2D ScreenOverlap = (PrevScreenPos - ScreenPos).GetSafeNormal() * 2.0;
				// if (i == SampleCount - 1)
				// 	ScreenPos += (ScreenPos - PrevScreenPos).GetSafeNormal() * 1.0;

				Context.DrawLine(
					PrevScreenPos + ScreenOverlap,
					ScreenPos,
					FLinearColor(0.2, 0.2, 0.2),
					18 * ThicknessMultiplier);
			}

			PrevScreenPos = ScreenPos;
		}

		for (int i = 0; i < SampleCount; ++i)
		{
			FVector RelativePos = Spline.GetRelativeLocationAtSplineDistance(i * Step);
			FVector PctPos = (RelativePos - MinPos) / PosSize;

			PctPos = PctPos * 2.0 - FVector(1, 1, 1);
			PctPos = PctPos.RotateAngleAxis(TrackRotation, FVector::UpVector);
			PctPos = (PctPos + FVector(1, 1, 1)) * 0.5;

			FVector2D ScreenPos;
			ScreenPos.X = Math::Lerp(ScreenStart.X, ScreenEnd.X, PctPos.X);
			ScreenPos.Y = Math::Lerp(ScreenStart.Y, ScreenEnd.Y, PctPos.Y);

			if (i != 0)
			{
				FVector2D ScreenOverlap = (PrevScreenPos - ScreenPos).GetSafeNormal() * 2.0;
				// if (i == 1)
				// 	ScreenOverlap = FVector2D(0, 0);

				Context.DrawLine(
					PrevScreenPos + ScreenOverlap,
					ScreenPos,
					FLinearColor::White, 15.0 * ThicknessMultiplier);
			}

			PrevScreenPos = ScreenPos;
		}
	}
}