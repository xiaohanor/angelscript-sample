enum EFloatingMovementValidateMethod
{
	   /**
        * Move the origin up for the first iteration, then sweep as usual.
        * Fails if the capsule is penetrating.
        * Issues:
        * - Prevents the character from walking under slopes surfaces, as if they were much taller than they are.
        */
       NoValidation,

       /**
        * Do an overlap check at the stepped up location, and if there's no hits, sweep forward.
        * Issues:
        * - Requires an extra overlap.
        * - Prevents the character from walking under slopes surfaces, as if they were much taller than they are.
        */
       ValidateOverlap,

	   /**
        * Sweep up from the current location to find a ceiling, and then sweep forward from that ceiling.
        * Issues:
        * - Requires an extra sweep.
        * - Prevents the character from walking under slopes surfaces, as if they were much taller than they are.
        */
       ValidateSweep,
};

/**
 * How do we decide what direction to move up/down in while floating?
 */
enum EFloatingMovementFloatingDirection
{
	/**
	 * Always use the current WorldUp
	 */
	WorldUp,

	/**
	 * Use the ground normal if we are on ground.
	 * If we are not on ground, we fall back to the current WorldUp.
	 */
	Normal,

	/**
	 * Use the ground impact normal if we are on ground.
	 * If we are not on ground, we fall back to the current WorldUp.
	 */
	ImpactNormal,

	/**
	 * Use the current actor rotation up.
	 */
	ActorUp,

	/**
	 * Opposite direction to the gravity direction.
	 */
	GravityUp,

	/**
	 * Explicitly set the direction with ExplicitFloatingDirection on UMovementFloatingSettings.
	 */
	Explicit,
};

/**
 * Floating Movement is very similar to Sweeping Movement, but has the added feature that the collider will sweep slightly above the ground, instead of along it.
 * This helps prevent colliding with small edges on the ground, while not forcing you to use the full SteppingMovement.
 * Note that this does limit the movement along the floor to be more simple, since we will mostly be moving above it.
 */
class UMovementFloatingSettings : UHazeComposableSettings
{
	/**
	 * How do we want to validate that the sweep location is actually valid?
	 */
	UPROPERTY()
	EFloatingMovementValidateMethod ValidationMethod = EFloatingMovementValidateMethod::NoValidation;

	/**
	 * How far we want to move up while floating
	 */
	UPROPERTY()
	FMovementSettingsValue FloatingHeight = FMovementSettingsValue::MakeValue(50);

	/**
	 * How do we decide what direction to move up/down in while floating?
	 */
	UPROPERTY()
	EFloatingMovementFloatingDirection FloatingDirection = EFloatingMovementFloatingDirection::WorldUp;

	/**
	 * If FloatingDirection is set to EFloatingMovementFloatingDirection::Explicit, we use this vector.
	 */
	UPROPERTY()
	FVector ExplicitFloatingDirection = FVector::UpVector;

	/**
	 * Should we make the bottom of our capsule flat during ground traces?
	 * Only works when using a Capsule or Sphere shape.
	 */
	UPROPERTY()
	bool bFlatCapsuleBottom = false;

	/**
	 * If enabled, moving into the ground will be redirected, else, all movement will be stopped and the velocity zeroed out
	 */
	UPROPERTY()
	bool bRedirectMovementOnGroundImpacts = true;

	/**
	 * If enabled, moving into a wall will be redirected, else, all movement will be stopped and the velocity zeroed out
	 */
	UPROPERTY()
	bool bRedirectMovementOnWallImpacts = true;

	/**
	 * If enabled, moving into the ceiling will be redirected, else, all movement will be stopped and the velocity zeroed out
	 */
	UPROPERTY()
	bool bRedirectMovementOnCeilingImpacts = true;

	/** If the actor is grounded, we can use this to probe for the ground with a longer distance making the actor 'sticky' with the ground. */
	UPROPERTY()
	FMovementSettingsValue RemainOnGroundMinTraceDistance = FMovementSettingsValue::MakeDisabled();

	/** This will detect if we are moving on edges
	 * making it possible to create more accurate moves
	 * Comes with a heavy performance cost
	 */
	UPROPERTY()
	bool bPerformEdgeDetection = false;
}