
event void FOnFrameSelected(int Frame);
event void FOnTimelineShifted();

const int VIEW_FRAME_INVALID = MIN_int32;
const int VIEW_DEFAULT_FRAMECOUNT = 800;

class UTemporalLogTimelineWidget : UHazeUserWidget
{
	UPROPERTY()
	FSlateBrush BackgroundBrush;

	UPROPERTY()
	FSlateBrush SelectedBackgroundBrush;

	UPROPERTY()
	FSlateBrush SelectedForegroundBrush;

	UPROPERTY()
	FSlateBrush HoveredBackgroundBrush;

	UPROPERTY()
	FSlateBrush HoveredForegroundBrush;

	UPROPERTY()
	FSlateBrush LeftMoreDataBrush;

	UPROPERTY()
	FSlateBrush RightMoreDataBrush;

	UPROPERTY()
	int SelectedFrame = -1;

	UPROPERTY()
	int HoveredFrame = -1;

	UPROPERTY(NotEditable)
	FHazeTemporalLogWatchReport FrameTimeline;

	UPROPERTY(NotEditable)
	FHazeTemporalLogWatchReport StatusWatch;

	UHazeTemporalLog TemporalLog;
	TArray<FHazeTemporalLogWatchReport> Watches;
	TArray<FHazeTemporalLogGraphReport> Graphs;

	FOnFrameSelected OnFrameSelected;
	FOnTimelineShifted OnTimelineShifted;

	bool bIsScrubbing = false;

	bool bIsSelectingRange = false;
	bool bIsRangeSelected = false;
	int RangeStartFrame = -1;
	int RangeEndFrame = -1;
	int DataStartFrame = 0;

	bool bIsShifting = false;
	FVector2D MouseShiftStart;
	int MouseFrameShift = 0;

	float TimelinePadding = 2.0;
	float MarkerForegroundSize = 2.0;
	float MarkerBackgroundSize = 5.0;

	int ViewStartFrame = VIEW_FRAME_INVALID;
	int ViewEndFrame = VIEW_FRAME_INVALID;
	int ViewFrameCount = VIEW_DEFAULT_FRAMECOUNT;

	float LastDeltaTime = 0.0;
	float StoredAnalogMovement = 0.0;
	float StoredAnalogZoom = 0.0;

	void Reset(int ActiveFrame)
	{
		if (ActiveFrame == -1)
		{
			ViewStartFrame = VIEW_FRAME_INVALID;
			ViewEndFrame = VIEW_FRAME_INVALID;
			ViewFrameCount = VIEW_DEFAULT_FRAMECOUNT;
		}
	}

	void ScrollSelectedFrame(int MoveFrames)
	{
		SelectedFrame = Math::Clamp(SelectedFrame + MoveFrames, FrameTimeline.StartFrame, FrameTimeline.EndFrame);
		bIsRangeSelected = false;

		if (ViewStartFrame != VIEW_FRAME_INVALID && ViewEndFrame != VIEW_FRAME_INVALID)
		{
			int RealCount = ViewEndFrame - ViewStartFrame;
			int ScrollBorder = Math::CeilToInt(float(RealCount) * 0.1);

			if (SelectedFrame > ViewEndFrame - ScrollBorder)
			{
				ViewEndFrame = Math::Min(SelectedFrame + ScrollBorder, Math::Max(FrameTimeline.EndFrame, ViewEndFrame));
				ViewStartFrame = ViewEndFrame - RealCount;
			}
			if (SelectedFrame < ViewStartFrame + ScrollBorder)
			{
				ViewStartFrame = Math::Max(SelectedFrame - ScrollBorder, Math::Min(FrameTimeline.StartFrame, ViewStartFrame));
				ViewEndFrame = ViewStartFrame + RealCount;
			}
		}

		OnFrameSelected.Broadcast(SelectedFrame);
	}

	void AnalogMovement(float Speed)
	{
		if (SelectedFrame == -1)
			return;

		int RealCount = ViewFrameCount;
		if (ViewStartFrame != VIEW_FRAME_INVALID && ViewEndFrame != VIEW_FRAME_INVALID)
			RealCount = ViewEndFrame - ViewStartFrame;

		float MovePerSecond = Math::Lerp(0.1, 0.5, Math::Abs(Speed)) * Math::Sign(Speed) * float(RealCount);
		StoredAnalogMovement += MovePerSecond * LastDeltaTime;

		int MoveFrames = 0;
		if (StoredAnalogMovement > 1.0)
		{
			MoveFrames = Math::FloorToInt(StoredAnalogMovement);
			StoredAnalogMovement -= float(MoveFrames);

			ScrollSelectedFrame(MoveFrames);
		}
		else if (StoredAnalogMovement < -1.0)
		{
			MoveFrames = Math::CeilToInt(StoredAnalogMovement);
			StoredAnalogMovement -= float(MoveFrames);

			ScrollSelectedFrame(MoveFrames);
		}
	}

	void AnalogZoom(float Zoom)
	{
		StoredAnalogZoom += Zoom * LastDeltaTime * 10.0;
		if (StoredAnalogZoom > 1.0)
		{
			float Ticks = Math::FloorToFloat(StoredAnalogZoom);
			StoredAnalogZoom -= float(Ticks);

			PerformZoom(Ticks, bAroundSelected = true);
		}
		else if (StoredAnalogZoom < -1.0)
		{
			float Ticks = Math::CeilToFloat(StoredAnalogZoom);
			StoredAnalogZoom -= float(Ticks);

			PerformZoom(Ticks, bAroundSelected = true);
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseMove(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		FVector2D ScreenPos = MouseEvent.GetScreenSpacePosition();
		FVector2D LocalPos = MyGeometry.AbsoluteToLocal(ScreenPos);

		HoveredFrame = GetFrameAtLocation(MyGeometry, LocalPos);

		if (bIsShifting)
		{
			if (ViewStartFrame != VIEW_FRAME_INVALID && ViewEndFrame != VIEW_FRAME_INVALID)
			{
				FVector2D PositionDelta = (MouseEvent.ScreenSpacePosition - MouseShiftStart);
				float FrameSize = GetSizePerFrame(MyGeometry);
				if (FrameSize != 0.0)
				{
					int FrameShift = Math::FloorToInt((PositionDelta.X / FrameSize) - MouseFrameShift);
					if (FrameShift != 0)
					{
						MouseFrameShift += FrameShift;

						ViewStartFrame -= FrameShift;
						ViewEndFrame -= FrameShift;

						ViewFrameCount = (ViewEndFrame - ViewStartFrame);

						ViewStartFrame = Math::Max(ViewStartFrame, FrameTimeline.StartFrame - int(ViewFrameCount * 0.9));
						ViewEndFrame = Math::Min(ViewStartFrame + ViewFrameCount, FrameTimeline.EndFrame + int(ViewFrameCount * 0.9));
						ViewStartFrame = Math::Max(ViewEndFrame - ViewFrameCount, FrameTimeline.StartFrame - int(ViewFrameCount * 0.9));

						ViewFrameCount = (ViewEndFrame - ViewStartFrame);
						OnTimelineShifted.Broadcast();
					}
				}
			}
		}

		if (bIsScrubbing)
		{
			if (HoveredFrame != -1 && HoveredFrame != SelectedFrame
				&& HoveredFrame >= FrameTimeline.StartFrame
				&& HoveredFrame <= FrameTimeline.EndFrame
				&& HoveredFrame >= DataStartFrame)
			{
				bIsRangeSelected = false;
				OnFrameSelected.Broadcast(HoveredFrame);
			}
		}
		else if (bIsSelectingRange && HoveredFrame != -1)
		{
			int ClampedHoveredFrame = Math::Clamp(HoveredFrame, DataStartFrame, FrameTimeline.EndFrame);
			ClampedHoveredFrame = Math::Clamp(ClampedHoveredFrame, ViewStartFrame, ViewEndFrame);
			RangeEndFrame = ClampedHoveredFrame;

			if (ClampedHoveredFrame != SelectedFrame)
				OnFrameSelected.Broadcast(ClampedHoveredFrame);
		}

		return FEventReply::Unhandled();
	}

	void ScrollFrameIntoView(int Frame)
	{
		if (ViewStartFrame != VIEW_FRAME_INVALID && ViewEndFrame != VIEW_FRAME_INVALID)
		{
			if (Frame >= ViewStartFrame && Frame <= ViewEndFrame)
				return;
		}

		int HalfFrameCount = Math::IntegerDivisionTrunc(ViewFrameCount, 2);
		ViewStartFrame = Math::Max(Frame - HalfFrameCount, FrameTimeline.StartFrame);
		ViewEndFrame = Math::Min(Frame + HalfFrameCount - 1, FrameTimeline.EndFrame);
		ViewFrameCount = (ViewEndFrame - ViewStartFrame);
		OnTimelineShifted.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton)
		{
			if (MouseEvent.IsControlDown() || MouseEvent.IsShiftDown())
			{
				if (HoveredFrame != -1 && HoveredFrame != SelectedFrame
					&& HoveredFrame >= FrameTimeline.StartFrame
					&& HoveredFrame <= FrameTimeline.EndFrame
					&& HoveredFrame >= DataStartFrame)
				{
					bIsSelectingRange = true;
					RangeStartFrame = HoveredFrame;
					RangeEndFrame = HoveredFrame;
				}
			}
			else
			{
				bIsScrubbing = true;
				bIsRangeSelected = false;
				RangeStartFrame = -1;
				RangeEndFrame = -1;

				if (HoveredFrame != -1 && HoveredFrame != SelectedFrame
					&& HoveredFrame >= FrameTimeline.StartFrame
					&& HoveredFrame <= FrameTimeline.EndFrame
					&& HoveredFrame >= DataStartFrame)
				{
					OnFrameSelected.Broadcast(HoveredFrame);
				}
			}
			return FEventReply::Handled()
				.PreventThrottling()
				.CaptureMouse(this);
		}
		else if (MouseEvent.EffectingButton == EKeys::RightMouseButton)
		{
			bIsShifting = true;
			MouseShiftStart = MouseEvent.ScreenSpacePosition;
			MouseFrameShift = 0;

			return FEventReply::Handled()
				.PreventThrottling()
				.CaptureMouse(this);
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton)
		{
			if (bIsSelectingRange && RangeStartFrame != -1 && RangeEndFrame != -1)
			{
				if (MouseEvent.IsControlDown())
				{
					ViewStartFrame = Math::Min(RangeStartFrame, RangeEndFrame);
					ViewEndFrame = Math::Max(RangeStartFrame, RangeEndFrame);
					ViewFrameCount = (ViewEndFrame - ViewStartFrame);
					OnTimelineShifted.Broadcast();

					RangeStartFrame = -1;
					RangeEndFrame = -1;
				}
				else
				{
					if (HoveredFrame != -1)
					{
						bIsRangeSelected = true;
					}
					else
					{
						RangeStartFrame = -1;
						RangeEndFrame = -1;
					}
				}
			}
			else
			{
				RangeStartFrame = -1;
				RangeEndFrame = -1;
			}

			bIsScrubbing = false;
			bIsSelectingRange = false;

			return FEventReply::Handled()
				.PreventThrottling()
				.ReleaseMouseCapture();
		}
		else if (MouseEvent.EffectingButton == EKeys::RightMouseButton)
		{
			bIsShifting = false;
			MouseShiftStart = FVector2D(-1.0, -1.0);
			MouseFrameShift = 0;

			return FEventReply::Handled()
				.PreventThrottling()
				.ReleaseMouseCapture();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseCaptureLost()
	{
		bIsScrubbing = false;
		bIsSelectingRange = false;
		if (!bIsRangeSelected)
		{
			RangeStartFrame = -1;
			RangeEndFrame = -1;
		}

		bIsShifting = false;
		MouseShiftStart = FVector2D(-1.0, -1.0);
		MouseFrameShift = 0;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseWheel(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		PerformZoom(MouseEvent.WheelDelta, bAroundSelected = false);
		return FEventReply::Handled();
	}

	int GetFirstVisibleFrame() property
	{
		if (ViewStartFrame != VIEW_FRAME_INVALID)
			return ViewStartFrame;
		return FrameTimeline.StartFrame;
	}

	int GetLastVisibleFrame() property
	{
		if (ViewEndFrame != VIEW_FRAME_INVALID)
			return ViewEndFrame;
		return FrameTimeline.EndFrame;
	}

	void PerformZoom(float Ticks, bool bAroundSelected)
	{
		if (ViewStartFrame == VIEW_FRAME_INVALID || ViewEndFrame == VIEW_FRAME_INVALID)
		{
			ViewStartFrame = FrameTimeline.StartFrame;
			ViewEndFrame = FrameTimeline.EndFrame;
		}

		if (ViewStartFrame == -1 || ViewEndFrame == -1)
			return;

		int AroundFrame = HoveredFrame;
		if (bAroundSelected)
			AroundFrame = SelectedFrame;
		if (AroundFrame == -1)
			AroundFrame = ViewStartFrame + Math::IntegerDivisionTrunc(ViewEndFrame - ViewStartFrame, 2);

		// The frame we're zooming around should stay at the same position
		int FrameCount = (ViewEndFrame - ViewStartFrame) + 1;
		float Pct = float(AroundFrame - ViewStartFrame) / float(FrameCount);

		int NewCount = Math::FloorToInt(FrameCount * Math::Pow(1.25, -Ticks));
		int FramesInTimeline = FrameTimeline.EndFrame - FrameTimeline.StartFrame;
		NewCount = Math::Clamp(NewCount, Math::Min(120, FrameCount), FramesInTimeline * 5);

		ViewStartFrame = AroundFrame - Math::FloorToInt(NewCount * Pct);
		ViewEndFrame = AroundFrame + Math::FloorToInt(NewCount * (1.0 - Pct)) - 1;

		ViewFrameCount = (ViewEndFrame - ViewStartFrame);
		OnTimelineShifted.Broadcast();
	}

	float GetSizePerFrame(FGeometry MyGeometry)
	{
		float BarWidth = MyGeometry.LocalSize.X - TimelinePadding*2;
		int StartFrame = FrameTimeline.StartFrame;
		int EndFrame = FrameTimeline.EndFrame;

		if (ViewStartFrame != VIEW_FRAME_INVALID && ViewEndFrame != VIEW_FRAME_INVALID)
		{
			StartFrame = ViewStartFrame;
			EndFrame = ViewEndFrame;
		}

		float FrameSize = BarWidth / float(EndFrame - StartFrame + 1);
		return FrameSize;
	}

	int GetFrameAtLocation(FGeometry MyGeometry, FVector2D LocalPos)
	{
		float BarWidth = MyGeometry.LocalSize.X - TimelinePadding*2;
		float BarHeight = MyGeometry.LocalSize.Y - TimelinePadding*2;

		if (LocalPos.X < TimelinePadding || LocalPos.X > MyGeometry.LocalSize.X - TimelinePadding)
			return -1;

		if (!bIsScrubbing && !bIsSelectingRange && !bIsShifting)
		{
			if (LocalPos.Y < TimelinePadding || LocalPos.Y > MyGeometry.LocalSize.Y - TimelinePadding)
				return -1;
		}

		int StartFrame = FrameTimeline.StartFrame;
		int EndFrame = FrameTimeline.EndFrame;

		if (ViewStartFrame != VIEW_FRAME_INVALID && ViewEndFrame != VIEW_FRAME_INVALID)
		{
			StartFrame = ViewStartFrame;
			EndFrame = ViewEndFrame;
		}

		float FrameSize = BarWidth / float(EndFrame - StartFrame + 1);
		return Math::Clamp(StartFrame + Math::FloorToInt(float(LocalPos.X - TimelinePadding) / FrameSize), StartFrame, EndFrame);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.IsMouseButtonDown(EKeys::LeftMouseButton))
		{
			if (MouseEvent.IsControlDown() || MouseEvent.IsShiftDown())
			{
				if (RangeStartFrame == -1)
					RangeStartFrame = HoveredFrame;
				if (RangeStartFrame != -1)
					bIsSelectingRange = true;
			}
			else
			{
				bIsScrubbing = true;
			}
		}
		else if (MouseEvent.IsMouseButtonDown(EKeys::RightMouseButton))
		{
			bIsShifting = true;
			if (MouseShiftStart == FVector2D(-1, -1))
			{
				MouseShiftStart = MouseEvent.ScreenSpacePosition;
				MouseFrameShift = 0;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
	}

	void ShiftToLatestFrame()
	{
		ViewEndFrame = FrameTimeline.EndFrame;
		ViewStartFrame = Math::Max(ViewEndFrame - ViewFrameCount, FrameTimeline.StartFrame);
	}

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		if (FrameTimeline.Sections.Num() == 0)
			return;

		// Draw the full background of the timeline
		Context.DrawBox(
			FVector2D(),
			Context.AllottedGeometry.LocalSize,
			BackgroundBrush);

		// Draw the full background of the entire timeline
		int StartFrame = FrameTimeline.StartFrame;
		int EndFrame = FrameTimeline.EndFrame;

		if (ViewStartFrame != VIEW_FRAME_INVALID && ViewEndFrame != VIEW_FRAME_INVALID)
		{
			StartFrame = ViewStartFrame;
			EndFrame = ViewEndFrame;
		}

		float BarWidth = Context.AllottedGeometry.LocalSize.X - TimelinePadding*2;
		float BarHeight = Context.AllottedGeometry.LocalSize.Y - TimelinePadding*2;

		float FrameSize = BarWidth / float(EndFrame - StartFrame + 1);
		for (auto Section : FrameTimeline.Sections)
		{
			if (Section.EndFrame < DataStartFrame)
				continue;
			if (Section.EndFrame < StartFrame)
				continue;
			if (Section.StartFrame > EndFrame)
				continue;

			int SectionStart = Math::Max(DataStartFrame, Section.StartFrame);

			float StartPos = Math::Clamp(FrameSize * (SectionStart - StartFrame), 0.0, BarWidth);
			float EndPos = Math::Clamp(FrameSize * (Section.EndFrame - StartFrame + 1), 0.0, BarWidth);

			FLinearColor Color;
			if (Section.Value.Tag == n"NoData")
				Color = FLinearColor(0.02, 0.0, 0.0, 1.0);
			else
				Color = FLinearColor(0.1, 0.1, 0.1, 1.0);

			Context.DrawBox(
				FVector2D(StartPos + TimelinePadding, TimelinePadding),
				FVector2D(EndPos - StartPos, BarHeight),
				Color);
		}

		// Draw milestone lines to show frame counts
		int MilestoneInterval = 60;
		int FrameCount = EndFrame - StartFrame;

		float MilestoneSize = 0.5;
		FLinearColor MilestoneColor(0.15, 0.15, 0.15);
		int MilestoneFrame;

		if (FrameCount < 3000)
		{
			MilestoneFrame = Math::IntegerDivisionTrunc(StartFrame, MilestoneInterval) * MilestoneInterval;
			for (; MilestoneFrame < EndFrame; MilestoneFrame += MilestoneInterval)
			{
				if (MilestoneFrame < DataStartFrame)
					continue;
				if (MilestoneFrame < StartFrame)
					continue;
				if (MilestoneFrame < FrameTimeline.StartFrame)
					continue;
				if (MilestoneFrame > FrameTimeline.EndFrame)
					continue;

				float Position = Math::Clamp(FrameSize * (MilestoneFrame - StartFrame), 0.0, BarWidth);
				Context.DrawBox(
					FVector2D(Position + TimelinePadding - MilestoneSize, TimelinePadding),
					FVector2D(MilestoneSize * 2.0, BarHeight),
					MilestoneColor);
			}
		}

		MilestoneInterval = 600;
		MilestoneSize = 2.0;
		MilestoneColor = FLinearColor(0.15, 0.1, 0.15);

		MilestoneFrame = Math::IntegerDivisionTrunc(StartFrame, MilestoneInterval) * MilestoneInterval;
		for (; MilestoneFrame < EndFrame; MilestoneFrame += MilestoneInterval)
		{
			if (MilestoneFrame < DataStartFrame)
				continue;
			if (MilestoneFrame < StartFrame)
				continue;
			if (MilestoneFrame < FrameTimeline.StartFrame)
				continue;
			if (MilestoneFrame > FrameTimeline.EndFrame)
				continue;

			float Position = Math::Clamp(FrameSize * (MilestoneFrame - StartFrame), 0.0, BarWidth);
			Context.DrawBox(
				FVector2D(Position + TimelinePadding - MilestoneSize, TimelinePadding),
				FVector2D(MilestoneSize * 2.0, BarHeight),
				MilestoneColor);
		}

		// Draw the glyphs for more data to the left or right
		if (StartFrame > FrameTimeline.StartFrame)
		{
			Context.DrawBox(
				FVector2D(2.0, 17.0),
				FVector2D(12.0, 12.0),
				LeftMoreDataBrush);
		}

		if (EndFrame < FrameTimeline.EndFrame)
		{
			Context.DrawBox(
				FVector2D(BarWidth - 15.0, 17.0),
				FVector2D(12.0, 12.0),
				RightMoreDataBrush);
		}

		// Draw the marker for the selected frame
		if (SelectedFrame >= StartFrame && SelectedFrame <= EndFrame)
		{
			float Pos = Math::Clamp(FrameSize * (SelectedFrame - StartFrame) + FrameSize*0.5, MarkerForegroundSize*0.5, BarWidth - MarkerForegroundSize*0.5);
			float FGSize = Math::Max(MarkerForegroundSize, FrameSize);
			Context.DrawBox(
				FVector2D(Pos - FGSize*0.5 + TimelinePadding, 0.0),
				FVector2D(FGSize, Context.AllottedGeometry.LocalSize.Y),
				SelectedForegroundBrush);

			float BGSize = Math::Max(MarkerBackgroundSize, FrameSize);
			Context.DrawBox(
				FVector2D(Pos - BGSize*0.5 + TimelinePadding, 0.0),
				FVector2D(BGSize, Context.AllottedGeometry.LocalSize.Y),
				SelectedBackgroundBrush);
		}

		// Draw the small status watch at the top
		for (const FHazeTemporalLogWatchSection& Section : StatusWatch.Sections)
		{
			if (Section.EndFrame < DataStartFrame)
				continue;
			if (Section.EndFrame < StartFrame)
				continue;
			if (Section.StartFrame > EndFrame)
				continue;

			int SectionStart = Math::Max(DataStartFrame, Section.StartFrame);

			FLinearColor Color;
			if (StatusWatch.WatchMode == ETemporalLogWatchMode::Colored)
			{
				Color = Section.Value.Color.ReinterpretAsLinear();
			}
			else if (StatusWatch.WatchMode == ETemporalLogWatchMode::ChangedFrames)
			{
				if (Section.Value.Tag == n"NoData")
					Color = FLinearColor(0.05, 0.04, 0.04);
				else if (Section.Value.Tag == n"Changed")
					Color = FLinearColor(0.5, 0.0, 0.2);
				else
					Color = FLinearColor(0.05, 0.05, 0.05);
			}
			else if (StatusWatch.WatchMode == ETemporalLogWatchMode::Boolean)
			{
				if (Section.Value.Tag == n"NoData")
					Color = FLinearColor(0.0, 0.0, 0.0);
				else if (Section.Value.Tag == n"True")
					Color = FLinearColor(0.0, 0.5, 0.0);
				else
					Color = FLinearColor(0.5, 0.0, 0.0);
			}

			float StartPos = Math::Clamp(FrameSize * (SectionStart - StartFrame), 0.0, BarWidth);
			float EndPos = Math::Clamp(FrameSize * (Section.EndFrame - StartFrame + 1), 0.0, BarWidth);

			Context.DrawBox(
				FVector2D(StartPos + TimelinePadding, 0),
				FVector2D(EndPos - StartPos, 4),
				Color);
		}

		// Draw each watch report that we are doing
		for (int i = 0, Count = Watches.Num(); i < Count; ++i)
		{
			int WatchY = 53 + 28*i;
			int WatchH = 12;

			// Draw the watch bar
			const FHazeTemporalLogWatchReport& WatchReport = Watches[i];
			for (const FHazeTemporalLogWatchSection& Section : WatchReport.Sections)
			{
				if (Section.EndFrame < DataStartFrame)
					continue;
				if (Section.EndFrame < StartFrame)
					continue;
				if (Section.StartFrame > EndFrame)
					continue;

				int SectionStart = Math::Max(DataStartFrame, Section.StartFrame);

				FLinearColor Color;
				if (WatchReport.WatchMode == ETemporalLogWatchMode::Colored)
				{
					Color = Section.Value.Color.ReinterpretAsLinear();
				}
				else if (WatchReport.WatchMode == ETemporalLogWatchMode::ChangedFrames)
				{
					if (Section.Value.Tag == n"NoData")
						Color = FLinearColor(0.05, 0.04, 0.04);
					else if (Section.Value.Tag == n"Changed")
						Color = FLinearColor(0.5, 0.0, 0.2);
					else
						Color = FLinearColor(0.05, 0.05, 0.05);
				}
				else if (WatchReport.WatchMode == ETemporalLogWatchMode::Boolean)
				{
					if (Section.Value.Tag == n"NoData")
						Color = FLinearColor(0.0, 0.0, 0.0);
					else if (Section.Value.Tag == n"True")
						Color = FLinearColor(0.0, 0.5, 0.0);
					else
						Color = FLinearColor(0.5, 0.0, 0.0);
				}

				float StartPos = Math::Clamp(FrameSize * (SectionStart - StartFrame), 0.0, BarWidth);
				float EndPos = Math::Clamp(FrameSize * (Section.EndFrame - StartFrame + 1), 0.0, BarWidth);

				Context.DrawBox(
					FVector2D(StartPos + TimelinePadding, WatchY),
					FVector2D(EndPos - StartPos, WatchH),
					Color);
			}

			// Draw the graph if we have any graphable data
			const FHazeTemporalLogGraphReport& GraphReport = Graphs[i];
			if (GraphReport.GraphSamples.Num() != 0)
			{
				float GraphMin = GraphReport.GraphMin;
				float GraphSpan = GraphReport.GraphMax - GraphReport.GraphMin;
				if (GraphSpan <= 0.0)
					GraphSpan = 1.0;

				TArray<FVector2D> Points;
				for (const FHazeTemporalLogGraphSample& Sample : GraphReport.GraphSamples)
				{
					if (Sample.Frame < DataStartFrame)
						continue;
					if (Sample.Frame < StartFrame)
						continue;
					if (Sample.Frame > EndFrame)
						continue;

					FVector2D Pos;
					Pos.X = Math::Clamp(FrameSize * (float(Sample.Frame - StartFrame) + 0.5), 0.0, BarWidth) + TimelinePadding;
					Pos.Y = WatchY + WatchH - 1 - 50.0 * Math::Clamp((Sample.Value - GraphMin) / GraphSpan, 0.0, 1.0);

					Points.Add(Pos);
				}

				FLinearColor Color = FLinearColor::MakeFromHSV8(uint8(GraphReport.ValuePath.Hash % 255), 255, 255);
				Context.DrawLines(Points, Color, 2.0, false);
			}
		}

		// Draw the marker for the hovered frame if any
		bool bHoveredValidFrame =  (HoveredFrame >= StartFrame && HoveredFrame <= EndFrame && HoveredFrame != -1
			&& HoveredFrame >= FrameTimeline.StartFrame && HoveredFrame <= FrameTimeline.EndFrame
			&& HoveredFrame >= DataStartFrame);

		// Draw the overlay for when we are selecting a range to zoom to
		if (RangeStartFrame != -1 && RangeEndFrame != -1 && (bIsSelectingRange || bIsRangeSelected))
		{
			int SelectionStart = Math::Min(RangeStartFrame, RangeEndFrame);
			int SelectionEnd = Math::Max(RangeStartFrame, RangeEndFrame);

			float StartPos = Math::Clamp(FrameSize * (SelectionStart - StartFrame), 0.0, BarWidth);
			float EndPos = Math::Clamp(FrameSize * (SelectionEnd - StartFrame + 1), 0.0, BarWidth);

			Context.DrawBox(
				FVector2D(StartPos + TimelinePadding, TimelinePadding),
				FVector2D(EndPos - StartPos, BarHeight),
				FLinearColor(0.0, 1.0, 1.0, 0.25));

			if (TemporalLog != nullptr)
			{
				FHazeTemporalLogFrameData StartFrameData;
				TemporalLog.ReportGlobalFrameData(SelectionStart, StartFrameData);

				FHazeTemporalLogFrameData EndFrameData;
				TemporalLog.ReportGlobalFrameData(SelectionEnd, EndFrameData);

				float SelectedDuration = EndFrameData.GameTime + EndFrameData.DeltaTime - StartFrameData.GameTime;
				FString DurationText = f"{SelectedDuration : .3} s";
				FString FramesText = f"{SelectionEnd - SelectionStart} Frames";

				Context.DrawText(
					DurationText,
					FVector2D(StartPos + TimelinePadding + 1.0, TimelinePadding + 4.0),
					FLinearColor::Black
				);

				Context.DrawText(
					DurationText,
					FVector2D(StartPos + TimelinePadding - 1.0, TimelinePadding + 2.0),
					FLinearColor::Black
				);

				Context.DrawText(
					DurationText,
					FVector2D(StartPos + TimelinePadding, TimelinePadding + 3.0),
					FLinearColor::White
				);

				Context.DrawText(
					FramesText,
					FVector2D(StartPos + TimelinePadding + 5.0, TimelinePadding + 4.0 + 17.0),
					FLinearColor::Black
				);

				Context.DrawText(
					FramesText,
					FVector2D(StartPos + TimelinePadding + 3.0, TimelinePadding + 2.0 + 17.0),
					FLinearColor::Black
				);

				Context.DrawText(
					FramesText,
					FVector2D(StartPos + TimelinePadding + 4.0, TimelinePadding + 3.0 + 17.0),
					FLinearColor::White
				);
			}
		}

		if (bHoveredValidFrame && !bIsSelectingRange)
		{
			float Pos = Math::Clamp(FrameSize * (HoveredFrame - StartFrame) + FrameSize*0.5, MarkerForegroundSize*0.5, BarWidth - MarkerForegroundSize*0.5);
			float FGSize = Math::Max(MarkerForegroundSize, FrameSize);
			Context.DrawBox(
				FVector2D(Pos - FGSize*0.5 + TimelinePadding, 0.0),
				FVector2D(FGSize, Context.AllottedGeometry.LocalSize.Y),
				HoveredForegroundBrush);

			float BGSize = Math::Max(MarkerBackgroundSize, FrameSize);
			Context.DrawBox(
				FVector2D(Pos - BGSize*0.5 + TimelinePadding, 0.0),
				FVector2D(BGSize, Context.AllottedGeometry.LocalSize.Y),
				HoveredBackgroundBrush);
		}
	}
};