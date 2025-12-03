UCLASS(NotBlueprintable, NotPlaceable)
class UIslandCameraLookTowardsSplineRotationComponent : UActorComponent
{
	access Internal = private, AIslandCameraLookTowardsSplineRotationActor;

	access:Internal
	UHazeSplineComponent Spline;

	bool HasSplineToFollow() const
	{
		return Spline != nullptr;
	}

	UHazeSplineComponent GetSpline() const
	{
		return Spline;
	}
};