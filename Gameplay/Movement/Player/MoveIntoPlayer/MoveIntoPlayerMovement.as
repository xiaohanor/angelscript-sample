/** 
 * 
*/
class UMoveIntoPlayerMovementData : UBaseMovementData
{
	default DefaultResolverType = UMoveIntoPlayerMovementResolver;

	USceneComponent MovedByComponent;

#if !RELEASE
	FString MoveCategory;
#endif

	bool IsValid() const override
	{
		return HasMovementComponent();
	}

	bool PrepareMoveIntoPlayer(
		const UHazeMovementComponent MovementComponent, 
		USceneComponent InMovedByComponent,
		FString DebugMoveCategory)
	{
		if(!PrepareMove(MovementComponent))
			return false;

		MovedByComponent = InMovedByComponent;

#if !RELEASE
		MoveCategory = DebugMoveCategory;
#endif

		// Limit max iterations to 3
		MaxRedirectIterations = 3;

		return true;
	}
}

