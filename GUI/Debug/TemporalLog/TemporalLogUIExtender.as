
UCLASS(Abstract)
class UTemporalLogUIExtender : UHazeTemporalLogExtender
{
	// The current temporal log being viewed
	UHazeTemporalLog TemporalLog;
	// The temporal log dev menu
	UObject TemporalDevMenu;

	// Get the name of this UI
	FString GetUIName(FHazeTemporalLogReport Report) const
	{
		return "...";
	}

	// Whether this UI should be shown right now
	bool ShouldShow(FHazeTemporalLogReport Report) const
	{
		return true;
	}

	// Whether the panel this is rendering should be resizable or autosized
	bool ShouldBeResizable(FHazeTemporalLogReport Report) const
	{
		return false;
	}

	// Draw the UI tab in the temporal log
	void DrawUI(UHazeImmediateDrawer Drawer, FHazeTemporalLogReport Report) const
	{
	}
}