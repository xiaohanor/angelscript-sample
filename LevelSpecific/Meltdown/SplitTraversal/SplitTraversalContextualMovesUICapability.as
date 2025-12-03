class USplitTraversalContextualMovesUICapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UPlayerContextualMovesTargetingComponent TargetingComp;
	UClass WidgetToUse;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		TargetingComp = UPlayerContextualMovesTargetingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
		if (Manager.bSplitSlideActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
		if (!Manager.bSplitSlideActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WidgetToUse = Player.IsZoe() ? TargetingComp.ContextualMovesWidget_Zoe : TargetingComp.ContextualMovesWidget_Mio;
		if(WidgetToUse == nullptr)
			WidgetToUse = TargetingComp.DefaultContextualMoveWidget;

		Player.BlockCapabilities(n"ContextualMovesWidgets", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"ContextualMovesWidgets", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();

		// Show on both players' screens
		for (AHazePlayerCharacter ShowPlayer : Game::Players)
		{
			FTargetableWidgetSettings WidgetSettings;
			WidgetSettings.TargetableClass = UContextualMovesTargetableComponent;
			WidgetSettings.DefaultWidget = WidgetToUse;
			WidgetSettings.MaximumVisibleWidgets = 1;
			WidgetSettings.bAllowAttachToEdgeOfScreen = false;
			WidgetSettings.OverrideShowWidgetsPlayer = ShowPlayer;

			if (ShowPlayer.IsZoe())
				WidgetSettings.AdditionalWidgetOffset = -Manager.SplitOffset;

			PlayerTargetablesComponent.ShowWidgetsForTargetables(WidgetSettings);
		}
	}
};