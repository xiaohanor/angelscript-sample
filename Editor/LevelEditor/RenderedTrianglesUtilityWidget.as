enum ERenderedTrianglesDisplayMode
{
	Summary,
	TriangleDensity,
}

class URenderedTrianglesUtilityWidget : UEditorUtilityWidget
{
	UPROPERTY(BindWidget)
	UHazeImmediateWidget ImmediateWidget;

	ERenderedTrianglesDisplayMode DisplayMode = ERenderedTrianglesDisplayMode::Summary;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		auto Drawer = ImmediateWidget.GetDrawer();
		if (!Drawer.IsVisible())
			return;

		FRenderingStatsReport Report;
		EditorRendering::GetRenderingStatsReport(Report, GetWorld(), Editor::GetEditorViewLocation(), Editor::GetEditorViewRotation());

		auto Root = Drawer.BeginVerticalBox();
		Root
			.ComboBox()
			.ChooseEnum(DisplayMode)
		;

		auto ScrollBox = Root.SlotFill().ScrollBox();

		if (DisplayMode == ERenderedTrianglesDisplayMode::Summary)
		{
			for (auto Elem : Report.StaticMeshes)
			{
				auto Row = ScrollBox.HorizontalBox();
				Row.Text(Elem.Key.Name.ToString());
			}
		}
	}
}