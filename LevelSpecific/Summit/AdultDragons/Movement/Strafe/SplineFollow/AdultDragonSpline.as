UCLASS(NotBlueprintable)
class AAdultDragonSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	USummitAdultDragonSplineFollowComponent SplineFollowComp;
};