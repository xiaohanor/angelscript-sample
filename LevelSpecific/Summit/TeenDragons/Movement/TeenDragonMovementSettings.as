class UTeenDragonMovementSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Input")
    float MinimumInput = 0.4;
	UPROPERTY(Category = "Ground Movement")
    float MinimumSpeed = 320.0;
	UPROPERTY(Category = "Ground Movement")
    float MaximumSpeed = 950.0;

	//add for sprinting
	UPROPERTY(Category = "Sprint")
    float SprintSpeed = 1350.0;

	UPROPERTY(Category = "Dash")
    float DashSpeed = 2800.0;
	UPROPERTY(Category = "Dash")
    float DashDuration = 0.65;
	// Cooldown will start when dash ends
	UPROPERTY(Category = "Dash")
    float DashCooldown = 0.0;
	// During the dash, this deceleration will be applied constantly
	UPROPERTY(Category = "Dash")
    float DashDeceleration = 1900;

	// How long the dragon keeps moving during its floor slowdown deceleration
	UPROPERTY(Category = "Floor Slowdown")
    float FloorSlowdownDuration = 0.20;

	UPROPERTY(Category = "Ground Movement")
    float AccelerationInterpSpeed = 10.0;
	UPROPERTY(Category = "Ground Movement")
    float SlowDownInterpSpeed = 5.0;
	UPROPERTY(Category = "Ground Movement")
    float TurnMultiplier = 1.6;

	UPROPERTY(Category = "Air Movement")
    float AirHorizontalMinMoveSpeed = 450.0;
	UPROPERTY(Category = "Air Movement")
    float AirHorizontalMaxMoveSpeed = 1150.0;
	UPROPERTY(Category = "Air Movement")
    float AirMovementRotationSpeed = 0.5;
	UPROPERTY(Category = "Air Movement")
    float AirHorizontalVelocityAccelerationWithInput = 5.0;
	UPROPERTY(Category = "Air Movement")
    float AirHorizontalVelocityAccelerationWithoutInput = 1.0;
	UPROPERTY(Category = "Air Movement")
    float AirHorizontalVelocityDecelerationWhenOverSpeed = 0.72;
	UPROPERTY(Category = "Air Movement")
	float AirFacingDirectionInterpSpeed = 2.5;
}