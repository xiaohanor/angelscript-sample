class ALiftSectionSawBlade : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditInstanceOnly, ExposeOnSpawn)
	ASplineActor SplineActor;	
}
