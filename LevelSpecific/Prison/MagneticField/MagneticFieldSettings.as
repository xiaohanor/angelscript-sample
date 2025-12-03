namespace MagneticField
{
	const float InnerRadius = 600.0;
	const float OuterRadius = 200.0;
	const float ChargeDurationGrounded = 0.2;
	const float ChargeDurationAirborne = 0.2;

	float GetTotalRadius()
	{
		return InnerRadius + OuterRadius;
	}

	const float RepelHorizontalMovementMultiplier = 2000.0;
	const float RepelHorizontalMovementInterpSpeed = 5.0;
	const float RepelForce = 15000.0;
	const float RepelLaunchForce = 3000.0;
	const float RepelHorizontalDrag = 3.0;
	const float RepelVerticalDrag = 4.5;
	const float RepelMoveTowardsCenterForce = 0.2;
	const float RepelPreventOrbitalMovementForce = 0.1;

    const FName Feature = n"ExoSuit";
	
	const float ForceFeedbackFrequency = 12.0;
	const float ForceFeedbackIntensity = 0.05;

	const float BurstLaunchBufferTime = 0.5;
}