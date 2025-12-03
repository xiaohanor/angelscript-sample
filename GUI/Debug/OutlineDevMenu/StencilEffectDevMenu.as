
class UStencilEffectDevMenu: UHazeDevMenuEntryImmediateWidget
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
			UStencilEffectViewerComponent OutlineViewerComponent = UStencilEffectViewerComponent::Get(Player);

			auto TopPanel = RootPanel.ScrollBox().VerticalBox();
			TopPanel.Text(Player.Name.ToString()).Bold().Scale(1.3).Color(FLinearColor::LucBlue);
			TopPanel.Text("Stencil Slots").Bold();

			for (auto StencilEffectDataAsset : OutlineViewerComponent.StencilEffectSlots)
			{
				if(StencilEffectDataAsset == nullptr)
					TopPanel.Text("nullptr");
				else
					TopPanel.Text("" + StencilEffectDataAsset.Name + " - " + StencilEffectDataAsset.Data.Type);
			}
			TopPanel.Spacer(25);

			TopPanel.Text("Stencil Assignments").Bold();
			
			for (auto Iterator : OutlineViewerComponent.StencilEffectAssignments)
			{
				FString ActorName = "";
				FString ComponentName = "";
				FString AssetName = "";
				
				AssetName = "" + Iterator.Value.Get().Asset;
				
				if(Iterator.Key != nullptr)
					ComponentName = Iterator.Key.Name.ToString();
				
				if(Iterator.Key != nullptr)
					ActorName = Iterator.Key.Owner.Name.ToString();

				TopPanel.Text(ActorName + ", " + ComponentName + ", Asset: " + AssetName + ", InstigatedCount: " + Iterator.Value.Num());
			}
		}
		
    }
}