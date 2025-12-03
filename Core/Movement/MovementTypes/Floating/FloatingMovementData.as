/**
 * EXPERIMENTAL: Might be merged into SweepingMovement in the future.
 * Floating Movement is very similar to Sweeping Movement, but has the added feature that the collider will sweep slightly above the ground, instead of along it.
 * This helps prevent colliding with small edges on the ground, while not forcing you to use the full SteppingMovement.
 */
class UFloatingMovementData : UBaseMovementData
{
	access Protected = protected, UFloatingMovementResolver (inherited), AddMovementResolvedData;

	default DefaultResolverType = UFloatingMovementResolver;

	access:Protected
	EFloatingMovementValidateMethod ValidationMethod;

	access:Protected
	float FloatingHeight = 0;

	access:Protected
	EFloatingMovementFloatingDirection FloatingDirection = EFloatingMovementFloatingDirection::WorldUp;

	access:Protected
	FVector ExplicitFloatingDirection = FVector::UpVector;

	access:Protected
	bool bFlatCapsuleBottom = false;

	access:Protected
	bool bAllowSubStep = false;

	access:Protected
	bool bCanPerformGroundTrace = true;

	access:Protected
	bool bRedirectMovementOnGroundImpacts = true;

	access:Protected
	bool bRedirectMovementOnWallImpacts = true;

	access:Protected
	bool bRedirectMovementOnCeilingImpacts = true;

	access:Protected
	float BonusGroundedTraceDistanceWhileGrounded = 0;

	access:Protected
	FMovementAlignWithImpactSettings AlignWithImpactSettings;

	access:Protected
	EMovementEdgeHandlingType EdgeHandling = EMovementEdgeHandlingType::None;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp = FVector::ZeroVector) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		auto Settings = UMovementFloatingSettings::GetSettings(MovementComponent.HazeOwner);

		ValidationMethod = Settings.ValidationMethod;
		FloatingHeight = Settings.FloatingHeight.Get(ShapeSizeForMovement);
		FloatingDirection = Settings.FloatingDirection;
		ExplicitFloatingDirection = Settings.ExplicitFloatingDirection;
		bFlatCapsuleBottom = Settings.bFlatCapsuleBottom;

		// Substepping by default its not allowed on the remote
		bAllowSubStep = MovementComponent.HasMovementControl();
		bCanPerformGroundTrace = true;
		bRedirectMovementOnGroundImpacts = Settings.bRedirectMovementOnGroundImpacts;
		bRedirectMovementOnWallImpacts = Settings.bRedirectMovementOnWallImpacts;
		bRedirectMovementOnCeilingImpacts = Settings.bRedirectMovementOnCeilingImpacts;
		BonusGroundedTraceDistanceWhileGrounded = Math::Max(Settings.RemainOnGroundMinTraceDistance.Get(ShapeSizeForMovement), 0);
		AlignWithImpactSettings = MovementComponent.GetImpactAlignmentSettings();

		EdgeHandling = EMovementEdgeHandlingType::None;
		if(MovementComponent.ShouldFollowEdges())
			EdgeHandling = EMovementEdgeHandlingType::Follow;
		else if(Settings.bPerformEdgeDetection)
			EdgeHandling = EMovementEdgeHandlingType::Leave;

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		auto Other = Cast<UFloatingMovementData>(OtherBase);

		ValidationMethod = Other.ValidationMethod;
		FloatingHeight = Other.FloatingHeight;
		FloatingDirection = Other.FloatingDirection;
		ExplicitFloatingDirection = Other.ExplicitFloatingDirection;
		bFlatCapsuleBottom = Other.bFlatCapsuleBottom;

		bAllowSubStep = Other.bAllowSubStep;
		bCanPerformGroundTrace = Other.bCanPerformGroundTrace;
		bRedirectMovementOnGroundImpacts = Other.bRedirectMovementOnGroundImpacts;
		bRedirectMovementOnWallImpacts = Other.bRedirectMovementOnWallImpacts;
		bRedirectMovementOnCeilingImpacts = Other.bRedirectMovementOnCeilingImpacts;
		BonusGroundedTraceDistanceWhileGrounded = Other.BonusGroundedTraceDistanceWhileGrounded;
		AlignWithImpactSettings = Other.AlignWithImpactSettings;
		EdgeHandling = Other.EdgeHandling;
	}
#endif

	/**
	 * How do we want to validate that the sweep location is actually valid?
	 */
	void ApplyFloatingValidationMethodThisFrame(EFloatingMovementValidateMethod InValidationMethod)
	{
		ValidationMethod = InValidationMethod;
	}

	/**
	 * How far we want to move up while floating
	 */
	void ApplyFloatingHeightThisFrame(float InFloatingHeight)
	{
		FloatingHeight = InFloatingHeight;
	}

	/**
	 * How do we decide what direction to move up/down in while floating?
	 */
	void ApplyFloatingDirectionThisFrame(EFloatingMovementFloatingDirection InFloatingDirection)
	{
		FloatingDirection = InFloatingDirection;
	}

	void ApplyExplicitFloatingDirectionThisFrame(FVector InFloatingDirection)
	{
		FloatingDirection = EFloatingMovementFloatingDirection::Explicit;
		ExplicitFloatingDirection = InFloatingDirection;
	}

	/**
	 * EXPERIMENTAL: Apply extra tracing distance to fake a flat capsule bottom.
	 */
	void ApplyFlatCapsuleBottomThisFrame(bool bInFlatCapsuleBottom)
	{
		bFlatCapsuleBottom = bInFlatCapsuleBottom;
	}

	/**
	 * Add a velocity only along the horizontal plane determined by WorldUp.
	 */
	void AddHorizontalVelocity(FVector Velocity)
	{
		check(IsValid());
		check(!Velocity.ContainsNaN());

		const FMovementDelta DeltaToAdd(GetDeltaFromVelocityInternal(Velocity), Velocity);
		AddHorizontalInternal(DeltaToAdd.GetHorizontalPart(WorldUp), true);
	}

	/**
	 * Add an acceleration only along the horizontal plane determined by WorldUp.
	 */
	void AddHorizontalAcceleration(FVector Acceleration)
	{
		check(IsValid());
		check(!Acceleration.ContainsNaN());

		const FMovementDelta DeltaToAdd(GetDeltaFromAcceleration(Acceleration), GetVelocityFromAcceleration(Acceleration));
		AddHorizontalInternal(DeltaToAdd.GetHorizontalPart(WorldUp), true);
	}

	/**
	 * Add a velocity only along the vertical direction determined by WorldUp.
	 */
	void AddVerticalVelocity(FVector Velocity)
	{
		check(IsValid());
		check(!Velocity.ContainsNaN());

		const FMovementDelta DeltaToAdd(GetDeltaFromVelocityInternal(Velocity), Velocity);
		AddVerticalInternal(DeltaToAdd.GetVerticalPart(WorldUp), true);
	}

	/**
	 * Add an acceleration only along the vertical direction determined by WorldUp.
	 */
	void AddVerticalAcceleration(FVector Acceleration)
	{
		check(IsValid());
		check(!Acceleration.ContainsNaN());

		const FMovementDelta DeltaToAdd(GetDeltaFromAcceleration(Acceleration), GetVelocityFromAcceleration(Acceleration));
		AddVerticalInternal(DeltaToAdd.GetVerticalPart(WorldUp), true);
	}

	/** The actor will become airborne this frame 
	 * Any ground impacts are considered to be wall impacts
	 * and the redirects are handled as if they where walls
	*/
	void BlockGroundTracingForThisFrame()
	{
		bCanPerformGroundTrace = false;
		WalkableSlopeAngle = -1;
	}

	/** No redirects will happen on impact. The actor will stop if we get an impact and get zero velocity */
	void BlockRedirectsForThisFrame()
	{
		BlockGroundRedirectsThisFrame();
		BlockWallRedirectsThisFrame();
		BlockCeilingRedirectsThisFrame();
	}

	void BlockGroundRedirectsThisFrame()
	{
		bRedirectMovementOnGroundImpacts = false;
	}

	void BlockWallRedirectsThisFrame()
	{
		bRedirectMovementOnWallImpacts = false;
	}

	void BlockCeilingRedirectsThisFrame()
	{
		bRedirectMovementOnCeilingImpacts = false;
	}

	/** If the actor is grounded, this amount will be added to the ground trace distance
	 * making the actor more sticky to the ground
	 */
	void UseGroundStickynessDistanceThisFrame(float Amount)
	{
		devCheck(bCanPerformGroundTrace, "UseGroundStickynessDistanceThisFrame can't be used when 'BlockGroundTracingForThisFrame' has been called");
		BonusGroundedTraceDistanceWhileGrounded = Amount;
	}

	/** If the actor is grounded, this will make the actor stick to the ground a lot more.
	 * Otherwise, when going up edges, we usually take of from them.
	 */
	void UseGroundStickynessThisFrame()
	{
		devCheck(bCanPerformGroundTrace, "UseGroundStickynessDistanceThisFrame can't be used when 'BlockGroundTracingForThisFrame' has been called");
		BonusGroundedTraceDistanceWhileGrounded = ShapeSizeForMovement;
	}

	/**
	 * This will make the movement smoothly round over edges, and move along the other surface
	 */
	void FollowSurfaceOverEdgesThisFrame()
	{
		EdgeHandling = EMovementEdgeHandlingType::Follow;
	}
}
