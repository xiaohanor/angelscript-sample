

/** 
 * 
*/
class UFollowComponentMovementData : UBaseMovementData
{
	default DefaultResolverType = UFollowComponentMovementResolver;

	int FollowMoveCount = 0;
	const USceneComponent FollowComponent = nullptr;
	int MaxIterations = 1;
	bool bSlideAlongSurfaces = true;
	bool bUseSweepBackDepenetration = false;

	bool IsValid() const override
	{
		return HasMovementComponent() && FollowComponent != nullptr;
	}

	bool PrepareFollowMove(UHazeMovementComponent MovementComponent, const USceneComponent InFollowComponent)
	{
		if(InFollowComponent == nullptr)
			return false;
		
		if(!PrepareMove(MovementComponent))
			return false;

		FollowMoveCount = MovementComponent.FollowMovesThisFrame;
		FollowComponent = InFollowComponent;

		auto HazeActor = Cast<AHazeActor>(MovementComponent.Owner);
		if(HazeActor != nullptr)
		{
			auto Settings = UFollowComponentMovementSettings::GetSettings(HazeActor);
			MaxIterations = Settings.MaxIterations;
			bSlideAlongSurfaces = Settings.bSlideAlongSurfaces;
			bUseSweepBackDepenetration = Settings.bUseSweepBackDepenetration;
		}

		// Don't allow 0 or less iterations, since then we shouldn't be using ResolveCollision following
		MaxIterations = Math::Max(MaxIterations, 1);

		return true;
	}
}

