event void FSketchbookPenPropStartBeingDrawn();
event void FSketchbookPenPropFinishBeingDrawn();

event void FSketchbookPenPropStartBeingErased();
event void FSketchbookPenPropFinishBeingErased();

namespace Sketchbook
{
	namespace DrawableProps
	{
		const FHazeDevToggleCategory DevToggleCategory = FHazeDevToggleCategory(n"Audio Drawable Props");
		const FHazeDevToggleBool AudioDebugProps = FHazeDevToggleBool(DevToggleCategory, n"Audio Debug Drawable Props");
	}
}

class ASketchbookDrawableProp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.bNeverDistanceCull = true;
	default MeshComp.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent, ShowOnActor)
	USketchbookDrawableObjectComponent DrawableComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USketchbookDrawableEditorRenderedComponent EditorRenderedComp;
#endif

	UPROPERTY(BlueprintReadOnly, Category = "Drawable Prop")
	FSketchbookPenPropStartBeingDrawn OnStartBeingDrawn;

	UPROPERTY(BlueprintReadOnly, Category = "Drawable Prop")
	FSketchbookPenPropFinishBeingDrawn OnFinishedBeingDrawn;

	UPROPERTY(BlueprintReadOnly, Category = "Drawable Prop")
	FSketchbookPenPropStartBeingErased OnStartBeingErased;

	UPROPERTY(BlueprintReadOnly, Category = "Drawable Prop")
	FSketchbookPenPropFinishBeingErased OnFinishedBeingErased;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DrawableComp.OnStartBeingDrawn.AddUFunction(this, n"StartBeingDrawn");
		DrawableComp.OnFinishedBeingDrawn.BindUFunction(this, n"FinishedBeingDrawn");

		DrawableComp.OnStartBeingErased.BindUFunction(this, n"StartBeingErased");
		DrawableComp.OnFinishedBeingErased.BindUFunction(this, n"FinishedBeingErased");
	}

	UFUNCTION()
	private void StartBeingDrawn()
	{
		OnStartBeingDrawn.Broadcast();
	}

	UFUNCTION()
	private void FinishedBeingDrawn()
	{
		OnFinishedBeingDrawn.Broadcast();
	}

	UFUNCTION()
	private void StartBeingErased()
	{
		OnStartBeingErased.Broadcast();
	}

	UFUNCTION()
	private void FinishedBeingErased()
	{
		OnFinishedBeingErased.Broadcast();
	}

	UFUNCTION(CallInEditor, Category = "Drawable Prop")
	private void MakeAllPropsStatic()
	{
		Editor::BeginTransaction("MakeAllPropsStatic");

		TArray<ASketchbookDrawableProp> Actors = Editor::GetAllEditorWorldActorsOfClass(ASketchbookDrawableProp);
		for(auto Actor : Actors)
		{
			auto PropActor = Cast<ASketchbookDrawableProp>(Actor);
			if(PropActor == nullptr)
				continue;

			PropActor.Modify();

			TArray<USceneComponent> SceneComponents;
			PropActor.GetComponentsByClass(SceneComponents);

			for(auto SceneComponent : SceneComponents)
				SceneComponent.SetMobility(EComponentMobility::Static);
		}

		Editor::EndTransaction();
	}
};