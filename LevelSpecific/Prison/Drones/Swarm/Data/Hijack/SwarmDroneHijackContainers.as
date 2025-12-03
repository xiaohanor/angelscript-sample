
USTRUCT()
struct FSwarmHijackTargetableSettings
{
	UPROPERTY(DisplayName = "Range")
	float AimRange = 500.0;

	UPROPERTY()
	float MaxActivationAngle = 50.0;

	UPROPERTY()
	float CameraDistanceFromPanel = 200.0;

	UPROPERTY()
	float HijackDelayAfterDive = 0.3;
}

USTRUCT()
struct FSwarmDroneHijackParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}


// Let's just do rectangle
struct FSwarmDroneHijackTargetRectangle
{
	FVector WorldOrigin;
	FVector PlaneNormal;
	FVector2D Size;
};

/* ==========================
** Movement hijack stuff
* =========================== */

USTRUCT()
struct FSwarmDroneGroundMovementHijackSettings
{
	UPROPERTY()
	float MaxSpeed = 500.0;

	// How fast we reach max peed
	UPROPERTY()
	float Acceleration = 800.0;

	UPROPERTY()
	float Deceleration = 2000.0;

	UPROPERTY()
	bool bShouldRotateWithVelocity;

	UPROPERTY(Meta = (EditCondition = "bShouldRotateWithVelocity"))
	float RotationSpeed = 20.0;
	
}

enum ESwarmDroneMovementHijackInputType
{
	ButtonMash,
	StickSpin,
	MovementStick
}

enum ESwarmDroneSimpleMovementHijackInput
{
	CameraRelative,
	RawStick
}

enum ESwarmDroneSimpleMovementHijackType
{
	AxisConstrained,
	SplineConstrained
}

USTRUCT()
struct FSwarmDroneSimpleMovementHijackSettings
{
	UPROPERTY()
	ESwarmDroneSimpleMovementHijackType HijackType;

	UPROPERTY(Meta = (EditCondition = "HijackType == ESwarmDroneSimpleMovementHijackType::AxisConstrained", EditConditionHides))
	FSwarmDroneAxisConstrainedMovementHijackSettings AxisConstrainedSettings;

	UPROPERTY(Meta = (EditCondition = "HijackType == ESwarmDroneSimpleMovementHijackType::SplineConstrained", EditConditionHides))
	FSwarmDroneSplineConstrainedMovementHijackSettings SplineConstrainedSettings;


	UPROPERTY()
	ESwarmDroneSimpleMovementHijackInput InputType;


	UPROPERTY()
	float MaxSpeed = 500.0;

	// How fast until we reach max speed
	UPROPERTY()
	float Acceleration = 50.0;

	// How fast we will come to a full stop
	UPROPERTY()
	float Deceleration = 300.0;
}


/* --------------------------
** Axis constrained settings
 * ------------------------- */
enum ESwarmDroneAxisConstrainedMovementHijackType
{
	X,
	Y,
	Z
}

USTRUCT()
struct FSwarmDroneAxisConstrainedMovementHijackSettings
{
	UPROPERTY()
	ESwarmDroneAxisConstrainedMovementHijackType AxisConstrainType;

	UPROPERTY(Meta = (ClampMax = 0.0))
	float NegativeBound;

	UPROPERTY(Meta = (ClampMin = 0.0))
	float PositiveBound;

	FVector GetConstraintVector() const
	{
		switch (AxisConstrainType)
		{
			case ESwarmDroneAxisConstrainedMovementHijackType::X:
				return FVector::ForwardVector;

			case ESwarmDroneAxisConstrainedMovementHijackType::Y:
				return FVector::RightVector;

			case ESwarmDroneAxisConstrainedMovementHijackType::Z:
				return FVector::UpVector;
		}
	}

	void GetWorldBounds(const USceneComponent Origin, FVector& WorldNegativeBound, FVector& WorldPositiveBound) const
	{
		FVector ParentScale = Origin.AttachParent != nullptr ? Origin.AttachParent.GetWorldScale() : Origin.Owner.GetActorScale3D();
		FVector Scale = Origin.WorldScale / ParentScale;

		FVector ConstrainedDirection = GetConstraintVector();
		FVector LocalNegativeLocation = Origin.RelativeLocation + ConstrainedDirection * NegativeBound;
		FVector LocalPositiveLocation = Origin.RelativeLocation + ConstrainedDirection * PositiveBound;

		// WorldNegativeBound = Origin.WorldTransform.TransformPosition(LocalNegativeLocation) * Scale;
		// WorldPositiveBound = Origin.WorldTransform.TransformPosition(LocalPositiveLocation) * Scale;

		WorldNegativeBound = LocalNegativeLocation;
		WorldPositiveBound = LocalPositiveLocation;
	}
}

/* --------------------------
** Spline constrained settings
 * ------------------------- */
USTRUCT()
struct FSwarmDroneSplineConstrainedMovementHijackSettings
{
	UPROPERTY(Meta = (UseComponentPicker, AllowAnyActor, AllowedClasses = "/Script/Angelscript.HazeSplineComponent"))
	FComponentReference SplineComponentReference;
}

/* --------------------------
** Movement hijack sheets
 * ------------------------- */
namespace SwarmDroneMovementHijackSheets
{
	asset SimpleMovement of UHazeCapabilitySheet
	{
		AddCapability(n"SwarmDroneAxisConstrainedMovementHijackCapability");
		AddCapability(n"SwarmDroneSplineConstrainedMovementHijackCapability");
	};

	asset GroundMovement of UHazeCapabilitySheet
	{
		AddCapability(n"SwarmDroneGroundMovementHijackCapability");
	};
}

/* ==========================
** Effect event handler stuff
* =========================== */
USTRUCT()
struct FSwarmDroneHijackDiveParams
{
	UPROPERTY()
	float DiveDuration = 0.0;

	UPROPERTY()
	float BlendTime = 0.0;
}