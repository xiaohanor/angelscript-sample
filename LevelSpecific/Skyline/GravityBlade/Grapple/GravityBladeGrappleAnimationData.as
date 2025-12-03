struct FGravityBladeGrappleAnimationData
{
	uint LastGrappleThrowFrame = 0;
	uint LastGrappleTransitionFrame = 0;
	uint LastGrapplePullFrame = 0;
	uint LastGrappleLandFrame = 0;
	bool bGrappleGrounded = true;
	float GrappleStateAlpha = 0.0;
	float GrappleVerticalAngle = 0.0;

	bool GrappleThrewThisFrame() const
	{
		return (LastGrappleThrowFrame == Time::FrameNumber);
	}

	bool GrappleTransitionedThisFrame() const
	{
		return (LastGrappleTransitionFrame == Time::FrameNumber);
	}

	bool GrapplePulledThisFrame() const
	{
		return (LastGrapplePullFrame == Time::FrameNumber);
	}
	
	bool GrappleLandedThisFrame() const
	{
		return (LastGrappleLandFrame == Time::FrameNumber);
	}
}