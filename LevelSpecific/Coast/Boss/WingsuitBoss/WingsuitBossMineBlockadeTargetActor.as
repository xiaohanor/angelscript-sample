UCLASS(Abstract)
class AWingsuitBossMineBlockadeTargetActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent EditorMesh;
	default EditorMesh.bIsEditorOnly = true;
	default EditorMesh.bHiddenInGame = true;
	default EditorMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UWingsuitBossMineBlockadeTargetVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditDefaultsOnly)
	float TriggerRadius = 5000.0;

	bool bConsumed = false;
}

#if EDITOR
UCLASS(NotBlueprintable, NotPlaceable)
class UWingsuitBossMineBlockadeTargetVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UWingsuitBossMineBlockadeTargetVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UWingsuitBossMineBlockadeTargetVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Target = Cast<AWingsuitBossMineBlockadeTargetActor>(Component.Owner);
		DrawWireSphere(Target.ActorLocation, Target.TriggerRadius, FLinearColor::Red);
	}
}
#endif