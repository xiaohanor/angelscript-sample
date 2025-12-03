class UPlayerCollisionCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CapabilityTags::Collision);

	AHazePlayerCharacter Player;

	TArray<AActor> AffectedActors;
	TArray<UPrimitiveComponent> AffectedComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		Player.CapsuleComponent.ApplyCollisionProfile(n"PlayerCharacterOverlapOnly", this, EInstigatePriority::Override);

		TArray<USceneComponent> Comps;
		Comps.Reserve(32);
		Comps.Add(Player.RootComponent);

		AHazePlayerCharacter OtherPlayer = Player.OtherPlayer;
		for (int CheckIndex = 0; CheckIndex < Comps.Num(); ++CheckIndex)
		{
			USceneComponent Comp = Comps[CheckIndex];

			// If the other player is attached to us, ignore them. The other player's collision is managed by them
			if (Comp.Owner == OtherPlayer)
				continue;

			// Check if we should hide this specific component
			if (Comp != Player.CapsuleComponent
				&& Comp != Player.RootComponent
				&& Comp != Player.Mesh)
			{
				if (Comp.Owner.IsA(AWorldSettings))
					continue;

				if (Comp.Owner != nullptr && Comp.Owner.RootComponent == Comp)
				{
					// If an actor's root is attached to us, block collision on that whole actor
					AffectedActors.Add(Comp.Owner);
					Comp.Owner.AddActorCollisionBlock(this);
				}
				else
				{
					auto PrimComp = Cast<UPrimitiveComponent>(Comp);

					// Block collision on this component only
					if (PrimComp != nullptr)
					{
						PrimComp.AddComponentCollisionBlocker(this);
						AffectedComponents.Add(PrimComp);
					}
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

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		Player.CapsuleComponent.ClearCollisionProfile(this);

		// Unblock attached actors
		for (int i = 0, Count = AffectedActors.Num(); i < Count; ++i)
		{
			if (AffectedActors[i] != nullptr)
				AffectedActors[i].RemoveActorCollisionBlock(this);
		}
		AffectedActors.Reset();

		// Unblock attached components
		for (int i = 0, Count = AffectedComponents.Num(); i < Count; ++i)
		{
			if (AffectedComponents[i] != nullptr)
				AffectedComponents[i].RemoveComponentCollisionBlocker(this);
		}
		AffectedComponents.Reset();
	}
};