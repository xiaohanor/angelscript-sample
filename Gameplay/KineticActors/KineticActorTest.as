UCLASS(NotBlueprintable)
class AKineticActorTest : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	AKineticMovingActor MovingActor;

	UPROPERTY(EditInstanceOnly)
	AKineticRotatingActor RotatingActor;

	UPROPERTY(EditInstanceOnly)
	AKineticSplineFollowActor SplineFollowActor;

	UFUNCTION(DevFunction)
	private void MovingActivateForward()
	{
		MovingActor.ActivateForward();
	}

	UFUNCTION(DevFunction)
	private void MovingReverseBackwards()
	{
		MovingActor.ReverseBackwards();
	}

	UFUNCTION(DevFunction)
	private void RotatingActivateForward()
	{
		RotatingActor.ActivateForward();
	}

	UFUNCTION(DevFunction)
	private void RotatingReverseBackwards()
	{
		RotatingActor.ReverseBackwards();
	}

	UFUNCTION(DevFunction)
	private void SplineFollowActivateFollowSpline()
	{
		SplineFollowActor.ActivateFollowSpline();
	}

	UFUNCTION(DevFunction)
	private void SplineFollowReverseDirection()
	{
		SplineFollowActor.ReverseDirection();
	}
};