class ARedSpaceCubeGroup : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	TArray<ARedSpaceCube> Cubes;;
}