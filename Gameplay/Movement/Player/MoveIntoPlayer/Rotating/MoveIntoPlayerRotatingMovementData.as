/** 
 * 
*/
class UMoveIntoPlayerRotatingMovementData : UBaseMovementData
{
	default DefaultResolverType = UMoveIntoPlayerRotatingMovementResolver;

	const UMoveIntoPlayerShapeComponent ShapeComponent;
	FVector FollowDelta;
	FVector ExtrapolatedDelta;

	bool IsValid() const override
	{
		return HasMovementComponent() && ShapeComponent != nullptr;
	}

	bool PrepareMoveIntoPlayer(const UHazeMovementComponent MovementComponent, const UMoveIntoPlayerShapeComponent InShapeComponent)
	{
		if(!ensure(InShapeComponent != nullptr))
			return false;

		if(!PrepareMove(MovementComponent))
			return false;

		MaxRedirectIterations = 3;

		ShapeComponent = InShapeComponent;

		return true;
	}
}

