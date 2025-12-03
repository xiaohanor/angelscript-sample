
class UAudioOverviewAssetsWidget : UHazeAudioOverviewAssetsWidget
{
	UPROPERTY(Meta = (BindWidget))
	UHazeImmediateWidget Content;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
	}

	void TickWidget(FGeometry MyGeometry, float InDeltaTime)
	{
		if (Content == nullptr)
			return;

		if (!Content.Drawer.IsVisible())
			return;

		auto ContentSection = Content.Drawer.Begin("Assets");

		ContentSection.Text("Here we will be able to see and debug when our assets will be loaded by reference!");

		Content.Drawer.End();
	}
}