class ASkylineTorEjectPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(4.0);
#endif
}