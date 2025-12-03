UCLASS(HideCategories = "Activation Tags")
class AVillageOgreGroupDisabler : AGroupedDisableActor
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UVillageOgreGroupDisableComponent OgreGroupDisableComponent;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		DisableComp.AutoDisableLinkedActors.Reset();

		float DistanceSquared = Math::Square(OgreGroupDisableComponent.FindOgresRange);

		auto Ogres = Editor::GetAllEditorWorldActorsOfClass(AVillageOgreBase);
		for(auto It : Ogres)
		{
			AVillageOgreBase Ogre = Cast<AVillageOgreBase>(It);
			if(ActorLocation.DistSquared(Ogre.ActorLocation) < DistanceSquared)
				DisableComp.AutoDisableLinkedActors.Add(Ogre);
		}
	}
#endif
}

UCLASS(HideCategories = "Tags AssetUserData Collision Cooking Transform Activation Rendering Replication Input Actor LOD Debug")
class UVillageOgreGroupDisableComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly)
	float FindOgresRange = 5000;
}

class UVillageOgreGroupDisableComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UVillageOgreGroupDisableComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		UVillageOgreGroupDisableComponent OgreGroupDisabler = Cast<UVillageOgreGroupDisableComponent>(Component);
		if (OgreGroupDisabler != nullptr)
		{
			const float Range = OgreGroupDisabler.FindOgresRange;
			const FVector Origin = OgreGroupDisabler.Owner.ActorLocation;

			DrawWireSphere(Origin, Range, FLinearColor::LucBlue, 2);
		}
	}
}