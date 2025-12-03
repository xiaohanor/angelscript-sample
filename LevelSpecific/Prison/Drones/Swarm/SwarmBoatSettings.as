class USwarmBoatSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Transition")
	float EnterTransitionDuration = 0.5;


	UPROPERTY(Category = "Movement | Water")
	float InputAccelerationDuration = 2.6; // Increased from 1.3 to compensate for bigger boat

	UPROPERTY(Category = "Movement | Water")
	float MaxSpeed = SwarmDrone::Movement::Speed * 0.85;

	UPROPERTY(Category = "Movement | Water")
	float RotationSpeed = 180.0; // * 1.5?!


	UPROPERTY(Category = "Movement | Air")
	float AirMaxRoll = 30.0;

	UPROPERTY(Category = "Movement | Air")
	float RollAcceleration = 20.0;


	// Used to determine location of propeller guy (forward offset)
	UPROPERTY(Category = "Formation")
	float PropellerOffset = 45.0;


	UPROPERTY(Category = "Camera")
	float AdditiveSpeedFov = 5.0;

	UPROPERTY(Category = "Collision")
	bool bDetachMagnetDroneOnAnyCollision = false;
}

class USwarmBoatRapidsSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Spline")
	float SplineWidthScaleMultiplier = 30;

	UPROPERTY(Category = "Spline")
	float LookAheadSplineDistance = 100.0;

	UPROPERTY(Category = "Movement")
	float MaxSpeed = 3000.0;

	UPROPERTY(Category = "Movement")
	float MaxRoll = 20.0;

	UPROPERTY(Category = "Movement")
	float MaxYaw = 30.0;
}