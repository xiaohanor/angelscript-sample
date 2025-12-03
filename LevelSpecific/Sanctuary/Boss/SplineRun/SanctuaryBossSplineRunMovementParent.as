class ASanctuaryBossSplineRunMovementParent : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent InheritMoveComp;

	FSplinePosition SplinePosition;
};