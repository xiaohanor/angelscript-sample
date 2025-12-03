class UDentistToothRagdollSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Ragdoll")
	float StopAfterDelay = 0.5;

	UPROPERTY(Category = "Ground|Slope")
	float GroundDeceleration = 100;

	UPROPERTY(Category = "Ground|Slope")
	float GroundMaxHorizontalSpeed = 900;

	UPROPERTY(Category = "Ground|Slope")
	float GroundMaxSpeedDeceleration = 1000;

	UPROPERTY(Category = "Ground|Slope")
	float MinSlopeAngle = 10;

	UPROPERTY(Category = "Ground|Slope")
	float UpSlopeDeceleration = 1000;

	UPROPERTY(Category = "Ground|Slope")
	float UpSlopeSideDeceleration = 1000;

	UPROPERTY(Category = "Ground|Slope")
	float DownSlopeDeceleration = 250;

	UPROPERTY(Category = "Ground|Slope")
	float DownSlopeSideDeceleration = 100;

	UPROPERTY(Category = "Air")
	float AirReboundMultiplier = 1;

	UPROPERTY(Category = "Air")
	float AirAcceleration = 1500;

	UPROPERTY(Category = "Air")
	float AirMaxHorizontalSpeed = 800;

	UPROPERTY(Category = "Air")
	float AirMaxSpeedDeceleration = 2000;

	UPROPERTY(Category = "Air")
	float AirMaxFallSpeed = -1500;

	UPROPERTY(Category = "Air")
	float AirMaxFallDeceleration = 3000;

	UPROPERTY(Category = "Edge")
	float PushOffEdgeForce = 100;
};

namespace Dentist::Ragdoll
{

};

namespace Dentist::Tags
{
	const FName Ragdoll = n"Ragdoll";
	const FName RagdollMovement = n"RagdollMovement";
	const FName RagdollRotation = n"RagdollRotation";
	const FName CancelOnRagdoll = n"CancelOnRagdoll";
};