class UBattlefieldHoverboardAirMovementSettings : UHazeComposableSettings
{
	// How fast the wanted rotation updates with input
	UPROPERTY()
	float WantedRotationSpeed = 45.0;

	// How fast it rotates towards the wanted rotation
	UPROPERTY()
	float RotationDuration = 0.8;

	// How fast it rotates towards the wanted rotation during input
	UPROPERTY()
	float RotationDurationDuringInput = 0.45;

	/* How fast the horizontal velocity direction
	turns towards the forward vector based on input (Degrees per second)*/
	UPROPERTY()
	float HorizontalInputVelocityTurnSpeed = 40;

	/* How fast the horizontal velocity direction 
	turns towards the forward vector constantly (Degrees per second)*/
	UPROPERTY()
	float HorizontalConstantVelocityTurnSpeed = 17;

	UPROPERTY(Category = "Speed")
	float HorizontalAcceleration = 1300.0;

	UPROPERTY(Category = "Speed")
	float MaxHorizontalSpeed = 3000.0;
}