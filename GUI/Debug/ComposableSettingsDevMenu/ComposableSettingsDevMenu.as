class UComposableSettingsDevMenu : UHazeDevMenuEntryImmediateWidget
{
	TArray<UClass> SettingsClasses;
	TArray<FHazeComposableSettingsDebugLayer> Layers;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (!Drawer.IsVisible())
			return;

		AHazeActor Actor = Cast<AHazeActor>(GetDebugActor());
		if (Actor == nullptr)
		{
			auto S =  Drawer.Begin();
			S.Text("No actor selected.").Scale(2.0);
			if (S.Button("Select Actor"))
			{
				// Trigger actor picker?
				DevMenu::TriggerActorPicker();
			}
			return;
		}

		auto Root = Drawer.BeginVerticalBox();

		// Show actor name
		FString ActorName = Actor.Name.ToString();
		if(Network::IsGameNetworked())
		{
			if(Actor.HasControl())
				ActorName += " (Control)";
			else
				ActorName += " (Remote)";
		}
		auto Text = Root.SlotPadding(5).Text(f"{ActorName}").Scale(2.0);

		auto PlayerActor = Cast<AHazePlayerCharacter>(Actor);
		if(PlayerActor != nullptr)
		{
			Text.Color(PlayerActor.GetPlayerDebugColor());
		}

		auto Component = UHazeComposableSettingsComponent::Get(Actor);
		if (Component == nullptr)
		{
			Root.Text("Actor does not have any composable settings applied.");
			Drawer.End();
			return;
		}

		Component.DebugGetSettingsTypes(SettingsClasses);
		if (SettingsClasses.Num() == 0)
		{
			Root.Text("Actor does not have any composable settings applied.");
			Drawer.End();
			return;
		}

		// First panel: Settings classes
		auto Splitter = Root.SlotFill().Splitter();

		auto Sidebar = Splitter.SlotFill(0.5).VerticalBox();

		auto ClassList = Sidebar.SlotFill().SlotPadding(0).ListView(SettingsClasses.Num());
		ClassList.BackgroundColor(FLinearColor(0.05, 0.05, 0.045, 1.0));
		ClassList.DefaultSelectedItem(0);
		for (int ItemIndex : ClassList)
		{
			UClass SettingsClass = SettingsClasses[ItemIndex];

			auto Item = ClassList.Item(SettingsClass.Name);
			Item.Text(f"{SettingsClass.Name}").Scale(1.1);
		}

		// Retrieve debug layers from component
		UClass SelectedSettingsClass = nullptr;
		if (SettingsClasses.IsValidIndex(ClassList.SelectedItemIndex))
			SelectedSettingsClass = SettingsClasses[ClassList.SelectedItemIndex];

		if (SelectedSettingsClass != nullptr)
			Component.DebugDescribeSettingsType(SelectedSettingsClass, Layers);
		else
			Layers.Reset();

		// Second panel: Settings layers
		Sidebar.Spacer(10);
		auto LayersList = Sidebar.SlotFill().SlotPadding(0).ListView(Layers.Num());
		LayersList.BackgroundColor(FLinearColor(0.045, 0.05, 0.05, 1.0));
		LayersList.SelectedColor(FLinearColor(0.2, 0.0, 0.5, 0.5));
		LayersList.DefaultSelectedItem(0);
		for (int ItemIndex : LayersList)
		{
			auto Item = LayersList.Item();
			FString LayerText;

			auto& Layer = Layers[Layers.Num() - ItemIndex - 1];
			if (Layer.bIsTransientSettings)
				LayerText = f"Transient ({Layer.Priority :n})";
			else if (Layer.Asset != nullptr)
				LayerText = f"{Layer.Asset.Name} ({Layer.Priority :n})";
			else
				LayerText = f"Defaults";

			Item.Text(LayerText).Scale(1.1);
		}

		// Right side: Details box
		auto DetailsScroll = Splitter.ScrollBox();

		FString Details;
		if (Layers.IsValidIndex(LayersList.SelectedItemIndex))
		{
			auto& Layer = Layers[Layers.Num() - LayersList.SelectedItemIndex - 1];
			if (Layer.Asset != nullptr)
			{
				if (Layer.bIsTransientSettings)
					Details += f"<b>Transient Layer</>\n";

				FString AssetName = Layer.Asset.Outermost.GetPathName();
				if (AssetName == "/Script/AngelscriptAssets")
					AssetName = Layer.Asset.Name.ToString();

				Details += f"<b>Asset:</> {AssetName}\n";
				Details += f"<b>Instigator:</> {Layer.Instigator.ToPlainString()}\n";
				Details += f"<b>Priority:</> {Layer.Priority :n}";
			}
			else
			{
				Details += f"<b>Default Settings:</>";
			}

			DetailsScroll.SlotPadding(10).RichText(Details);

			if (Layer.Asset != nullptr)
			{
				auto ButtonBox = DetailsScroll.SlotPadding(10, 0).HorizontalBox();
				if (ButtonBox.Button("Edit Asset"))
				{
					Editor::OpenEditorForAsset(Layer.Asset.GetPathName());
				}
			}

			DetailsScroll.SlotPadding(10).RichText(Layer.DebugString);
		}
		else
		{
			DetailsScroll.SlotPadding(10).RichText(Details);
		}

		Drawer.End();
	}
};