class UCongaLinePlayerSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Movement")
	float MoveSpeed = CongaLine::DefaultMoveSpeed;	// Change DefaultMoveSpeed in CongaLineSettings.as

	UPROPERTY(Category = "Movement")
	float MinimumWallHitMoveSpeed = CongaLine::DefaultMoveSpeed * 0.75;

	UPROPERTY(Category = "Movement")
	float Acceleration = 1000;

	UPROPERTY(Category = "Movement")
	float Deceleration = 1000;

	UPROPERTY(Category = "Turning")
	float TankControlsTurnSpeed = 1;

	UPROPERTY(Category = "Turning")
	float InterpTowardsDirectionTurnSpeed = 1.9;

	UPROPERTY(Category = "Camera")
	bool bUseCameraDistanceOverLineAlpha = false;

	UPROPERTY(Category = "Camera")
	FRuntimeFloatCurve CameraDistanceAlphaOverLineAlpha;

	UPROPERTY(Category = "Camera")
	float CameraDistanceAccelerateDuration = 1.0;
};