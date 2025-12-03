
class UAudioOverviewWidget : UHazeUserWidget
{
	default TickFrequency = EWidgetTickFrequency::Auto;

	UPROPERTY(Meta = (BindWidget))
	UHazeImmediateWidget Content;

	UPROPERTY(Meta = (BindWidget))
	UAudioOverviewConfigWidget Config;

	UPROPERTY(Meta = (BindWidget))
	UAudioOverviewToolsWidget Tools;

	UPROPERTY(Meta = (BindWidget))
	UAudioOverviewAssetsWidget Assets;

	UPROPERTY(NotVisible)
	TArray<FString> Notifications;
	// default Notifications.Add("")

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// Draw();

		if (Config != nullptr)
			Config.TickWidget(MyGeometry, InDeltaTime);

		if (Tools != nullptr)
			Tools.TickWidget(MyGeometry, InDeltaTime);

		if (Assets != nullptr)
			Assets.TickWidget(MyGeometry, InDeltaTime);
	}

	void Draw()
	{
		if (Content == nullptr)
			return;

		if (!Content.Drawer.IsVisible())
			return;

		auto ContentSection = Content.Drawer.Begin("General");

		ContentSection.Text("Here general content will be");

		Content.Drawer.End();
	}
}