class UDentistToothMovementSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Ground")
	float GroundMaxSpeed = 800;

	UPROPERTY(Category = "Ground")
	float GroundAcceleration = 3000;

	UPROPERTY(Category = "Ground")
	float GroundDeceleration = 2000;
	
	UPROPERTY(Category = "Ground")
	float GroundRotationSpeed = 100;

	UPROPERTY(Category = "Ground")
	float ReboundFactor = 5;

	UPROPERTY(Category = "Air")
	float AirMaxSpeed = 700;

	UPROPERTY(Category = "Air")
	float AirAcceleration = 1500;

	UPROPERTY(Category = "Air")
	float AirDeceleration = 500;

	UPROPERTY(Category = "Air")
	float AirRotationSpeed = 5;

	// UPROPERTY(Category = "Ground")
	// float GroundMaxSpeed = 800;

	// UPROPERTY(Category = "Ground")
	// float GroundAcceleration = 1500;

	// UPROPERTY(Category = "Ground")
	// float GroundDeceleration = 2000;
	
	// UPROPERTY(Category = "Ground")
	// float GroundRotationSpeed = 5;

	// UPROPERTY(Category = "Ground")
	// float ReboundFactor = 3;

	// UPROPERTY(Category = "Air")
	// float AirMaxSpeed = 700;

	// UPROPERTY(Category = "Air")
	// float AirAcceleration = 500;

	// UPROPERTY(Category = "Air")
	// float AirRotationSpeed = 5;
};

namespace Dentist::Tags
{
	const FName ToothMovement = n"ToothMovement";
	const FName OrientToVelocity = n"OrientToVelocity";
}