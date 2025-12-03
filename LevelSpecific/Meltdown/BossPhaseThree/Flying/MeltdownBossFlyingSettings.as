
class UMeltdownBossFlyingSettings : UHazeComposableSettings
{
	UPROPERTY()
	float MinimumPitch = -30.0;
	UPROPERTY()
	float MaximumPitch = 30.0;

	UPROPERTY()
	float MinimumYaw = -960.0;
	UPROPERTY()
	float MaximumYaw = 930.0;

	UPROPERTY()
	float BoundaryClampEdgeWidth = 0.3;

	UPROPERTY()
	float HorizontalSpeed = 1000.0;
	UPROPERTY()
	float HorizontalAcceleration = 3000.0;

	UPROPERTY()
	float VerticalSpeed = 1000.0;
	UPROPERTY()
	float VerticalAcceleration = 3000.0;

	UPROPERTY()
	float CameraPointOfInterestClampYaw = 60.0;
	UPROPERTY()
	float CameraPointOfInterestClampPitch = 45.0;

	UPROPERTY()
	float DashDuration = 0.2;
	UPROPERTY()
	float DashDistance = 1000.0;
	UPROPERTY()
	float DashCooldown = 1.0;
	UPROPERTY()
	float DashAccelerationDuration = 0.1;
	UPROPERTY()
	float DashDecelerationDuration = 0.1;
	UPROPERTY()
	float DashExitSpeed = 3000.0;
}