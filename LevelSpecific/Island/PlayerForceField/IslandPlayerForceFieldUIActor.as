UCLASS(Abstract)
class AIslandPlayerForceFieldUIActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UStaticMeshComponent UIMesh;
	default UIMesh.CollisionProfileName = n"NoCollision";
}