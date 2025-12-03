namespace Pig
{
	namespace StretchyLegs
	{
		const float MinLength = 200.0;
		const float MaxLength = 600.0;
		const float StretchDuration = 0.4;
		const float StretchFullyExtendedDuration = 0.25;

		const float CameraOffsetMultiplier = 0.75;
		const float ClearBlendCameraSettingsDuration = 4.0;

		const float FlipImpulseGrounded = 600.0;
		const float FlipImpulseAirborne = 400.0;
		const float FlipDuration = 0.4;

		// Wile E. Coyote air time before getting butt slapped
		const float AirDelay = 0.13;

		namespace Dizzy 
		{
			const float Duration = 6.0;
			const float DisableMovementDuration = 1.0;

			const float HaloRadius = 50;
			const FVector HaloOffset = FVector(0, 0, 40);

			const int StarsAmount = 3;
			const float StarSpeed = 0.5;
			const float StarMinScale = 0.001;
			const float StarMaxScale = 0.1;
		}
	}

	namespace RainbowFart
	{
		const float GroundedVerticalImpulse = 950.0;
		const float AirborneVerticalImpluse = 560.0;

		const float BounceBubbleExtraVerticalVelocity = 10000.0;
		const float BounceBubbleMaxVerticalVelocity = 1800.0;

		const float HorizontalImpulse = 600.0;
	}

	namespace GoldenApple
	{
		const float PickupAlignDuration = 0.2;
		const float PickupAnimationDuration = 1.2;
	}	
}

class UPigMovementSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Ground")
	float MoveSpeedMin = 300.0;

	UPROPERTY(Category = "Ground")
	float MoveSpeedMax = 700.0;

	UPROPERTY(Category = "Ground")
	float Acceleration = 8.0;

	UPROPERTY(Category = "Ground")
	float RotationSpeed = 5.0;

	UPROPERTY(Category = "Ground")
	float StickDeadZone = 0.3;


	UPROPERTY(Category = "Jump")
	float JumpImpulse = 1000.0;


	UPROPERTY(Category = "Sprint")
	float SpeedMultiplier = 1.0;


	UPROPERTY(Category = "Slide")
	float SlideMoveSpeed = 1000.0;

	UPROPERTY(Category = "Slide")
	float SlideAcceleration = 10.0;

	UPROPERTY(Category = "Slide")
	float SlideMaxInputAngleRelativeToSlope = 40.0;
}

class UPigSausageMovementSettings : UHazeComposableSettings
{
	UPROPERTY()
	float ForwardSpeed = 400.0;

	UPROPERTY()
	float LateralSpeed = 500.0;

	UPROPERTY()
	float LateralAcceleration = 8.0;

	UPROPERTY()
	float LateralDeceleration = 4.0;

	UPROPERTY()
	float WobbleMultiplier = 3.0;
}

class URainbowFartPigSettings : UHazeComposableSettings
{
	UPROPERTY()
	float MaxVerticalForce = 800.0;
}