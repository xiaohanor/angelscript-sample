class UIslandContextualMovesTargetingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ContextualMoves");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 95;

	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UIslandPlayerContextualMovesTargetingComponent TargetingComp;

	UClass WidgetToUse;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		TargetingComp = UIslandPlayerContextualMovesTargetingComponent::Get(Player);
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
		Player.BlockCapabilities(n"ContextualMoves", this);

		WidgetToUse = Player.IsZoe() ? TargetingComp.ContextualMovesWidget_Zoe : TargetingComp.ContextualMovesWidget_Mio;
		if(WidgetToUse == nullptr)
			WidgetToUse = TargetingComp.DefaultContextualMoveWidget;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"ContextualMoves", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTargetableWidgetSettings WidgetSettings;
		WidgetSettings.TargetableClass = UContextualMovesTargetableComponent;
		WidgetSettings.DefaultWidget = WidgetToUse;
		WidgetSettings.MaximumVisibleWidgets = 1;

		UTargetableComponent Targetable;
		FTargetableResult Result;
		PlayerTargetablesComponent.GetMostVisibleTargetAndResult(UContextualMovesTargetableComponent, Targetable, Result);

		TargetingComp.bPrimaryTargetBlockedByForceField = false;
		
		if(Targetable != nullptr && Targetable.HasTag(n"Island"))
		{
			FIslandHazeTraceSettings Trace = IslandTrace::InitFromPlayer(Player, n"TargetableOcclusion");
			Trace.IgnorePlayers();
			Trace.IgnoreCameraHiddenComponents(Player);

			const float TracePullback = 100.0;
			FVector TargetPosition = Targetable.WorldLocation;
			if (TracePullback != 0.0)
				TargetPosition -= (TargetPosition - Player.ActorLocation).GetSafeNormal() * TracePullback;

			FHitResult Hit = Trace.QueryTraceSingle(
				Player.ActorLocation,
				TargetPosition,
			);

			if(Hit.bBlockingHit && Hit.Actor.IsA(AIslandRedBlueForceField))
			{
				TargetingComp.bPrimaryTargetBlockedByForceField = true;
			}
		}

		PlayerTargetablesComponent.ShowWidgetsForTargetables(WidgetSettings);
	}
};