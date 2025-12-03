class ASlidingRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	USceneComponent LocationOffset;

	UPROPERTY(DefaultComponent, Attach = LocationOffset)
	USceneComponent ShakeComp;

	UPROPERTY(DefaultComponent, Attach = ShakeComp)
	UStaticMeshComponent Mesh;
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshEnd;
	default Mesh.bCanEverAffectNavigation = false;
}