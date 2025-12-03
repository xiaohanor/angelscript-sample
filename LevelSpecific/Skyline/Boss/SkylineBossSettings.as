class USkylineBossSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Movement")
	float BaseHeight = 9000.0; // 12000.0

	UPROPERTY(Category = "Movement")
	float PendingDownHeight = 7000.0;

	UPROPERTY(Category = "Movement")
	float StepDuration = 1.8; // 3.0

	UPROPERTY(Category = "Movement")
	float StepInterval = 0.5; // 1.0

	UPROPERTY(Category = "Movement")
	float StepHeight = 3000.0; // 2000.0

	UPROPERTY(Category = "Movement")
	float StepMaxPitch = 40;

	UPROPERTY(Category = "Movement")
	float StepMaxPitchDistance = 11000; //If the new target is this many units away, the foot will reach its max pitch tilt

	UPROPERTY(Category = "Movement")
	float LookAtSpeed = 20.0;

	UPROPERTY(Category = "Movement")
	float LookAtDrag = 8.0;

	UPROPERTY(Category = "Movement|Curves")
	UCurveFloat FootStepCurve;

	UPROPERTY(Category = "Movement|Curves")
	UCurveFloat FootStepSpeedCurve;

	UPROPERTY(Category = "Movement|Curves")
	UCurveFloat FootStepRotationCurve;
	
	UPROPERTY(Category = "Attack")
	float MinLongRangeAttacks = 11000.0; // 22000.0
}

namespace SkylineBoss
{
	const int NUM_LEG_BONE_INDEXES = 29;

	// The IK chain ends above the ground.
	// This offset is matched by the leg actors attached to the mesh.
	const float IK_CHAIN_END_VERTICAL_OFFSET = 1219;
	const FRotator IK_CHAIN_END_ROTATION_OFFSET = FRotator(0, 0, -180);
};