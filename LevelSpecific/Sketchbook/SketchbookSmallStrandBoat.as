UCLASS(Abstract)
class ASketchbookSmallStrandBoat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;
};
