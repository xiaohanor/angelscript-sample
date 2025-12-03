class UAdultDragonAirDashSettings : UHazeComposableSettings
{
	UPROPERTY()
	float AirDashDuration = 0.5;

	UPROPERTY()
	float MaxAdditionalSpeed = 5000;

	// Time axle : 0 - 1 Fraction of air dash (0 seconds to AirDashDuration)
	// Value Axle : Fraction of speed during dash (0 additional speed to MaxAdditionalSpeed)
	UPROPERTY()
	FRuntimeFloatCurve SpeedCurve;
	default SpeedCurve.AddDefaultKey(0, 0);
	default SpeedCurve.AddDefaultKey(0.2, 1);
	default SpeedCurve.AddDefaultKey(1, 0);

	// How fast the wanted pitch is updated
	UPROPERTY()
	float WantedPitchSpeed = 70.0;

	// How fast the dragon yaws
	UPROPERTY()
	float WantedYawSpeed = 60.0;

	// The maximum the dragon can pitch up or down
	UPROPERTY()
	float PitchMaxAmount = 75;

	// How fast the dragon rotates towards the wanted rotation while there is steering input
	UPROPERTY()
	float RotationAccelerationDuringInput = 3.0;

	// How fast the dragon rotates towards the wanted rotation while there is no steering input
	UPROPERTY()
	float RotationAcceleration = 1.0;

	/* How much speed is lost when flying into a wall
	If set to 1, all speed is lost with a full on collision*/
	UPROPERTY()
	float CollisionSpeedLossMultiplier = 1.0;
}