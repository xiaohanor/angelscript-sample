UCLASS()
class AIslandOverseerDoorSplineContainer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
}