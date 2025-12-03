class UWitchPlayerMushroomBounceComponent : UActorComponent
{
	uint BounceFrame;

	float BounceTime;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams SlotAnimParams;

	bool HasBouncedThisFrame() const
	{
		return BounceFrame == Time::FrameNumber;
	}

	bool HasBouncedLastFrame() const
	{
		return BounceFrame == Time::FrameNumber -1;
	}
};