class UGravityBikeFreeKartDriftSettings : UHazeComposableSettings
{
	/**
	 * Jumping
	 */
	UPROPERTY(EditAnywhere, Category = "Jumping")
	bool bDoLilJump = false;
	UPROPERTY(EditAnywhere, Category = "Jumping")
	float KartDriftJumpVerticalImpulse = 600;
	UPROPERTY(EditAnywhere, Category = "Jumping")
	float ForceAirborneTime = 0.35;

	/**
	 * Ground Turning
	 */
	UPROPERTY(EditAnywhere, Category = "Ground Turning")
	float GroundTurnMinAmount = 0.2;
	UPROPERTY(EditAnywhere, Category = "Ground Turning")
	float GroundTurnDefaultAmount = 1;
	UPROPERTY(EditAnywhere, Category = "Ground Turning")
	float GroundTurnMaxAmount = 3;
	UPROPERTY(EditAnywhere, Category = "Ground Turning")
	float GroundDriftSideDragIncreaseTime = 1.0;

	/**
	 * Boost
	 */
	UPROPERTY(EditAnywhere, Category = "Boost")
	bool bApplyBoost = true;
	UPROPERTY(EditAnywhere, Category = "Boost")
	float MinBoostDuration = 0.5;
	UPROPERTY(EditAnywhere, Category = "Boost")
	float MaxBoostDuration = 2;
	UPROPERTY(EditAnywhere, Category = "Boost")
	float ReachMaxBoostTime = 1.0;
	UPROPERTY(EditAnywhere, Category = "Boost")
	float ReachMaxBoostExponent = 2.0;

	/**
	 * Hover
	 */
	UPROPERTY(EditAnywhere, Category = "Hover")
	float JumpYawOffset = 10;
	UPROPERTY(EditAnywhere, Category = "Hover")
	float DriftYawOffset = 35;
	UPROPERTY(EditAnywhere, Category = "Hover")
	float DriftYawAccelerateDuration = 1.5;

	/**
	 * Speed
	 */
	UPROPERTY(EditAnywhere, Category = "Speed")
	float MinSpeed = 400; // 3000

	/**
	 * Camera
	 */
	UPROPERTY(EditAnywhere, Category = "Camera")
	bool bUseDriftCamera = true;

	UPROPERTY(EditAnywhere, Category = "Camera")
	float CameraFollowDuration = 1.5;

	UPROPERTY(EditAnywhere, Category = "Camera")
	float CameraLeadAmount = 50;
};

namespace GravityBikeFree::KartDrift
{
	/**
	 * Tilt
	 */
    const float MaxTilt = 50;
    const float TiltStiffness = 50;
    const float TiltDamping = 0.5;
};