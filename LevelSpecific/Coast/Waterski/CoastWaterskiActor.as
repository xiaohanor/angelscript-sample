UCLASS(Abstract)
class ACoastWaterskiActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

}