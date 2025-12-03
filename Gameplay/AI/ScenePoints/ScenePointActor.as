
UCLASS(Abstract, HideCategories = "Physics Debug Activation Cooking Tags LOD Collision Rendering Actor")
class AScenepointActorBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Scenepoint";
	default Billboard.WorldScale3D = FVector(2.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);
#endif	

	UFUNCTION()
	UScenepointComponent GetScenepoint()
	{
		return nullptr;
	};
}

class AScenepointActor : AScenepointActorBase
{
#if EDITOR
	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComponent;
	default ArrowComponent.SetRelativeLocation(FVector(20.0, 0.0, 0.0));
	default ArrowComponent.ArrowSize = 2.0;
	default ArrowComponent.ArrowColor = FLinearColor::Red;
#endif

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	private UScenepointComponent ScenepointComponent;

	UScenepointComponent GetScenepoint() override
	{
		return ScenepointComponent;
	};
}
