
class USkylineFlyingCarGotySettings : UHazeComposableSettings
{
	// How fast we move on the spline
	UPROPERTY(Category = "SplineMovement")
	float SplineMoveSpeed = 8000.0;

	// How many times we increase the 'SplineMoveSpeed' while boosting on the spline
	UPROPERTY(Category = "SplineMovement")
	float SplineBoostSpeedMultiplier = 2.0; //2
	
	// How fast we accelerate to the target movespeed if its higer than the current move speed
	UPROPERTY(Category = "SplineMovement")
	float SplineMoveSpeedAcceleration = 10.0;

	// How fast we decelerate to the target movespeed if its lower than the current move speed
	UPROPERTY(Category = "SplineMovement")
	float SplineMoveSpeedDeceleration = 5.0;

	// How far along the spline we steer towards
    UPROPERTY(Category = "SplineMovement")
	float SplineGuidanceDistance = 1000.0;

	UPROPERTY(Category = "SplineMovement")
	float SplineMovementSplineGrabDistance = 1000.0;

	/** How hard we turn towards the spline center when moving along it (0..1), 
	 * 0: Only uses input steering 
	 * 1: Only uses spline direction 
	 * At the Highways 'TunnelRadius' distance from the spline, the alpha is 1.
	 * At the middle of the tunnel, the alpha is 0.
	 * */
    UPROPERTY(Category = "SplineMovement")
	FHazeRange SplineGuidanceStrength = FHazeRange(0.0, 0.5);

	/** Modify the SplineGuidanceStrength using a custom curve */
	UPROPERTY(Category = "SplineMovement")
	FRuntimeFloatCurve SplineGuidanceStrengthAlphaModifier;

	// The max amount we can steer away from the spline direction
	UPROPERTY(Category = "SplineMovement")
	float MaxSplineOffsetSteeringAngle = 30.0;


	// How long the dash will last
    UPROPERTY(Category = "Dash")
	float DashDuration = 0.5;

	// How much car will travel via dash
	UPROPERTY(Category = "Dash")
	float DashImpulse = 3000.0;


	// How far away from the spline center the car needs to be in order
	// to escape the highway (0 is spline center and 1 is highway radius)
	// UPROPERTY(Category = "Hopping")
	// float SplineHoppingFraction = 0.5;

	// // Max angle (relative to MovementWorldUp) that car needs to have in order to leave spline
	// UPROPERTY(Category = "Hopping")
	// float SplineHoppingAngle = 90.0;

	// How high the car will jump, relative to the begining of the hop
	UPROPERTY(Category = "Hopping")
	float SplineHoppingHeight = 4000.0;

	// Initial horizontal impulse when hopping starts
	UPROPERTY(Category = "Hopping")
	float SplineHoppingInitialHorizontalImpulse = 2000.0;

	// The time it will take to accelerate to the desired height
	UPROPERTY(Category = "Hopping")
	float SplineHoppingAccelerationDuration = 1.0;

	// The time it will take to accelerate from 0 to 'SplineGuidanceStrength' right after hopping
	// onto a new highway spline
	UPROPERTY(Category = "Hopping")
	float SplineMergeGuidanceStrengthAccelerationDuration = 1.0;

	// When merging onto new spline, lookahead 'SplineGuidanceDistance' will be multiplied by this
	UPROPERTY(Category = "Hopping")
	float SplineMergeGuidanceDistanceMultiplier = 5.0;

	// After landing inside tunnel; how long will it take before you can dash or spline hop
	UPROPERTY(Category = "Hopping")
	float SpecialManeuverCooldown = 0.6;

	// // How fast we move while not on the spline
	// UPROPERTY(Category = "FreeMovement")
	// float FreeMoveSpeed = 2000.0;

	// Distance at which we start lerping towards the spline if we are in freefly movement
    UPROPERTY(Category = "FreeMovement")
	float SplineGrabDistance = 1500.0;

	/** How much gravity we add when we are pitching up or down 
	 * Min; Pitch toward the sky
	 * Max; Pitch toward the ground,
	*/
	UPROPERTY(Category = "FreeMovement")
	FHazeRange FreeFlyPitchGravityMultiplier = FHazeRange(1.2, 3.0);

	// The max amount we can steer away from the spline direction
	UPROPERTY(Category = "FreeMovement")
	float MaxFreeFlyOffsetSteeringAngle = 45.0;

	// (Degrees relative to absolute forward vector) How steep the nose dive will be when free flying
	UPROPERTY(Category = "FreeMovement")
	float MaxFreeFlyDiveAngle = 50.0;

	// How fast we reach the wanted facing direction
	UPROPERTY(Category = "FreeMovement")
	float FreeFlyRotationInterpSpeed = 20.0;

	// Yaw rotation and pitch rotation speeds will be multiplied by this when free flying
	UPROPERTY(Category = "FreeMovement")
	float FreeFlySteeringMultiplier = 2.0;


	// How fast we move on houses
	UPROPERTY(Category = "HouseMovement")
	float HouseMoveSpeed = 5000.0;


	// How fast the car will move on rooftops
	UPROPERTY(Category = "CrashMovement")
	float CrashMoveSpeed = 7000.0;

	// How much of the original vertical speed is kept for bounce
	UPROPERTY(Category = "CrashMovement")
	float CrashBounceImpulseMultiplier = 0.1;


	UPROPERTY(Category = "RampMovement")
	float RampLateralSpeedMultiplier = 1.5;

	UPROPERTY(Category = "RampMovement")
	float RampSplineMoveSpeedAccelerationMultiplier = 0.3;


	// How much gravity we have by default
	UPROPERTY(Category = "Car")
	float GravityAmount = 3600.0;

	// How fast the car rotatets in yaw
	UPROPERTY(Category = "Car")
	float YawRotationSpeed = 4.1;

	// How fast the car rotatets in pitch
	UPROPERTY(Category = "Car")
	float PitchRotationSpeed = 4.1; //3f;

	UPROPERTY(Category = "Car")
	float ReturnToIdleRotationSpeed = 5.0;

	/* How much extra we turn the mesh, making it turn "ahead" of the movement direction. 
	 * == 0; nothing
	 * == 'x'; addes the input rotation amount, 'x' amount of times
	*/
	UPROPERTY(Category = "Car")
	float FakeMeshRotationAmount = 1.0;


	UPROPERTY(Category = "CarMeshRotation")
	FFlyingCarAxisRotation YawMeshRotation;

	UPROPERTY(Category = "CarMeshRotation")
	FFlyingCarAxisRotation PitchMeshRotation;

	UPROPERTY(Category = "CarMeshRotation")
	FFlyingCarAxisRotation RollMeshRotation;
}

/**
 * Settings for the driver camera
 * (They used to be composable settings but no longer)
 */
class USkylineFylingCarPilotCameraComposableSettings : UDataAsset
{
	/** How much the camera should lerp between the car and the center of the spline on the horizonal plane
	 * 0; stay at the spline center. 1, follow the car
	 */
	UPROPERTY(Category = "Spline Movement")
	float HorizontalFollowCarPercentage = 1.0;

	/** How much the camera should lerp between the car and the center of the spline on the vertical plane
	 * 0; stay at the spline center. 1, follow the car
	 */
	UPROPERTY(Category = "Spline Movement")
	float VerticalFollowCarPercentage = 1.0;

	/** Modify the FollowCarPercentage depending on how far we are away from the spline center.
	 * Time is the current distance percentage (0->1) where 0 is at the highway center. The value is the new current percentage.
	 * 0; stay at the spline center. 1, follow the car
	 */
	UPROPERTY(Category = "Spline Movement")
	FRuntimeFloatCurve FollowCarPercentageModifierFromSplineCenter;

	// How much of the wanted look ahead we use (0 -> 1)
	UPROPERTY(Category = "Spline Camera")
	float LookAheadAlpha = 0.0;

	// The point on the spline the camera should look at
	UPROPERTY(Category = "Spline Camera", meta = (EditCondition = "LookAheadAlpha > 0", EditConditionHides))
	float TargetLookAtLocationLookAheadDistance = 100.0;

	/** How fast we force the camera into the straight ahead direction.
	 * Stronger value also meens less look to the sides
	 */
	UPROPERTY(Category = "Spline Camera", meta = (EditCondition = "LookAheadAlpha > 0", EditConditionHides))
	float ForceCameraLookDirectionSpeed = 5.0;

	// Offset the "Straight ahead" direction for the camera
	UPROPERTY(Category = "Spline Camera")
	float TargetPitchOffset = -0.5;
};

struct FSkylineFlyingCarSplineParams
{
	ASkylineFlyingHighway HighWay;
	FSplinePosition SplinePosition;
	float SplineCenterDistance;
	float SplineHorizontalDistanceAlphaUnclamped;
	float SplineVerticalDistanceAlphaUnclamped;
	FVector DirToSpline;
	bool bHasReachedEndOfSpline;
}

enum ESkylineFlyingCarMovementMode
{
	Spline,
	Tunnel,
	Free,
}

enum ESkylineFlyingCarCollisionType
{
	Bounce,
	TotalLoss
}

USTRUCT()
struct FSkylineFlyingCarCollision
{
	UPROPERTY()
	ESkylineFlyingCarCollisionType Type;

	UPROPERTY()
	FHitResult HitResult;

	// -1: Left
	// 0: Front/Rear/Up/Down
	// 1: Right
	UPROPERTY()
	float Direction = 0.0;
}

struct FSkylineFlyingCarGunHit
{
	float Damage;

	FVector WorldImpactLocation;
	FVector WorldImpactNormal;

	bool bControlSide;
}


UENUM()
enum EFlyingCarMeshAxisRotationType
{
	Interpolation,
	Spring
}

// Used to describe per-axis mesh rotation
struct FFlyingCarAxisRotation
{
	UPROPERTY()
	float MaxAngle = 20.0;

	UPROPERTY()
	EFlyingCarMeshAxisRotationType Type = EFlyingCarMeshAxisRotationType::Interpolation;


	// Used when user is giving input
	UPROPERTY(Meta = (EditCondition = "Type == EFlyingCarMeshAxisRotationType::Interpolation", EditConditionHides))
	float AccelerationSpeed = 10.0;

	// Used when no stick input is given
	UPROPERTY(Meta = (EditCondition = "Type == EFlyingCarMeshAxisRotationType::Interpolation", EditConditionHides))
	float DecelerationSpeed = 5.0;


	UPROPERTY(Meta = (EditCondition = "Type == EFlyingCarMeshAxisRotationType::Spring", EditConditionHides))
	float Stiffness = 50.0;

	UPROPERTY(Meta = (EditCondition = "Type == EFlyingCarMeshAxisRotationType::Spring", EditConditionHides))
	float Damping = 0.5;


	FHazeAcceleratedFloat AcceleratedAngle;


	float UpdateAngle(float AxisInput, float DeltaTime)
	{
		float TargetAngle = MaxAngle * AxisInput;

		if (Type == EFlyingCarMeshAxisRotationType::Interpolation)
		{
			float Alpha = Math::Abs(AxisInput);
			float InterpSpeed = Math::Lerp(DecelerationSpeed, AccelerationSpeed, Math::Saturate(Alpha));
			AcceleratedAngle.SnapTo(Math::FInterpTo(AcceleratedAngle.Value, TargetAngle, DeltaTime, InterpSpeed));
		}

		if (Type == EFlyingCarMeshAxisRotationType::Spring)
		{
			AcceleratedAngle.SpringTo(TargetAngle, Stiffness, Damping, DeltaTime);
		}

		return AcceleratedAngle.Value;
	}

	float GetAngle() const
	{
		return AcceleratedAngle.Value;
	}
}
