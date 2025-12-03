
class UVoxViewportOverlayWidget : UHazeUserWidget
{
	UPROPERTY(Meta = (BindWidget))
	UVoxDevTimelineWidget VoxTimeline;

	void InitTimeline()
	{
#if TEST
		VoxTimeline.EnableViewportMode();

		VoxTimeline.Reset(-1);

		auto VoxRunner = UHazeVoxRunner::Get();
		VoxTimeline.TimelineStartFrame = int(VoxRunner.DebugStartFrame);
		VoxTimeline.DataStartFrame = int(VoxRunner.DebugStartFrame);
		VoxTimeline.TimelineEndFrame = -1;

		VoxTimeline.Lanes.Reset();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnInitialized()
	{
#if TEST
		InitTimeline();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
#if TEST
		const int CurrentFrame = int(GFrameNumber);
		VoxTimeline.TimelineEndFrame = CurrentFrame;

		// Force locked to latest frame behaviour
		VoxTimeline.SelectedFrame = CurrentFrame;
		VoxTimeline.ShiftToLatestFrame();

		auto VoxRunner = UHazeVoxRunner::Get();
		VoxTimeline.Lanes = VoxRunner.DebugTimelineLanes;

		VoxTimeline.UpdateTimeline(InDeltaTime);
#endif
	}
}
