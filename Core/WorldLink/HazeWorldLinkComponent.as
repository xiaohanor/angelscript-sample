void DropAllWorldLinkReferences(AActor ReferencedActor)
{
	TArray<AActor> Actors;
	Actors = Editor::GetAllEditorWorldActorsOfClass(AActor);

	for (auto Actor : Actors)
	{
		auto LinkComp = UHazeWorldLinkComponent::Get(Actor);

		if (LinkComp != nullptr &&
			LinkComp.LinkedActor.Get() == ReferencedActor)
			LinkComp.LinkedActor.Reset();
	}
}

class UHazeWorldLinkComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "World Link")
	TSoftObjectPtr<AActor> LinkedActor;

	UFUNCTION(CallInEditor)
	void LinkUpWorlds()
	{
	#if EDITOR
		if (!LinkedActor.IsValid())
		{
			// If we've reset LinkedActor to null, something might still be referencing us
			DropAllWorldLinkReferences(Owner);
			return;
		}

		auto OtherLinkComp = UHazeWorldLinkComponent::Get(LinkedActor.Get());

		if (OtherLinkComp == nullptr)
		{
			// Might've selected a child object of a linkable object in the editor
			//  so we move through the hierarchy looking for a valid parent
			AActor OtherParent;
			GetFirstLinkableParent(LinkedActor.Get(),
				OtherParent,
				OtherLinkComp);

			if (OtherParent == nullptr ||
				OtherLinkComp == nullptr)
			{
				LinkedActor.Reset();
				return;
			}

			LinkedActor = TSoftObjectPtr<AActor>(OtherParent);
		}
		
		// Possible self-reference, no bueno
		if (OtherLinkComp == this)
		{
			LinkedActor.Reset();
			return;
		}

		// Let other component drop their reference mutually first
		if (OtherLinkComp.LinkedActor.IsValid() &&
			OtherLinkComp.LinkedActor.Get() != Owner)
			OtherLinkComp.DropReferenceMutual();

		// Since we've "forgotten" what we were linked to before
		//  go through all actors to find any references to us and remove them
		DropAllWorldLinkReferences(Owner);
		
		OtherLinkComp.LinkedActor = TSoftObjectPtr<AActor>(Owner);
	#endif
	}

	// Drops our reference to LinkedActor after dropping their reference to us.
	void DropReferenceMutual()
	{		
		if (!LinkedActor.IsValid())
		{
			// May be pending
			LinkedActor.Reset();
			return;
		}

		auto OtherActor = LinkedActor.Get();
		auto OtherComp = UHazeWorldLinkComponent::Get(OtherActor);

		if (OtherComp != nullptr &&
 			OtherComp.LinkedActor.IsValid() &&
			OtherComp.LinkedActor.Get() == Owner)
			OtherComp.LinkedActor.Reset();

		LinkedActor.Reset();
	}

	void GetFirstLinkableParent(AActor Child, 
		AActor&out Actor,
		UHazeWorldLinkComponent&out LinkComp)
	{
		Actor = Child;
		LinkComp = nullptr;
		while (Actor != nullptr && LinkComp == nullptr)
		{
			Actor = Actor.AttachParentActor;
			
			if (Actor != nullptr)
				LinkComp = UHazeWorldLinkComponent::Get(Actor);
		}
	}
}