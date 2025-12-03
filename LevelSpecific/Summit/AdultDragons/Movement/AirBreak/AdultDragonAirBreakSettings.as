class UAdultDragonAirBreakSettings : UHazeComposableSettings
{
	// The maximum the Dragon can roll
	UPROPERTY()
	float InputRollMax = 10;

	// The maximum the dragon can pitch up or down
	UPROPERTY()
	float PitchMaxAmount = 60;

	// How fast the dragon pitches towards the view direction
	UPROPERTY()
	float WantedPitchSpeed = 65.0;

	// How fast the dragon yaws
	UPROPERTY()
	float WantedYawSpeed = 85.0;

	// How fast it breaks down to 0 speed
	UPROPERTY()
	float BreakTime = 1.5;

	// How fast the dragon rotates towards the wanted rotation
	UPROPERTY()
	float RotationAcceleration = 1.2;

	// This impulse will be applied in the first frame after breaking
	UPROPERTY()
	float BreakEndImpulse = 1000;

	UPROPERTY()
	float CameraLagDuration = 2.5;
}