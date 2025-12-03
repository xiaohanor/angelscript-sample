/**
 * A spline simply used to override the current camera look
 */
UCLASS(NotBlueprintable)
class AGravityBikeSplineCameraLookSplineActor : ASplineActor
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UGravityBikeSplineCameraLookSplineComponent CameraLookSplineComp;

	// UPROPERTY(DefaultComponent)
	// UHazeListedActorComponent ListedActorComp;
};