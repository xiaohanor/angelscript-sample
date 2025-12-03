
/**
 * 
 */
class UMovementGravitySettings : UHazeComposableSettings
{
	// If true; the worlds global gravity settings will be used
	UPROPERTY()
	bool bUseWorldSettingsGravity = false;

	// The amount of gravity we should have
	UPROPERTY(meta=(ClampMin="0.0", EditCondition = "!bUseWorldSettingsGravity"))
	float GravityAmount = 980.0;

	// Scale of gravity used by the movement
	UPROPERTY(meta=(ClampMin="0.0"))
	float GravityScale = 1.0;

	// Maximum speed you can fall, use < 0 to dont clamp it
	UPROPERTY(meta=(ClampMin="-1.0"))
	float TerminalVelocity = -1.0;
}


/**
 * 
 */
class UMovementStandardSettings : UHazeComposableSettings
{
	// the default setting for being able to walk on a surface
	UPROPERTY()
	float WalkableSlopeAngle = 60.0;

	/**
	 * By default, WorldUp is used to find ground. However, in some instances it might be nice
	 * to also use the ActorUp, and if either of them align enough with a hit to find ground, it is ground.
	 * For example, a vehicle with WorldUp pointing straight down to fall downwards, but is still tilted from driving
	 * up a wall might want to find a wall with their actor up.
	 */
	UPROPERTY()
	bool bAlsoUseActorUpForWalkableSlopeAngle = false;

	UPROPERTY()
	bool bForceAllGroundUnwalkable = false;

	// The default angle for an impact to count as ceiling
	UPROPERTY(meta=(ClampMax="0.0"))
	float CeilingAngle = -20.0;

	/**
	 * When we are determining if an impact is an edge or not, we usually trace for the edge normals.
	 * But if the moving shape impacts in such a way that the impact normal and normal are misaligned, we
	 * can presume that we are impacting an edge, because that's the only way we can get an impact like that.
	 * This can be more reliable than tracing, since tracing can't find very small outcrops due to error margins.
	 * We currently use the walkable slope angle as a good default for how misaligned they need to be.
	 */
	UPROPERTY()
	bool bConsiderImpactEdgeIfNormalsAngleHigherThanWalkableSlopeAngle = true;

	/**
	 * When do we want to apply a follow to our current ground after applying movement.
	 * This follow will automatically be cleared the next frame.
	 * NOTE: Still requires follow to be enabled on the movement component.
	 */
	UPROPERTY()
	EMovementAutoFollowGroundType AutoFollowGround = EMovementAutoFollowGroundType::Never;
}

/**
 * 
 */
class UMovementResolverSettings : UHazeComposableSettings
{
	/** How many redirects can when colliding with something can we perform */ 
	UPROPERTY()
	int MaxRedirectIterations = 3;

	/** How many depenetration attempts can we perform */ 
	UPROPERTY()
	int MaxDepenetrationIterations = 1;
}


/** */
enum EMovementSettingsValueType
{
	// Not used
	Disabled,

	// Use the value
	Value,

	// Use a percentage of the collision shape size
	CollisionShapePercentage
}

/** 
 * A data type that can be either a value or a percentage change of the shape size used for movement.
 * @see FMovementSettingsValue::MakeValue()
 * @see FMovementSettingsValue::MakePercentage()
 * @see FMovementSettingsValue::MakeDisabled()
*/
struct FMovementSettingsValue
{
	UPROPERTY()
	EMovementSettingsValueType Type = EMovementSettingsValueType::Value;
	
	UPROPERTY(meta = (EditCondition="Type != EMovementStepSizeType::Disabled", EditConditionHides, ClampMin="0.0"))
	float Value = 0;

	void SetPercentage(float InPercentage)
	{
		Type = EMovementSettingsValueType::CollisionShapePercentage;
		Value = InPercentage;
	}

	void SetValue(float InValue)
	{
		Type = EMovementSettingsValueType::Value;
		Value = InValue;
	}

	void Disable()
	{
		Type = EMovementSettingsValueType::Disabled;
	}

	bool IsDisabled() const
	{
		return Type == EMovementSettingsValueType::Disabled;
	}

	float Get(float ShapeSize) const
	{
		if(Type == EMovementSettingsValueType::Disabled)
		{
			return 0;
		}
		else if(Type == EMovementSettingsValueType::CollisionShapePercentage)
		{
			return Value * ShapeSize;
		}
		else
		{
			return Value;
		}
	}
}

namespace FMovementSettingsValue
{
	/**
	 * Percentage of the Shape Size in range 0.0 -> 1.0.
	 * Can be > 1, but results may vary.
	 */
	FMovementSettingsValue MakePercentage(float Value)
	{
		FMovementSettingsValue Out;
		Out.SetPercentage(Value);
		return Out;
	}

	FMovementSettingsValue MakeValue(float Value)
	{
		FMovementSettingsValue Out;
		Out.SetValue(Value);
		return Out;
	}

	FMovementSettingsValue MakeDisabled()
	{
		FMovementSettingsValue Out;
		Out.Type = EMovementSettingsValueType::Disabled;
		return Out;
	}
}

enum EMovementFollowEnabledStatus
{
	FollowDisabled,
	FollowEnabled,
	OnlyFollowReferenceFrame,
}