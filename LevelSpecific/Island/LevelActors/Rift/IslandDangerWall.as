class AIslandDangerWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent Cube;
	
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

};
