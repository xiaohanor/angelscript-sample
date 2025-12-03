class UForceFeedbackDevMenu : UHazeDevMenuEntryImmediateWidget
{
	const float HeaderScale = 1.3;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (!Drawer.IsVisible())
			return;

		AHazeActor Actor = Cast<AHazeActor>(GetDebugActor());
		if (Actor == nullptr)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if (Player == nullptr)
			return;

		UHazePlayerForceFeedbackComponent PlayerForceFeedbackComponent = UHazePlayerForceFeedbackComponent::Get(Player);
		if (PlayerForceFeedbackComponent == nullptr)
			return;

		UHazeInputComponent InputComponent = UHazeInputComponent::Get(Player);
		if (InputComponent == nullptr)
			return;

		auto RootPanel = Drawer.BeginVerticalBox().SlotFill()
			.ScrollBox(EOrientation::Orient_Horizontal)
			.VerticalBox();

		auto TopPanel = RootPanel.HorizontalBox();
		{
			// Player actor name
			{
				auto Text = TopPanel.Text(f"{Actor.Name}").Scale(2.0);
				if(Player != nullptr)
					Text.Color(Player.GetPlayerDebugColor());

				TopPanel.Spacer(10);
			}
		}

		// Force feedback enabled?
		{
			bool bEnabled = Player.IsForceFeedbackEnabled();
			bool bTriggersEnabled = Player.IsTriggerForceFeedbackEnabled();

			TopPanel.SlotPadding(0, 10).Text("Controller rumble " + (bEnabled ? "enabled" : "disabled")).Color(bEnabled ? FLinearColor::Green : FLinearColor::Red);
			TopPanel.SlotPadding(20, 10).Text("Trigger rumble " + (bTriggersEnabled ? "enabled" : "disabled")).Color(bTriggersEnabled ? FLinearColor::Green : FLinearColor::Red);
		}

		auto BottomPanel = RootPanel.SlotFill().HorizontalBox();
		BottomPanel.SlotPadding(10.0, 10.0, 0.0, 0.0);
		{
			// Force feedback assets
			auto FFAssetPanel = BottomPanel.VerticalBox();
			{
				FFAssetPanel.Text("Force Feedback Assets\n")
					.Color(FLinearColor::LucBlue)
					.Scale(HeaderScale)
					.Bold();

					FHazeForceFeedbackDebugInfo DebugInfo;
					InputComponent.GetDebugInfo(DebugInfo);

					for (FString FFEffect : DebugInfo.ForceFeedbackEffects)
					{
						int HeaderEnd = FFEffect.Find("\n");
						auto HeadRoot = FFAssetPanel.VerticalBox();
							HeadRoot.SlotPadding(0, 0, 100, 0).Text(FFEffect.Left(HeaderEnd)).Color(FLinearColor::DPink);
							HeadRoot.SlotPadding(0, -10, 0, 0).Text(FFEffect.RightChop(HeaderEnd)).Color(FLinearColor::Purple * 30);
							HeadRoot.HorizontalBox();
					}
			}

			BottomPanel.SlotPadding(50.0, 10.0, 0.0, 0.0);

			// Trigger assets
			auto FFTAssetPanel = BottomPanel.VerticalBox();
			{
				FFTAssetPanel.Text("Trigger Effect Assets\n")
					.Color(FLinearColor::LucBlue)
					.Scale(HeaderScale)
					.Bold();

				FFTAssetPanel.VerticalBox().HorizontalBox().SlotPadding(0, 0, 10, 0).Text("Coming soon...").Color(FLinearColor::Yellow * 0.5);
			}

			BottomPanel.SlotPadding(50.0, 10.0, 0.0, 0.0);

			// Frame feedback
			auto FrameValuesPanel = BottomPanel.VerticalBox();
			{
				FrameValuesPanel.Text("Manual Values\n")
					.Color(FLinearColor::LucBlue)
					.Scale(HeaderScale)
					.Bold();

				FrameValuesPanel.VerticalBox().HorizontalBox().SlotPadding(0, 0, 10, 0).Text("Coming soon...").Color(FLinearColor::Yellow * 0.5);
			}
		}
	}
}