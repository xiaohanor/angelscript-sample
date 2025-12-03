
class UCompoundCapabilityTemporalExtender : UTemporalLogUIExtender
{
	FString GetUIName(FHazeTemporalLogReport Report) const override
	{
		return "Compound Capability";
	}

	bool ShouldBeResizable(FHazeTemporalLogReport Report) const override
	{
		return true;
	}

	void DrawUI(UHazeImmediateDrawer Drawer, FHazeTemporalLogReport Report) const override
	{
		TArray<FHazeCapabilityCompoundDebug> CompoundTree;

		FString CompoundPath = Report.ReportedPath;
		if (Report.ChildNodes.Num() == 0)
			CompoundPath = GetTemporalLogParentPath(CompoundPath);

		CapabilityDebug::GetCompoundTreeFromTemporalLog(
			TemporalLog,
			CompoundPath, Report.ReportedFrame,
			CompoundTree);

		FCompoundCapabilityDebug CompoundHelper;
		CompoundHelper.bCanSelectNodes = true;

		// Find selected capability index
		for (int i = 0, Count = CompoundTree.Num(); i < Count; ++i)
		{
			if (CompoundTree[i].OptionalTemporalPath == Report.ReportedPath)
			{
				CompoundHelper.SelectedIndex = i;
				break;
			}
		}

		auto Section = Drawer.Begin();
		auto Canvas = Section.CanvasPanel();
		CompoundHelper.Draw(Canvas, CompoundTree);

		if (CompoundHelper.ClickedIndex != -1)
			BrowseTemporalLog(this, CompoundTree[CompoundHelper.ClickedIndex].OptionalTemporalPath);
	}
};