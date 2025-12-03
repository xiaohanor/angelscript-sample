
class UPlayerAirJumpSettings : UHazeComposableSettings
{
	UPROPERTY()
	float Impulse = 906.0;

	// Extra horizontal speed we get when we air jump compared to normal movement speed
	UPROPERTY()
	float BonusHorizontalSpeed = 0.0;

	UPROPERTY()
	float FacingDirectionInterpSpeed = 8.0;
	

	//How much we need to steer away from our current velocity to cancel it out / redirect when air jumping
	const float VelocityRedirectionAngle = 45;
}