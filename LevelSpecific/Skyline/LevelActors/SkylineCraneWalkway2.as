class ASkylineCraneWalkway2 : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent CraneRoot;

	UPROPERTY(DefaultComponent, Attach = CraneRoot)
	UFauxPhysicsWeightComponent WeightComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;
};