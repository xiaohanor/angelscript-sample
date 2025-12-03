class AIslandOverseerPovCombatPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
#endif

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComponent;
	default ArrowComponent.SetRelativeLocation(FVector(0.0, 0.0, 0.0));
	default ArrowComponent.ArrowSize = 3.0;
	default ArrowComponent.ArrowColor = FLinearColor::Red;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
}