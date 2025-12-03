namespace GravityBikeFree::Alignment
{
	/**
	 * Ground
	 */

    const float GroundAlignmentDuration = 0.5;
	const bool bUseWheelTrace = true;
    const float GroundWheelAlignmentDurationMultiplier = 2;
    const float GroundTraceDistanceMultiplier = 1;

	/**
	 * Forward
	 */

	const float ForwardAlignmentDuration = 1;
    const float ForwardTraceDistanceMultiplier = 0.2;
	const float ForwardRedirectAlignmentDuration = 0.2;

	/**
	 * Air
	 */

    const float AirAlignmentDuration = 2;
    const float AirAlignmentMaxUpDot = 0.8;
    const float AirAlignmentMaxDownDot = -0.8;
	const bool bAlignWithApproachingGround = false;

	/**
	 * Landing
	 */

    const float LandingAlignmentDuration = 1.0;
    const float LandingAlignmentTraceDistanceMultiplier = 0.5;
};