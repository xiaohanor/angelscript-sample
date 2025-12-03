UCLASS(Abstract)
class ADroneWeightActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsConeRotateComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;


};
