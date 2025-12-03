/** 
 * 
*/
class USteppingMovementData : UBaseMovementData
{
	access Protected = protected, USteppingMovementResolver (inherited), AddMovementResolvedData;

	default DefaultResolverType = USteppingMovementResolver;

	access:Protected
	bool bAllowSubStep = true;

	access:Protected
	bool bSweepStep = true;

	access:Protected
	float StepUpSize = 0;

	access:Protected
	float StepDownOnGroundSize = 0;

	access:Protected
	float StepDownInAirSize = 0;

	access:Protected
	bool bCanTriggerStepUpOnUnwalkableSurface = false;

	access:Protected
	bool bRedirectMovementOnWallImpacts = true;

	access:Protected
	EMovementEdgeHandlingType EdgeHandling = EMovementEdgeHandlingType::None;

	access:Protected
	EMovementEdgeNormalRedirectType EdgeRedirectType = EMovementEdgeNormalRedirectType::None;

	access:Protected
	ESteppingMovementBottomOfCapsuleMode BottomOfCapsuleMode = ESteppingMovementBottomOfCapsuleMode::Flat;

	access:Protected
	bool bOnlyFlatBottomOfCapsuleIfLeavingEdge = false;

	access:Protected
	ESteppingWalkOnUnstableEdgeHandling WalkOnUnstableEdgeHandling = ESteppingWalkOnUnstableEdgeHandling::Ignored;

	access:Protected
	ESteppingLandOnUnstableEdgeHandling LandOnUnstableEdgeHandling = ESteppingLandOnUnstableEdgeHandling::Adjust;

	access:Protected
	bool bProjectVelocityOnGroundNormalOnLanding = false;

	access:Protected
	FMovementAlignWithImpactSettings AlignWithImpactSettings;

	access:Protected
	float MaxEdgeDistanceUntilUnstable = -1;

	access:Protected
	FHitResult OverrideFinalGroundContact;

	access:Protected
	EMovementOverrideFinalGroundType OverrideFinalGroundContactType = EMovementOverrideFinalGroundType::None;

	access:Protected
	bool bGenerateInitialGroundedStateFirstIteration = false;

	access:Protected
	bool bWasStuckLastFrame = false;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp = FVector::ZeroVector) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		// Extra delta types that can be added
		DeltaStates.Init(EMovementIterationDeltaStateType::Horizontal, WorldUp);

		// Substepping by default its not allowed on the remote
		bAllowSubStep = MovementComponent.HasMovementControl();

		const auto Settings = UMovementSteppingSettings::GetSettings(MovementComponent.HazeOwner);
		bSweepStep = Settings.bSweepStep;
		StepUpSize = Settings.StepUpSize.Get(ShapeSizeForMovement);
		StepDownOnGroundSize = Settings.StepDownSize.Get(ShapeSizeForMovement);
		StepDownInAirSize = Settings.StepDownInAirSize.Get(ShapeSizeForMovement);
		bCanTriggerStepUpOnUnwalkableSurface = Settings.bCanTriggerStepUpOnUnwalkableSurface;
		bRedirectMovementOnWallImpacts = Settings.bRedirectMovementOnWallImpacts;

		EdgeHandling = EMovementEdgeHandlingType::None;
		if(MovementComponent.ShouldFollowEdges())
			EdgeHandling = EMovementEdgeHandlingType::Follow;
		else if(Settings.bPerformEdgeDetection)
			EdgeHandling = EMovementEdgeHandlingType::Leave;
		else if(Settings.BottomOfCapsuleMode != ESteppingMovementBottomOfCapsuleMode::Rounded)
			EdgeHandling = EMovementEdgeHandlingType::Leave;

		EdgeRedirectType = Settings.EdgeRedirectType;
		
		BottomOfCapsuleMode = Settings.BottomOfCapsuleMode;
		bOnlyFlatBottomOfCapsuleIfLeavingEdge = Settings.bOnlyFlatBottomOfCapsuleIfLeavingEdge;

		WalkOnUnstableEdgeHandling = Settings.WalkOnUnstableEdgeHandling;
		LandOnUnstableEdgeHandling = Settings.LandOnUnstableEdgeHandling;
		bProjectVelocityOnGroundNormalOnLanding = false;

		AlignWithImpactSettings = MovementComponent.GetImpactAlignmentSettings();

		if(Settings.bForceAllEdgesAreUnstable)
			MaxEdgeDistanceUntilUnstable = 0;
		else
			MaxEdgeDistanceUntilUnstable = -1;

		OverrideFinalGroundContact = FHitResult();
		OverrideFinalGroundContactType = EMovementOverrideFinalGroundType::None;
		bGenerateInitialGroundedStateFirstIteration = !MovementComponent.bHasPerformedAnyMovementSinceReset;

		bWasStuckLastFrame = MovementComponent.LastStuckFrame >= Time::FrameNumber - 1;

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		auto Other = Cast<USteppingMovementData>(OtherBase);

		bAllowSubStep = Other.bAllowSubStep;

		bSweepStep = Other.bSweepStep;
		StepUpSize = Other.StepUpSize;
		StepDownOnGroundSize = Other.StepDownOnGroundSize;
		StepDownInAirSize = Other.StepDownInAirSize;
		bCanTriggerStepUpOnUnwalkableSurface = Other.bCanTriggerStepUpOnUnwalkableSurface;
		bRedirectMovementOnWallImpacts = Other.bRedirectMovementOnWallImpacts;

		EdgeHandling = Other.EdgeHandling;
		EdgeRedirectType = Other.EdgeRedirectType;
		BottomOfCapsuleMode = Other.BottomOfCapsuleMode;
		bOnlyFlatBottomOfCapsuleIfLeavingEdge = Other.bOnlyFlatBottomOfCapsuleIfLeavingEdge;
		WalkOnUnstableEdgeHandling = Other.WalkOnUnstableEdgeHandling;
		LandOnUnstableEdgeHandling = Other.LandOnUnstableEdgeHandling;
		bProjectVelocityOnGroundNormalOnLanding = Other.bProjectVelocityOnGroundNormalOnLanding;

		AlignWithImpactSettings = Other.AlignWithImpactSettings;
		MaxEdgeDistanceUntilUnstable = Other.MaxEdgeDistanceUntilUnstable;
		OverrideFinalGroundContact = Other.OverrideFinalGroundContact;
		OverrideFinalGroundContactType = Other.OverrideFinalGroundContactType;
		bGenerateInitialGroundedStateFirstIteration = Other.bGenerateInitialGroundedStateFirstIteration;

		bWasStuckLastFrame = Other.bWasStuckLastFrame;
	}
#endif

	/**
	 * The stepping resolver can have a horizontal velocity in any direction
	 * making the horizontal velocity still be the horizontal velocity even
	 * if it is aligned with the ground.
	 * If we are currently grounded, all of this velocity will end up in the Horizontal delta type
	 * If we are not currently grounded, it will be split into Horizontal anv Vertical determined by the WorldUp.
	 */
	void AddHorizontalVelocity(FVector Velocity)
	{
		check(IsValid());
		check(!Velocity.ContainsNaN());

		const FMovementDelta DeltaToAdd(GetDeltaFromVelocityInternal(Velocity), Velocity);
		if(OriginalContacts.GroundContact.IsAnyGroundContact())
		{
			AddHorizontalInternal(DeltaToAdd, true);
		}
		else
		{
			AddHorizontalInternal(DeltaToAdd.GetHorizontalPart(WorldUp), true);
			AddVerticalInternal(DeltaToAdd.GetVerticalPart(WorldUp), true);
		}
	}

	void AddHorizontalAcceleration(FVector Acceleration)
	{
		check(IsValid());
		check(!Acceleration.ContainsNaN());

		const FMovementDelta DeltaToAdd(GetDeltaFromAcceleration(Acceleration), GetVelocityFromAcceleration(Acceleration));
		if(OriginalContacts.GroundContact.IsAnyGroundContact())
		{
			AddHorizontalInternal(DeltaToAdd, true);
		}
		else
		{
			AddHorizontalInternal(DeltaToAdd.GetHorizontalPart(WorldUp), true);
			AddVerticalInternal(DeltaToAdd.GetVerticalPart(WorldUp), true);
		}
	}

	protected void AddHorizontalInternal(FMovementDelta HorizontalDelta, bool bIsHorizontalType) override
	{	
		// If this type is not set to specifically be horizontal, we add it to the normal movement
		if(!bIsHorizontalType)
			Super::AddHorizontalInternal(HorizontalDelta, bIsHorizontalType);
		else
			DeltaStates.Add(EMovementIterationDeltaStateType::Horizontal, HorizontalDelta);	
			
	}

	/** Adding vertical velocity will split up the vertical part and the horizontal part
	 * and only add the vertical part
	 */
	void AddVerticalVelocity(FVector Velocity)
	{
		check(IsValid());
		check(!Velocity.ContainsNaN());

		const FVector TotalDelta = GetDeltaFromVelocityInternal(Velocity);

		const FVector ConstrainedVerticalDelta = TotalDelta.ProjectOnToNormal(WorldUp);
		const FVector ConstrainedVerticalVelocity = Velocity.ProjectOnToNormal(WorldUp);

		AddVerticalInternal(FMovementDelta(ConstrainedVerticalDelta, ConstrainedVerticalVelocity), true);
	}

	void AddVerticalAcceleration(FVector Acceleration)
	{
		check(IsValid());
		check(!Acceleration.ContainsNaN());

		const FVector TotalDelta = GetDeltaFromAcceleration(Acceleration);
		const FVector Velocity = GetVelocityFromAcceleration(Acceleration);

		const FVector ConstrainedVerticalDelta = TotalDelta.ProjectOnToNormal(WorldUp);
		const FVector ConstrainedVerticalVelocity = Velocity.ProjectOnToNormal(WorldUp);

		AddVerticalInternal(FMovementDelta(ConstrainedVerticalDelta, ConstrainedVerticalVelocity), true);
	}

	void BlockStepDownForThisFrame()
	{
		StepDownOnGroundSize = 0;
		StepDownInAirSize = 0;
	}

	void BlockStepUpForThisFrame()
	{
		StepUpSize = 0;
	}

	void BlockWallRedirectsThisFrame()
	{
		bRedirectMovementOnWallImpacts = false;
	}

	void OverrideStepDownAmountForThisFrame(float Value)
	{
		StepDownOnGroundSize = Math::Max(Value, 0.0);
		StepDownInAirSize = Math::Max(Value, 0.0);
	}

	void OverrideStepUpAmountForThisFrame(float Value)
	{
		StepUpSize = Math::Max(Value, 0.0);
	}

	void ForceGroundedStepDownSize()
	{
		StepDownInAirSize = StepDownOnGroundSize;
	}

	/**
	 * If this is requested and we are airborne after this move, we will start falling.
	 * @see UHazeMovementComponent::FallingState
	 */
	void RequestFallingForThisFrame()
	{
		check(IsValid());
		CustomStatus.FindOrAdd(EMovementCustomStatus::WantsToFall, true);
	}

	/**
	 * Attempt to stop when we are right on the edge.
	 * Note that you usually want to combine this with ApplyUnstableEdgeDistance, since otherwise the edge stopping might not match where the edge becomes unstable.
	 */
	void StopMovementWhenLeavingEdgeThisFrame()
	{
		EdgeHandling = EMovementEdgeHandlingType::Stop;
	}

	bool WantsToFall() const
	{
		bool bOutStatus = false;
		if(!CustomStatus.Find(EMovementCustomStatus::WantsToFall, bOutStatus))
			return false;
		return bOutStatus;
	}

	/**
	 * What ever grounded type is found, if any, this request will be used as the ground impact.
	 * @param bValidate If true, and the request is a valid blocking hit, the an extra trace will be made to actually place the actor on the ground
	 */
	void OverrideFinalGroundResult(FHitResult WantedGroundImpact, bool bValidate = true)
	{
		check(IsValid());

		OverrideFinalGroundContact = WantedGroundImpact;
		if(bValidate)
		{
			OverrideFinalGroundContactType = EMovementOverrideFinalGroundType::ActiveWithValidation;
		}
		else
		{
			OverrideFinalGroundContactType = EMovementOverrideFinalGroundType::Active;
		}
	}

	/**
	 * This will make the edges become unstable at a longer distance if we are moving towards the edges
	 */
	void ApplyUnstableEdgeDistance(FMovementSettingsValue Amount)
	{	
		// This requires edge handling
		if(EdgeHandling == EMovementEdgeHandlingType::None)
			EdgeHandling = EMovementEdgeHandlingType::Leave;

		// If the unstable distance is nearly 0, then we want all edges to always be unstable
		if(Math::IsNearlyZero(MaxEdgeDistanceUntilUnstable))
			return;

		MaxEdgeDistanceUntilUnstable = Math::Max(Amount.Get(ShapeSizeForMovement), SafetyDistance.X);
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

	/**
	 * If you are having issues with losing velocity when landing on slopes, try applying this.
	 * By default we project the movement deltas (except horizontal) on the world up plane when landing.
	 * In some cases, this can lead to losing velocity when landing on surfaces that are not aligned with WorldUp.
	 * Apply this function to project on the ground normal plane instead of the world up.
	 */
	void ApplyProjectVelocityOnGroundNormalOnLanding()
	{
		bProjectVelocityOnGroundNormalOnLanding = true;
	}
}
