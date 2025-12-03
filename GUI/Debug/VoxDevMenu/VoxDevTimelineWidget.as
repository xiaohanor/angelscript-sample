
event void FOnFrameSelectedB(int Frame);
event void FOnTimelineShiftedB();

const int VIEW_FRAME_INVALID = MIN_int32;
const int VIEW_DEFAULT_FRAMECOUNT = 800;

const FLinearColor PaleYellow = FLinearColor(1.0, 1.0, 0.65);

enum EVoxDevTimelineSectionMode
{
	Colored
}

struct FVoxTimelineSectionTime
{
	int DebugTriggerId;
	int VoiceLineIndex;

	float VoiceLineStartTime = MAX_flt;
	float VoiceLineEndTime = 0.0;
}

struct FVoxDevTimelineLaneDivider
{
	int OffsetY;
	FString DisplayText;
}

struct FVoxDevTimelineBox
{
	float Left;
	float Right;
	float Top;
	float Bottom;

	FVoxDevTimelineValue Value;
}

class UVoxDevTimelineWidget : UHazeUserWidget
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

	int TimelineStartFrame = -1;
	int TimelineEndFrame = -1;

	private bool bViewportMode = false;

	TArray<FVoxDevTimelineLane> Lanes;

	FOnFrameSelectedB OnFrameSelected;
	FOnTimelineShiftedB OnTimelineShifted;

	bool bIsScrubbing = false;

	bool bIsSelectingRange = false;
	int RangeStartFrame = -1;
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

	private float LastDeltaTime = 0.0;
	float StoredAnalogMovement = 0.0;
	float StoredAnalogZoom = 0.0;

	bool bMouseOver = false;
	FVector2D MousePosition;

	TArray<FVoxDevTimelineBox> TimelineBoxes;
	TArray<FVoxDevTimelineBox> TimelineOutlines;

	int HoveredId = -1;
	int HoveredVoiceLineIndex = -1;

	FString CustomToolTipText;

	int NumSlots = 0;

	private int SlotHeightOffset = 28;
	private int SlotHeight = 12;

	TArray<FVoxDevTimelineLaneDivider> LaneDividers;

	void EnableViewportMode()
	{
		bViewportMode = true;

		// Update slot sizes
		SlotHeightOffset = 28;
		SlotHeight = 12;
		TimelinePadding = 0;
	}

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
		SelectedFrame = Math::Clamp(SelectedFrame + MoveFrames, TimelineStartFrame, TimelineEndFrame);

		if (ViewStartFrame != VIEW_FRAME_INVALID && ViewEndFrame != VIEW_FRAME_INVALID)
		{
			int RealCount = ViewEndFrame - ViewStartFrame;
			int ScrollBorder = Math::CeilToInt(float(RealCount) * 0.1);

			if (SelectedFrame > ViewEndFrame - ScrollBorder)
			{
				ViewEndFrame = Math::Min(SelectedFrame + ScrollBorder, Math::Max(TimelineEndFrame, ViewEndFrame));
				ViewStartFrame = ViewEndFrame - RealCount;
			}
			if (SelectedFrame < ViewStartFrame + ScrollBorder)
			{
				ViewStartFrame = Math::Max(SelectedFrame - ScrollBorder, Math::Min(TimelineStartFrame, ViewStartFrame));
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

		MousePosition = LocalPos;

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

						ViewStartFrame = Math::Max(ViewStartFrame, TimelineStartFrame - int(ViewFrameCount * 0.9));
						ViewEndFrame = Math::Min(ViewStartFrame + ViewFrameCount, TimelineEndFrame + int(ViewFrameCount * 0.9));
						ViewStartFrame = Math::Max(ViewEndFrame - ViewFrameCount, TimelineStartFrame - int(ViewFrameCount * 0.9));

						ViewFrameCount = (ViewEndFrame - ViewStartFrame);
						OnTimelineShifted.Broadcast();
					}
				}
			}
		}

		if (bIsScrubbing)
		{
			if (HoveredFrame != -1 && HoveredFrame != SelectedFrame
				&& HoveredFrame >= TimelineStartFrame
				&& HoveredFrame <= TimelineEndFrame
				&& HoveredFrame >= DataStartFrame)
			{
				OnFrameSelected.Broadcast(HoveredFrame);
			}
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
		ViewStartFrame = Math::Max(Frame - HalfFrameCount, TimelineStartFrame);
		ViewEndFrame = Math::Min(Frame + HalfFrameCount - 1, TimelineEndFrame);
		ViewFrameCount = (ViewEndFrame - ViewStartFrame);
		OnTimelineShifted.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton)
		{
			if (MouseEvent.IsControlDown())
			{
				if (HoveredFrame != -1 && HoveredFrame != SelectedFrame
					&& HoveredFrame >= TimelineStartFrame
					&& HoveredFrame <= TimelineEndFrame
					&& HoveredFrame >= DataStartFrame)
				{
					bIsSelectingRange = true;
					RangeStartFrame = HoveredFrame;
				}
			}
			else
			{
				bIsScrubbing = true;
				if (HoveredFrame != -1 && HoveredFrame != SelectedFrame
					&& HoveredFrame >= TimelineStartFrame
					&& HoveredFrame <= TimelineEndFrame
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
			if (bIsSelectingRange && RangeStartFrame != -1 && HoveredFrame != VIEW_FRAME_INVALID)
			{
				ViewStartFrame = Math::Min(RangeStartFrame, HoveredFrame);
				ViewEndFrame = Math::Max(RangeStartFrame, HoveredFrame);
				ViewFrameCount = (ViewEndFrame - ViewStartFrame);
				OnTimelineShifted.Broadcast();
			}

			bIsScrubbing = false;
			bIsSelectingRange = false;
			RangeStartFrame = -1;

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
		RangeStartFrame = -1;

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
		return TimelineStartFrame;
	}

	int GetLastVisibleFrame() property
	{
		if (ViewEndFrame != VIEW_FRAME_INVALID)
			return ViewEndFrame;
		return TimelineEndFrame;
	}

	void PerformZoom(float Ticks, bool bAroundSelected)
	{
		if (ViewStartFrame == VIEW_FRAME_INVALID || ViewEndFrame == VIEW_FRAME_INVALID)
		{
			ViewStartFrame = TimelineStartFrame;
			ViewEndFrame = TimelineEndFrame;
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
		int FramesInTimeline = TimelineEndFrame - TimelineStartFrame;
		NewCount = Math::Clamp(NewCount, Math::Min(120, FrameCount), FramesInTimeline * 5);

		ViewStartFrame = AroundFrame - Math::FloorToInt(NewCount * Pct);
		ViewEndFrame = AroundFrame + Math::FloorToInt(NewCount * (1.0 - Pct)) - 1;

		ViewFrameCount = (ViewEndFrame - ViewStartFrame);
		OnTimelineShifted.Broadcast();
	}

	float GetSizePerFrame(FGeometry MyGeometry) const
	{
		float BarWidth = MyGeometry.LocalSize.X - TimelinePadding * 2;
		int StartFrame = TimelineStartFrame;
		int EndFrame = TimelineEndFrame;

		if (ViewStartFrame != VIEW_FRAME_INVALID && ViewEndFrame != VIEW_FRAME_INVALID)
		{
			StartFrame = ViewStartFrame;
			EndFrame = ViewEndFrame;
		}

		float FrameSize = BarWidth / float(EndFrame - StartFrame + 1);
		return FrameSize;
	}

	int GetFrameAtLocation(FGeometry MyGeometry, FVector2D LocalPos) const
	{
		float BarWidth = MyGeometry.LocalSize.X - TimelinePadding * 2;
		float BarHeight = MyGeometry.LocalSize.Y - TimelinePadding * 2;

		if (LocalPos.X < TimelinePadding || LocalPos.X > MyGeometry.LocalSize.X - TimelinePadding)
			return -1;

		if (!bIsScrubbing && !bIsSelectingRange && !bIsShifting)
		{
			if (LocalPos.Y < TimelinePadding || LocalPos.Y > MyGeometry.LocalSize.Y - TimelinePadding)
				return -1;
		}

		int StartFrame = TimelineStartFrame;
		int EndFrame = TimelineEndFrame;

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
		bMouseOver = true;
		if (MouseEvent.IsMouseButtonDown(EKeys::LeftMouseButton))
		{
			if (MouseEvent.IsControlDown())
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
		bMouseOver = false;
	}

	void ShiftToLatestFrame()
	{
		ViewEndFrame = TimelineEndFrame;
		ViewStartFrame = Math::Max(ViewEndFrame - ViewFrameCount, TimelineStartFrame);
	}

	FString BuildTooltipTimeText(int TriggerId, int VoiceLineIndex, const TArray<FVoxTimelineSectionTime>& SectionTimes) const
	{
		// Find Start and End times
		float VLStart = 0;
		float VLEnd = 0;
		float AssetStart = MAX_flt;
		float AssetEnd = 0.0;
		for (const FVoxTimelineSectionTime& SectionTime : SectionTimes)
		{
			if (SectionTime.DebugTriggerId == TriggerId)
			{
				AssetStart = Math::Min(AssetStart, SectionTime.VoiceLineStartTime);
				AssetEnd = Math::Max(AssetEnd, SectionTime.VoiceLineEndTime);

				if (SectionTime.VoiceLineIndex == VoiceLineIndex)
				{
					VLStart = SectionTime.VoiceLineStartTime;
					VLEnd = SectionTime.VoiceLineEndTime;
				}
			}
		}

		float VLDuration = VLEnd - VLStart;
		float AssetDuration = AssetEnd - AssetStart;
		return f"\nVL: {VLStart:.3} - {VLEnd:.3} ({VLDuration:.3})  Asset: {AssetStart:.3} - {AssetEnd:.3} ({AssetDuration:.3})";
	}

	// Used instead of tick since we can't tick widgets in global dev menus
	void UpdateTimeline(float InDeltaTime)
	{
		LastDeltaTime = InDeltaTime;

		// Reset values
		TimelineBoxes.Reset();
		TimelineOutlines.Reset();
		LaneDividers.Reset();

		HoveredId = -1;
		HoveredVoiceLineIndex = -1;

		// No frames
		if (TimelineEndFrame < TimelineStartFrame)
			return;

		// TODO: These are also calculated in OnPain
		int StartFrame = TimelineStartFrame;
		int EndFrame = TimelineEndFrame;
		if (ViewStartFrame != VIEW_FRAME_INVALID && ViewEndFrame != VIEW_FRAME_INVALID)
		{
			StartFrame = ViewStartFrame;
			EndFrame = ViewEndFrame;
		}
		float BarWidth = CachedGeometry.LocalSize.X - TimelinePadding * 2;
		float FrameSize = BarWidth / float(EndFrame - StartFrame + 1);

		int OffsetY = 0;
		FString ToolTipValuePart;
		TArray<FVoxTimelineSectionTime> SectionTimes;
		for (const FVoxDevTimelineLane& Lane : Lanes)
		{
			FVoxDevTimelineLaneDivider LaneDivider;
			LaneDivider.OffsetY = OffsetY;
			LaneDivider.DisplayText = Lane.Name;
			LaneDividers.Add(LaneDivider);

			OffsetY++;

			// Build boxes
			for (int SlotIndex = 0; SlotIndex < Lane.Slots.Num(); ++SlotIndex)
			{
				const FVoxDevTimelineLaneSlot& LaneSlot = Lane.Slots[SlotIndex];

				int SectionY = SlotHeightOffset * OffsetY;
				int SectionH = SlotHeight;

				bool bSlotHasBoxes = false;

				for (const FVoxDevTimelineSection& Section : LaneSlot.Sections)
				{
					if (Section.EndFrame < DataStartFrame)
						continue;
					if (Section.EndFrame < StartFrame)
						continue;
					if (Section.StartFrame > EndFrame)
						continue;

					int SectionStart = Math::Max(DataStartFrame, Section.StartFrame);

					const FVoxDevTimelineValue& Value = Section.Value;

					FLinearColor Color;
					if (Section.SectionMode == EVoxDevTimelineSectionMode::Colored)
					{
						Color = Value.Color;
					}

					float StartPos = Math::Clamp(FrameSize * (SectionStart - StartFrame), 0.0, BarWidth);
					float EndPos = Math::Clamp(FrameSize * (Section.EndFrame - StartFrame + 1), 0.0, BarWidth);

					float Left = StartPos + TimelinePadding;
					float Right = EndPos + TimelinePadding;
					float Top = SectionY;
					float Bottom = SectionY + SectionH;

					if (bMouseOver)
					{
						if (MousePosition.X >= Left && MousePosition.X <= Right && MousePosition.Y >= Top && MousePosition.Y <= Bottom)
						{
							HoveredId = Value.DebugTriggerId;
							HoveredVoiceLineIndex = Value.VoiceLineIndex;
							ToolTipValuePart = Section.Value.TooltipText;
						}
					}

					// Update section times for all sections
					bool bFoundSectionTime = false;
					for (FVoxTimelineSectionTime& SectionTime : SectionTimes)
					{
						if (SectionTime.DebugTriggerId == Value.DebugTriggerId
							&& SectionTime.VoiceLineIndex == Value.VoiceLineIndex)
						{
							SectionTime.VoiceLineStartTime = Math::Min(SectionTime.VoiceLineStartTime, Section.StartTime);
							SectionTime.VoiceLineEndTime = Math::Max(SectionTime.VoiceLineEndTime, Section.EndTime);
							bFoundSectionTime = true;
							break;
						}
					}

					// Add new section time if needed
					if (!bFoundSectionTime)
					{
						SectionTimes.Add(FVoxTimelineSectionTime());
						FVoxTimelineSectionTime& NewTime = SectionTimes.Last();
						NewTime.DebugTriggerId = Value.DebugTriggerId;
						NewTime.VoiceLineIndex = Value.VoiceLineIndex;
						NewTime.VoiceLineStartTime = Section.StartTime;
						NewTime.VoiceLineEndTime = Section.EndTime;
					}

					FVoxDevTimelineBox NewBox;
					NewBox.Left = Left;
					NewBox.Right = Right;
					NewBox.Top = Top;
					NewBox.Bottom = Bottom;
					NewBox.Value = Value;

					TimelineBoxes.Add(NewBox);
					bSlotHasBoxes = true;
				}

				// Draw outline box for voicelines triggered together
				int GroupStartFrame = MAX_int32;
				int GroupEndFrame = -1;
				for (int i = 0; i < LaneSlot.Sections.Num(); ++i)
				{
					const FVoxDevTimelineSection& Section = LaneSlot.Sections[i];
					GroupStartFrame = Math::Min(GroupStartFrame, Section.StartFrame);
					GroupEndFrame = Math::Max(GroupEndFrame, Section.EndFrame);

					// Draw box if this is the last section or if next section has different trigger id
					if (i == LaneSlot.Sections.Num() - 1
						|| Section.Value.DebugTriggerId != LaneSlot.Sections[i + 1].Value.DebugTriggerId)
					{
						int SectionStart = Math::Max(DataStartFrame, GroupStartFrame);
						float StartPos = Math::Clamp(FrameSize * (SectionStart - StartFrame), 0.0, BarWidth);
						float EndPos = Math::Clamp(FrameSize * (GroupEndFrame - StartFrame + 1), 0.0, BarWidth);

						float Left = StartPos + TimelinePadding;
						float Right = EndPos + TimelinePadding;
						float Top = SectionY - 1;
						float Bottom = SectionY + SectionH + 2;

						TArray<FVector2D> Corners;
						Corners.Add(FVector2D(Left, Top));
						Corners.Add(FVector2D(Right, Top));
						Corners.Add(FVector2D(Right, Bottom));
						Corners.Add(FVector2D(Left, Bottom));
						Corners.Add(FVector2D(Left, Top));

						FVoxDevTimelineBox NewBox;
						NewBox.Left = Left;
						NewBox.Right = Right;
						NewBox.Top = Top;
						NewBox.Bottom = Bottom;
						NewBox.Value = Section.Value;

						TimelineOutlines.Add(NewBox);

						GroupStartFrame = MAX_int32;
						GroupEndFrame = -1;
					}
				}

				if (bViewportMode)
				{
					// Always add min one empty slot per lane
					if (bSlotHasBoxes || SlotIndex == 0)
					{
						OffsetY++;
					}
				}
				else
				{
					OffsetY++;
				}
			}
		}

		NumSlots = OffsetY;

		// Update tooltip text
		if (HoveredId != -1 && HoveredVoiceLineIndex >= 0)
		{
			CustomToolTipText = ToolTipValuePart + BuildTooltipTimeText(HoveredId, HoveredVoiceLineIndex, SectionTimes);
		}
		else
		{
			CustomToolTipText.Reset();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		if (Lanes.Num() == 0)
		{
			if (bViewportMode)
				Context.DrawText("Vox Timeline: No events! Turn on 'Track Playing Events' in the Haze Vox Dev Menu", FVector2D(10, 10), FLinearColor::Red);

			return;
		}

		// Draw the full background of the timeline
		Context.DrawBox(
			FVector2D(),
			Context.AllottedGeometry.LocalSize,
			BackgroundBrush);

		// Draw the full background of the entire timeline
		int StartFrame = TimelineStartFrame;
		int EndFrame = TimelineEndFrame;

		if (ViewStartFrame != VIEW_FRAME_INVALID && ViewEndFrame != VIEW_FRAME_INVALID)
		{
			StartFrame = ViewStartFrame;
			EndFrame = ViewEndFrame;
		}

		float BarWidth = Context.AllottedGeometry.LocalSize.X - TimelinePadding * 2;
		float BarHeight = NumSlots * SlotHeightOffset;

		float FrameSize = BarWidth / float(EndFrame - StartFrame + 1);

		if (TimelineEndFrame < DataStartFrame && TimelineEndFrame >= StartFrame && TimelineStartFrame <= EndFrame)
		{

			int SectionStart = Math::Max(DataStartFrame, TimelineStartFrame);

			float StartPos = Math::Clamp(FrameSize * (SectionStart - StartFrame), 0.0, BarWidth);
			float EndPos = Math::Clamp(FrameSize * (TimelineEndFrame - StartFrame + 1), 0.0, BarWidth);

			FLinearColor Color = FLinearColor(0.1, 0.1, 0.1, 1.0);
			if (bViewportMode)
				Color.A = 0.4;

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
				if (MilestoneFrame < TimelineStartFrame)
					continue;
				if (MilestoneFrame > TimelineEndFrame)
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
			if (MilestoneFrame < TimelineStartFrame)
				continue;
			if (MilestoneFrame > TimelineEndFrame)
				continue;

			float Position = Math::Clamp(FrameSize * (MilestoneFrame - StartFrame), 0.0, BarWidth);
			Context.DrawBox(
				FVector2D(Position + TimelinePadding - MilestoneSize, TimelinePadding),
				FVector2D(MilestoneSize * 2.0, BarHeight),
				MilestoneColor);
		}

		// Draw the glyphs for more data to the left or right
		if (StartFrame > TimelineStartFrame && !bViewportMode)
		{
			Context.DrawBox(
				FVector2D(2.0, 17.0),
				FVector2D(12.0, 12.0),
				LeftMoreDataBrush);
		}

		if (EndFrame < TimelineEndFrame && !bViewportMode)
		{
			Context.DrawBox(
				FVector2D(BarWidth - 15.0, 17.0),
				FVector2D(12.0, 12.0),
				RightMoreDataBrush);
		}

		// Draw the marker for the selected frame
		if (SelectedFrame >= StartFrame && SelectedFrame <= EndFrame && !bViewportMode)
		{
			float Pos = Math::Clamp(FrameSize * (SelectedFrame - StartFrame) + FrameSize * 0.5, MarkerForegroundSize * 0.5, BarWidth - MarkerForegroundSize * 0.5);
			float FGSize = Math::Max(MarkerForegroundSize, FrameSize);
			Context.DrawBox(
				FVector2D(Pos - FGSize * 0.5 + TimelinePadding, 0.0),
				FVector2D(FGSize, Context.AllottedGeometry.LocalSize.Y),
				SelectedForegroundBrush);

			float BGSize = Math::Max(MarkerBackgroundSize, FrameSize);
			Context.DrawBox(
				FVector2D(Pos - BGSize * 0.5 + TimelinePadding, 0.0),
				FVector2D(BGSize, Context.AllottedGeometry.LocalSize.Y),
				SelectedBackgroundBrush);
		}

		// Draw lane outlines
		for (const FVoxDevTimelineLaneDivider& LaneDivider : LaneDividers)
		{
			// Lane outline
			FVector2D LaneBorderA(0, SlotHeightOffset * LaneDivider.OffsetY);
			FVector2D LaneBorderB(Context.AllottedGeometry.LocalSize.X, SlotHeightOffset * LaneDivider.OffsetY);
			Context.DrawLine(LaneBorderA, LaneBorderB, FLinearColor::Yellow, 1.0, false);

			FVector2D LaneTextPosition(0, SlotHeightOffset * LaneDivider.OffsetY);
			Context.DrawText(LaneDivider.DisplayText, LaneTextPosition, FLinearColor::Yellow);
		}

		// Draw pre-caluclated boxes and outlines
		for (const FVoxDevTimelineBox& Box : TimelineBoxes)
		{
			FVector2D BoxStart(Box.Left, Box.Top);
			FVector2D BoxSize(Box.Right - Box.Left, Box.Bottom - Box.Top);

			FLinearColor BoxColor = Box.Value.Color;
			if (Box.Value.DebugTriggerId == HoveredId)
			{
				BoxColor = Box.Value.VoiceLineIndex == HoveredVoiceLineIndex ? FLinearColor::Yellow : PaleYellow;
			}

			Context.DrawBox(BoxStart, BoxSize, BoxColor);

			Context.DrawText(Box.Value.DisplayText, FVector2D(Box.Left, Box.Top - 1), FLinearColor::Black);
		}

		for (const FVoxDevTimelineBox& Box : TimelineOutlines)
		{
			TArray<FVector2D> Corners;
			Corners.Add(FVector2D(Box.Left, Box.Top));
			Corners.Add(FVector2D(Box.Right, Box.Top));
			Corners.Add(FVector2D(Box.Right, Box.Bottom));
			Corners.Add(FVector2D(Box.Left, Box.Bottom));
			Corners.Add(FVector2D(Box.Left, Box.Top));

			bool bHightlightOutline = Box.Value.DebugTriggerId == HoveredId;
			FLinearColor OutlineColor = bHightlightOutline ? FLinearColor::Yellow : FLinearColor::Black;

			Context.DrawLines(
				Corners,
				OutlineColor,
				1.0,
				false);
		}

		// Draw the marker for the hovered frame if any
		if (HoveredFrame >= StartFrame && HoveredFrame <= EndFrame && HoveredFrame != -1
			&& HoveredFrame >= TimelineStartFrame && HoveredFrame <= TimelineEndFrame
			&& HoveredFrame >= DataStartFrame)
		{
			// Draw the overlay for when we are selecting a range to zoom to
			if (RangeStartFrame != -1 && bIsSelectingRange)
			{
				int SelectionStart = Math::Min(RangeStartFrame, HoveredFrame);
				int SelectionEnd = Math::Max(RangeStartFrame, HoveredFrame);

				float StartPos = Math::Clamp(FrameSize * (SelectionStart - StartFrame), 0.0, BarWidth);
				float EndPos = Math::Clamp(FrameSize * (SelectionEnd - StartFrame + 1), 0.0, BarWidth);

				Context.DrawBox(
					FVector2D(StartPos + TimelinePadding, TimelinePadding),
					FVector2D(EndPos - StartPos, BarHeight),
					FLinearColor(0.0, 1.0, 1.0, 0.25));
			}
			else
			{
				float Pos = Math::Clamp(FrameSize * (HoveredFrame - StartFrame) + FrameSize * 0.5, MarkerForegroundSize * 0.5, BarWidth - MarkerForegroundSize * 0.5);
				float FGSize = Math::Max(MarkerForegroundSize, FrameSize);
				Context.DrawBox(
					FVector2D(Pos - FGSize * 0.5 + TimelinePadding, 0.0),
					FVector2D(FGSize, Context.AllottedGeometry.LocalSize.Y),
					HoveredForegroundBrush);

				float BGSize = Math::Max(MarkerBackgroundSize, FrameSize);
				Context.DrawBox(
					FVector2D(Pos - BGSize * 0.5 + TimelinePadding, 0.0),
					FVector2D(BGSize, Context.AllottedGeometry.LocalSize.Y),
					HoveredBackgroundBrush);
			}
		}

		// Draw tooltop if we are hovering on something
		if (CustomToolTipText.Len() > 0 && !bViewportMode)
		{
			FVector2D BoxSize(700, 70);

			// Offset if tooltip would go outside left edge
			float TooptipX = Math::Clamp(MousePosition.X + 20, 0, Context.AllottedGeometry.LocalSize.X - BoxSize.X);

			// Put tooltip above mouse if it would go outside bottom
			float TooltipOffsetY = 20;
			if (MousePosition.Y + TooltipOffsetY + BoxSize.Y > Context.AllottedGeometry.LocalSize.Y)
				TooltipOffsetY = (BoxSize.Y + TooltipOffsetY) * -1;

			float TooltipY = MousePosition.Y + TooltipOffsetY;

			FVector2D TooltipPosition(TooptipX, TooltipY);
			Context.DrawBox(TooltipPosition, BoxSize, FLinearColor::White);

			TArray<FVector2D> Corners;
			Corners.Add(FVector2D(TooltipPosition.X, TooltipPosition.Y));
			Corners.Add(FVector2D(TooltipPosition.X + BoxSize.X, TooltipPosition.Y));
			Corners.Add(FVector2D(TooltipPosition.X + BoxSize.X, TooltipPosition.Y + BoxSize.Y));
			Corners.Add(FVector2D(TooltipPosition.X, TooltipPosition.Y + BoxSize.Y));
			Corners.Add(FVector2D(TooltipPosition.X, TooltipPosition.Y));

			Context.DrawLines(
				Corners,
				FLinearColor::Black,
				1.0,
				false);

			FVector2D TooltipTextPosition(TooltipPosition.X + 5, TooltipPosition.Y + 5);
			Context.DrawText(CustomToolTipText, TooltipTextPosition, FLinearColor::Black);
		}
	}
};
