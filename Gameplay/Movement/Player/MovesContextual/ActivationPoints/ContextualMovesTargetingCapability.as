
class UContextualMovesTargetingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ContextualMoves");
	default CapabilityTags.Add(n"ContextualMovesWidgets");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

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
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WidgetToUse = Player.IsZoe() ? TargetingComp.ContextualMovesWidget_Zoe : TargetingComp.ContextualMovesWidget_Mio;
		if(WidgetToUse == nullptr)
			WidgetToUse = TargetingComp.DefaultContextualMoveWidget;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTargetableWidgetSettings WidgetSettings;
		WidgetSettings.TargetableClass = UContextualMovesTargetableComponent;
		WidgetSettings.DefaultWidget = WidgetToUse;
		WidgetSettings.MaximumVisibleWidgets = 1;

		PlayerTargetablesComponent.ShowWidgetsForTargetables(WidgetSettings);
	}
};