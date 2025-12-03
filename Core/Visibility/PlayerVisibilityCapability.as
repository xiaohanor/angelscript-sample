class UPlayerVisibilityCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CapabilityTags::Visibility);

	AHazePlayerCharacter Player;
	TArray<AActor> HiddenActors;
	TArray<USceneComponent> HiddenComponents;

	#if !RELEASE
	UTemporalLogScrubbableVisible DebugScrubableComponent;
	#endif

 	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		#if !RELEASE
		DebugScrubableComponent = UTemporalLogScrubbableVisible::GetOrCreate(Owner);
		#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		Player.RemoveActorVisualsBlock(this);

		// Unhide attached actors
		for (int i = 0, Count = HiddenActors.Num(); i < Count; ++i)
		{
			if (HiddenActors[i] != nullptr)
				HiddenActors[i].RemoveActorVisualsBlock(this);
		}
		HiddenActors.Reset();

		// Unhide attached components
		for (int i = 0, Count = HiddenComponents.Num(); i < Count; ++i)
		{
			if (HiddenComponents[i] != nullptr)
				HiddenComponents[i].RemoveComponentVisualsBlocker(this);
		}
		HiddenComponents.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		Player.AddActorVisualsBlock(this);

		TArray<USceneComponent> Comps;
		Comps.Reserve(32);
		Comps.Add(Player.RootComponent);

		AHazePlayerCharacter OtherPlayer = Player.OtherPlayer;
		for (int CheckIndex = 0; CheckIndex < Comps.Num(); ++CheckIndex)
		{
			USceneComponent Comp = Comps[CheckIndex];
			
			// If the other player is attached to us, ignore them. The other player's visibility is managed by them
			if (Comp.Owner == OtherPlayer)
				continue;

			// Check if we should hide this specific component
			if (Comp.Owner != Owner)
			{
				if (Comp.Owner.IsA(AWorldSettings))
					continue;

				if (Comp.Owner != nullptr && Comp.Owner.RootComponent == Comp)
				{
					// If an actor's root is attached to us, hide that whole actor
					HiddenActors.Add(Comp.Owner);
					Comp.Owner.AddActorVisualsBlock(this);
				}
				else
				{
					// Set visibility on this component only
					Comp.AddComponentVisualsBlocker(this);
					HiddenComponents.Add(Comp);
				}
			}

			// Recurse through children of this component
			for (int i = 0, Count = Comp.GetNumChildrenComponents(); i < Count; ++i)
			{
				auto Child = Comp.GetChildComponent(i);
				if (Child != nullptr)
					Comps.AddUnique(Child);
			}
		}
	}

};
