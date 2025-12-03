class USpeedEffectDevMenu: UHazeDevMenuEntryImmediateWidget
{
    UFUNCTION(BlueprintOverride)
    void Tick(FGeometry Geometry, float DeltaTime)
    {
		if (!Drawer.IsVisible())
			return;


		auto RootPanel = Drawer.BeginVerticalBox().SlotFill()
		.ScrollBox(EOrientation::Orient_Horizontal)
		.HorizontalBox();
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPostProcessingComponent PostProcessingComponent = UPostProcessingComponent::Get(Player);

			auto TopPanel = RootPanel.ScrollBox().VerticalBox();
			TopPanel.Text(Player.Name.ToString()).Bold().Scale(1.3).Color(FLinearColor::LucBlue);
			//TopPanel.Text("").Bold();
			
			//TopPanel.Text("Current Priority: " + PostProcessingComponent.CurrentSpeedEffectSpeed.CurrentPriority);
			//TopPanel.Text("Current Speed: " + PostProcessingComponent.CurrentSpeedEffectSpeed.Get());
			//TopPanel.Text("Is Default Value: " + PostProcessingComponent.CurrentSpeedEffectSpeed.IsDefaultValue());
			//TopPanel.Text("Default Value: " + PostProcessingComponent.CurrentSpeedEffectSpeed.DefaultValue);
			
		}
		
    }
}