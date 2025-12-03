
/**
 *
 */
class USweepingMovementData : UBaseMovementData
{
	access Protected = protected, USweepingMovementResolver (inherited), AddMovementResolvedData;

	default DefaultResolverType = USweepingMovementResolver;

	access:Protected
	bool bAllowSubStep = true;

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
	bool bConsiderLandingOnUnstableEdgeAsUnwalkableGround = true;

	access:Protected
	FMovementAlignWithImpactSettings AlignWithImpactSettings;

	access:Protected
	float MaxEdgeDistanceUntilUnstable = -1;

	access:Protected
	EMovementEdgeHandlingType EdgeHandling = EMovementEdgeHandlingType::None;

	access:Protected
	EMovementEdgeNormalRedirectType EdgeRedirectType = EMovementEdgeNormalRedirectType::None;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp = FVector::ZeroVector) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		auto Settings = UMovementSweepingSettings::GetSettings(MovementComponent.HazeOwner);

		// Substepping by default its not allowed on the remote
		bAllowSubStep = MovementComponent.HasMovementControl();

		bCanPerformGroundTrace = true;

		bRedirectMovementOnGroundImpacts = Settings.bRedirectMovementOnGroundImpacts;
		bRedirectMovementOnWallImpacts = Settings.bRedirectMovementOnWallImpacts;
		bRedirectMovementOnCeilingImpacts = Settings.bRedirectMovementOnCeilingImpacts;
		BonusGroundedTraceDistanceWhileGrounded = Math::Max(Settings.RemainOnGroundMinTraceDistance.Get(ShapeSizeForMovement), 0);
		bConsiderLandingOnUnstableEdgeAsUnwalkableGround = Settings.bConsiderLandingOnUnstableEdgeAsUnwalkableGround;
		AlignWithImpactSettings = MovementComponent.GetImpactAlignmentSettings();
		MaxEdgeDistanceUntilUnstable = -1;

		EdgeHandling = EMovementEdgeHandlingType::None;
		if(MovementComponent.ShouldFollowEdges())
			EdgeHandling = EMovementEdgeHandlingType::Follow;
		else if(Settings.bPerformEdgeDetection)
			EdgeHandling = EMovementEdgeHandlingType::Leave;

		EdgeRedirectType = Settings.EdgeRedirectType;
		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		auto Other = Cast<USweepingMovementData>(OtherBase);

		bAllowSubStep = Other.bAllowSubStep;

		bCanPerformGroundTrace = Other.bCanPerformGroundTrace;

		bRedirectMovementOnGroundImpacts = Other.bRedirectMovementOnGroundImpacts;
		bRedirectMovementOnWallImpacts = Other.bRedirectMovementOnWallImpacts;
		bRedirectMovementOnCeilingImpacts = Other.bRedirectMovementOnCeilingImpacts;
		BonusGroundedTraceDistanceWhileGrounded = Other.BonusGroundedTraceDistanceWhileGrounded;
		bConsiderLandingOnUnstableEdgeAsUnwalkableGround = Other.bConsiderLandingOnUnstableEdgeAsUnwalkableGround;
		AlignWithImpactSettings = Other.AlignWithImpactSettings;
		MaxEdgeDistanceUntilUnstable = Other.MaxEdgeDistanceUntilUnstable;
		
		EdgeHandling = Other.EdgeHandling;
		EdgeRedirectType = Other.EdgeRedirectType;
	}
#endif

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
		bRedirectMovementOnGroundImpacts = false;
		bRedirectMovementOnWallImpacts = false;
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

	/**
	 * This will make the edges become unstable at a longer distance if we are moving towards the edges
	 */
	void ApplyUnstableEdgeDistance(FMovementSettingsValue Amount)
	{	
		// This requires edge handling
		if(EdgeHandling == EMovementEdgeHandlingType::None)
			EdgeHandling = EMovementEdgeHandlingType::Leave;

		MaxEdgeDistanceUntilUnstable = Math::Max(Amount.Get(ShapeSizeForMovement), 1);
	}

	/**
	 * This will make the edges become unstable at a longer distance if we are moving towards the edges 
	 * @param OverrideRedirect Override the default settings type
	 */
	void ApplyUnstableEdgeDistance(FMovementSettingsValue Amount, EMovementEdgeNormalRedirectType OverrideRedirect)
	{
		ApplyUnstableEdgeDistance(Amount);
		EdgeRedirectType = OverrideRedirect;
	}
}
