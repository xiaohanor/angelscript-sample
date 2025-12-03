class AMoveIntoPlayerShape : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerShape;
};