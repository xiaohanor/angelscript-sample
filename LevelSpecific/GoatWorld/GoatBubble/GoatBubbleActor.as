UCLASS(Abstract)
class AGoatBubbleActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BubbleRoot;

	UPROPERTY(DefaultComponent, Attach = BubbleRoot)
	UStaticMeshComponent BubbleMesh;

	void DestroyBubble()
	{
		BP_DestroyBubble();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroyBubble() {}
}