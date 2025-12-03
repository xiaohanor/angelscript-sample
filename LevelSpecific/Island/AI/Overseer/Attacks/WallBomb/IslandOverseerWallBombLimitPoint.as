class AIslandOverseerWallBombLimitPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
}