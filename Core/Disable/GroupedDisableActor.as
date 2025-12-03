UCLASS(Meta = (HideCategories = "Tags AssetUserData Collision Cooking Transform Activation Rendering Replication Input Actor LOD Debug"))
class AGroupedDisableActor : AHazeActor
{
	default AddActorTag(n"GroupedDisable");

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Add Actors in Radius")
	float AddActorsRadius = -1;

	UPROPERTY(EditInstanceOnly, Category = "Add Actors in Radius")
	TArray<TSubclassOf<AHazeActor>> ActorTypesToAdd;
#endif

	/**
	 * Disable the actor, and all AutoDisableLinkedActors.
	 */
	UFUNCTION(BlueprintCallable)
	void AddActorDisableToActorAndLinkedActors(FInstigator Instigator)
	{
		DisableComp.AddActorDisableToActorAndLinkedActors(Instigator);
	}

	/**
	 * Remove a disabling instigator from the actor, and all AutoDisableLinkedActors.
	 */
	UFUNCTION(BlueprintCallable)
	void RemoveActorDisableFromActorAndLinkedActors(FInstigator Instigator)
	{
		DisableComp.RemoveActorDisableFromActorAndLinkedActors(Instigator);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if(AddActorsRadius > 0)
			Debug::DrawDebugSphere(ActorLocation, AddActorsRadius, 12, FLinearColor::Red);
	}

	UFUNCTION(CallInEditor, Category = "Add Actors in Radius")
	void AddActorsInRadius()
	{
		if(AddActorsRadius < 0)
		{
			Editor::MessageDialog(EAppMsgType::Ok, FText::AsCultureInvariant("Find radius is invalid!"));
			return;
		}

		if(ActorTypesToAdd.IsEmpty())
		{
			Editor::MessageDialog(EAppMsgType::Ok, FText::AsCultureInvariant("No actor types assigned!"));
			return;
		}

		TArray<TSoftObjectPtr<AHazeActor>> ActorsToLink;
		FSphere SearchBounds = FSphere(ActorLocation, float32(AddActorsRadius));

		for(auto ActorTypeToFind : ActorTypesToAdd)
		{
			if(ActorTypeToFind == nullptr)
				continue;

			TArray<AHazeActor> Actors = Editor::GetAllEditorWorldActorsOfClass(ActorTypeToFind);

			for(auto Actor : Actors)
			{
				FVector ActorOrigin;
				FVector ActorExtents;
				Actor.GetActorBounds(false, ActorOrigin, ActorExtents);

				FSphere ActorBounds = FSphere(ActorOrigin, float32(ActorExtents.Max));
				if(!SearchBounds.Intersects(ActorBounds))
					continue;

				ActorsToLink.AddUnique(Actor);
			}
		}

		for(auto ActorToLink : ActorsToLink)
		{
			DisableComp.AutoDisableLinkedActors.AddUnique(ActorToLink);
		}
	}
#endif
};