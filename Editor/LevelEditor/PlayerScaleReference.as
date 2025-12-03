UCLASS()
class APlayerScaleReference : AHazeActor
{
	default bIsEditorOnlyActor = true;

	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UPlayerEditorScaleReferenceComponent ScaleRefComp;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto Visualizer = CreatePlayerEditorVisualizer(Root, EHazePlayer::Mio, FTransform::Identity);
		Visualizer.SetShadowPriorityRuntime(EShadowPriority::Player);
	}
};

UCLASS(NotPlaceable, NotBlueprintable)
class UPlayerEditorScaleReferenceComponent : UActorComponent
{
	default bTickInEditor = true;
	bool bPlaced = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!Editor::IsSelected(Owner))
		{
			Owner.DestroyActor();
		}
		else if (!bPlaced)
		{
			FVector Location;
			FQuat Rotation;

			if (LevelEditor::GetActorPlacementPositionAtCursor(Location, Rotation))
			{
				Owner.SetActorLocation(Location);
				Editor::TriggerPostEditMove(Owner, true);
				Editor::ToggleActorSelected(Owner);
				Editor::ToggleActorSelected(Owner);
			}

			bPlaced = true;
		}
	}
}