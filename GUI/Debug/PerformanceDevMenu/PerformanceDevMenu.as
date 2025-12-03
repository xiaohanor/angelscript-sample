enum EPerformanceDevMenuPageType
{
	Ticking,
	MovingOverlaps,
};

class UPerformanceDevMenu : UHazeDevMenuEntryImmediateWidget
{
	EPerformanceDevMenuPageType PageType = EPerformanceDevMenuPageType::Ticking;

	TMap<EPerformanceDevMenuPageType, TSubclassOf<UPerformanceDevMenuPage>> Pages;
	default Pages.Add(EPerformanceDevMenuPageType::Ticking, UPerformanceDevMenuTickingPage);
	default Pages.Add(EPerformanceDevMenuPageType::MovingOverlaps, UPerformanceDevMenuMovingOverlapsPage);

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (!Drawer.IsVisible())
			return;

		FHazeImmediateVerticalBoxHandle RootBox = Drawer.BeginVerticalBox();

		FHazeImmediateHorizontalBoxHandle ButtonBar = RootBox
			.BorderBox()
				.BackgroundColor(FLinearColor::Black)
				.MinDesiredHeight(20)
			.SlotPadding(10)
			.SlotVAlign(EVerticalAlignment::VAlign_Fill)
			.HorizontalBox();

		ButtonBar.SlotVAlign(EVerticalAlignment::VAlign_Center).Text("Metric: ").Scale(1.0);
		ButtonBar.SlotVAlign(EVerticalAlignment::VAlign_Fill)
			.BorderBox()
				.MinDesiredWidth(250)
				.MinDesiredHeight(40)
			.ComboBox()
				.ChooseEnum(PageType);
		
		UPerformanceDevMenuPage Page = Pages[PageType].DefaultObject;

		Page.UpdateButtonBar(ButtonBar);

		if(ShouldUpdateList())
			Page.UpdateState();

		Page.UpdateList(RootBox);
	}

	bool ShouldUpdateList() const
	{
#if EDITOR
		// Don't update the list if we are not playing
		if(!Editor::IsPlaying())
			return false;
#endif

		return true;
	}
}