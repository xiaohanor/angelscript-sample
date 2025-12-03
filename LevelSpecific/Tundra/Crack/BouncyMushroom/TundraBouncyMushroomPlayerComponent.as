class UTundraMushroomPlayerBounceComponent : UActorComponent
{
	uint BounceFrame;

	bool HasBouncedRecently() const
	{
		return BounceFrame == Time::FrameNumber || BounceFrame == Time::FrameNumber -1;
	}
};