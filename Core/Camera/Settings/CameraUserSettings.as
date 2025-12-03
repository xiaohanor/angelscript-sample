class UCameraUserSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Camera")
	UCurveFloat InputAccelerationCurveYaw;

	UPROPERTY(Category = "Camera")
	UCurveFloat InputAccelerationCurvePitch;

	UPROPERTY(Category = "Camera")
	FRotator SnapOffset = FRotator(-10, 0, 0);


	UPROPERTY(Category = "SpringArm")
	UCurveFloat IdealDistanceByPitchCurve;

	UPROPERTY(Category = "SpringArm")
	UCurveFloat PivotHeightByPitchCurve;

	UPROPERTY(Category = "SpringArm")
	UCurveFloat CameraOffsetByPitchCurve;

	UPROPERTY(Category = "SpringArm")
	UCurveFloat CameraOffsetOwnerSpaceByPitchCurve;

	UPROPERTY(Category = "SpringArm")
	UCurveFloat PivotLagMaxMultiplierByPitchCurve;

	UPROPERTY(Category = "SpringArm")
	float PivotOwnerRotationAccelerationDuration = 1;

	UPROPERTY(Category = "SpringArm")
	float ExtensionDurationAfterBlock = 1;

	// Both the cameras 'bUseCollision' and this must be enable to allow camera tracing
	UPROPERTY(Category = "Camera Trace")
	bool bAllowCameraTrace = true;

	// If true, we allow the camera to go through small objects. This comes with a increased cost
	UPROPERTY(Category = "Camera Trace", meta = (EditCondition = "bAllowCameraTrace"))
	bool bAllowCameraTunnelTrace = true;
}