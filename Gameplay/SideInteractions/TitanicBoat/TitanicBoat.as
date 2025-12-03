UCLASS(Abstract)
class ATitanicBoat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent TitanicRoot;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;
};