#if EDITOR
class UTargetableTemporalUIExtender : UTemporalLogUIExtender
{
	FString GetUIName(FHazeTemporalLogReport Report) const override
	{
		return "Targetable Extender";
	}

	bool ShouldShow(FHazeTemporalLogReport Report) const override
	{
		return true;
	}

	void DrawUI(UHazeImmediateDrawer Drawer, FHazeTemporalLogReport Report) const override
	{
		auto Section = Drawer.Begin();

		Section.Text("NOTE: To log traces and more, check the Haze Editor Only bool on the targetable component you want to debug.").Scale(1.2).AutoWrapText();

		Drawer.End();
	}
};
#endif