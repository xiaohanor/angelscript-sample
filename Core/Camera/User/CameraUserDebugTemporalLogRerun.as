/** 
 * Makes if possible to rerun character movement frames
 */
class UCameraUserDebugTemporalLogRerunExtender : UTemporalLogUIExtender
{
	FString GetUIName(FHazeTemporalLogReport Report) const override
	{
		return "Camera User Rerun Extender";
	}

	bool ShouldShow(FHazeTemporalLogReport Report) const override
	{
	#if EDITOR
		if(!TemporalLog.bPauseLogPruning)
			return false;

		auto User = Cast<UCameraUserComponent>(Report.AssociatedObject);
		if(User == nullptr)
			return false;
		if(!User.CanRerunFrames())
			return false;
		return true;
	#else
		return false;
	#endif
	}

	void DrawUI(UHazeImmediateDrawer Drawer, FHazeTemporalLogReport Report) const override
	{
	#if EDITOR
		auto User = Cast<UCameraUserComponent>(Report.AssociatedObject);
		if (User == nullptr)
			return;	

		int CurrentFrame = Report.ReportedFrame;
		auto Section = Drawer.Begin();

		// RERUN
		if(Section.Button("Trigger Rerun"))
		{	
			User.CallEditorRerunFrame(CurrentFrame);
		}
	#endif
	}
};