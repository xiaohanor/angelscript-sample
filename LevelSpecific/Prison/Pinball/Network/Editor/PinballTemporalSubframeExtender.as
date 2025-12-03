#if EDITOR
/** 
 * Makes if possible to view pinball subframe transforms
 */
class UPinballTemporalSubframeExtender : UTemporalLogUIExtender
{
	FString GetUIName(FHazeTemporalLogReport Report) const override
	{
		return "Pinball Prediction Subframe Extender";
	}

	bool ShouldShow(FHazeTemporalLogReport Report) const override
	{
		return Cast<APinballMagnetDroneProxy>(Report.AssociatedObject) != nullptr;
	}

	void DrawUI(UHazeImmediateDrawer Drawer, FHazeTemporalLogReport Report) const override
	{
		const auto Proxy = Cast<APinballMagnetDroneProxy>(Report.AssociatedObject);
		if (Proxy == nullptr)
			return;

		const uint LogFrame = uint(Report.ReportedFrame);

		auto Section = Drawer.Begin("Subframe Logging");

		if(!Pinball::Prediction::bPredictionLogsSubframes)
		{
			Section.Text("Subframe logging is disabled. See PinballNetworkSettings.as");
			return;
		}

		if(!TemporalLog.bPauseLogPruning)
		{
			Section.Text("Scrub to display subframes.");
			return;
		}

		UPinballTemporalSubframeSubsystem::Get().bShowSubframes = Section.CheckBox()
			.Checked(UPinballTemporalSubframeSubsystem::Get().bShowSubframes)
			.Label("Show Subframes")
		;

		if(!UPinballTemporalSubframeSubsystem::Get().bShowSubframes)
			return;

		FPinballTemporalLogFrameData FrameData = Proxy.TemporalLogComp.GetFrameData(LogFrame);

		float& SelectedSubframe = UPinballTemporalSubframeSubsystem::Get().SelectedSubframe;

		SelectedSubframe = FrameData.PredictionTimeRange.Clamp(SelectedSubframe);

		SelectedSubframe = Section.FloatInput()
			.Label(f"Scrub to Subframes")
			.MinMax(FrameData.PredictionTimeRange.Min, FrameData.PredictionTimeRange.Max)
			.Value(SelectedSubframe)
		;

		ScrubToTime(uint(LogFrame), SelectedSubframe);

		Section.Text(f"Start: {FrameData.PredictionTimeRange.Min}");

		for(int i = 0; i < FrameData.SubframeTimes.Num(); i++)
		{
			Section.Text(f"Subframe {i + 1}: {FrameData.SubframeTimes[i]}");
		}

		Section.Text(f"End: {FrameData.PredictionTimeRange.Max}");
	}

	private void ScrubToTime(uint Frame, float PredictionTime) const
	{
		for(auto Scrubbable : TemporalLog.ScrubbableComponents)
		{
			auto SubframeTransformLoggerComp = Cast<UPinballTemporalLogSubframeTransformLoggerComponent>(Scrubbable);
			if(SubframeTransformLoggerComp == nullptr)
				continue;

			FAngelscriptGameThreadScopeWorldContext ScopeWorldContext(SubframeTransformLoggerComp);
			SubframeTransformLoggerComp.ScrubToPredictionTime(PredictionTime);
		}
	}
};

class UPinballTemporalSubframeSubsystem : UScriptEditorSubsystem
{
	bool bShowSubframes = false;
	float SelectedSubframe = 0;
}
#endif