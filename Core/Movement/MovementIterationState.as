/**
 * Iteration State
 * The main set of values that are initialized at the start of a resolver iteration,
 * and modified throughout the iteration.
 * After iterations are finished, this is applied on the moving actor.
 */
struct FMovementResolverState
{
	/**
	 * Where the ActorLocation is currently.
	 * This will be correct when set from HitResult.Location.
	 * Note that this is not the same as the shape location.
	 * @see GetShapeCenterLocation()
	 */
	FVector CurrentLocation = FVector::ZeroVector;

	/**
	 * How the actor is currently rotated.
	 * Note that this is not the same as the shape rotation.
	 * @see FHazeMovementTraceSettings::CollisionShapeWorldRotation
	 */
	FQuat CurrentRotation = FQuat::Identity;

	/**
	 * The current WorldUp.
	 * Note that this may not be the same as the shape Up vector.
	 * @see FHazeMovementTraceSettings::CollisionShapeWorldRotation
	 */
	FVector WorldUp = FVector::ZeroVector;

	/**
	 * Where did the previous iterations CurrentLocation end up?
	 */
	private FVector PreviousIterationLocation = FVector::ZeroVector;

	/**
	 * Where did the previous iterations CurrentRotation end up?
	 */
	private FQuat PreviousIterationRotation = FQuat::Identity;

	/**
	 * How much we have moved of the initial delta as a percentage.
	 * Range 0 to 1.
	 * If this value is >= 1, we are finished.
	 */
	float PerformedMovementAlpha = 0;

	/**
	 * How much we have moved of the initial delta in units.
	 */
	float PerformedMoveAmount = 0;

	/**
	 * When substepping, this modifier is used as a multiplier to decrease the delta per iteration,
	 * and increase the PerformedMovementAlpha less than usual.
	 */
	float AlphaModifier = 1;

	/**
	 * How much we want to move this iteration as a delta.
	 * Note that this is not the same as the current velocities and deltas.
	 * @see GetDelta()
	 */
	FVector DeltaToTrace = FVector::ZeroVector;
	
	/**
	 * The current movement contacts.
	 * Contains hit results for Ground, Wall and Ceiling contacts.
	 */
	FMovementContacts PhysicsState;

	private FMovementIterationDeltaStates InternalIterationDeltas;

	void InitFromMovementData(const UBaseMovementData Data)
	{
		CurrentLocation = Data.OriginalActorTransform.Location;
		CurrentRotation = Data.TargetRotation; // We set the rotation to the wanted rotation
		WorldUp = Data.WorldUp;

	 	PreviousIterationLocation = CurrentLocation;
	 	PreviousIterationRotation = Data.OriginalActorTransform.Rotation;

		PerformedMovementAlpha = 0;
		PerformedMoveAmount = 0;
		AlphaModifier = 1;

		DeltaToTrace = FVector::ZeroVector;

		InternalIterationDeltas = Data.DeltaStates;
		ApplyTerminalVelocityInternal(Data);
		ApplyMaximumSpeedInternal(Data);

		PhysicsState = FMovementContacts();
	}

	FMovementDelta GetDelta(EMovementIterationDeltaStateType DeltaType = EMovementIterationDeltaStateType::Sum) const
	{
		return InternalIterationDeltas.GetDelta(DeltaType);
	}

	const TMap<EMovementIterationDeltaStateType, FMovementDeltaWithWorldUp>& GetDeltaStates() const property
	{
		return InternalIterationDeltas.States;
	}

	FVector GetMovementDirection() const
	{
		if(!DeltaToTrace.IsNearlyZero())
			return DeltaToTrace.GetSafeNormal();

		const FVector IterationDelta = GetDelta().Delta;
		if(!IterationDelta.IsNearlyZero())
			return IterationDelta.GetSafeNormal();

		return CurrentRotation.ForwardVector;
	}

	FVector GetHorizontalMovementDirection(FVector UpVector) const
	{
		FVector Out = DeltaToTrace.VectorPlaneProject(UpVector);
		if(!Out.IsNearlyZero())
			return Out.GetSafeNormal();

		Out = GetDelta().Delta.VectorPlaneProject(UpVector);
		if(!Out.IsNearlyZero())
			return Out.GetSafeNormal();

		return CurrentRotation.ForwardVector.VectorPlaneProject(UpVector).GetSafeNormal();
	}

	void OverrideDelta(EMovementIterationDeltaStateType Type, FMovementDelta NewDelta)
	{
#if !RELEASE
		if(!ensure(InternalIterationDeltas.States.Contains(Type), "OverrideDelta() on a DeltaStateType that has not been initialized!"))
			return;
#endif

		FMovementDeltaWithWorldUp& State = InternalIterationDeltas.States[Type];
		State.Delta = NewDelta.Delta;
		State.Velocity = NewDelta.Velocity;
	}	

	void OverrideHorizontalDelta(EMovementIterationDeltaStateType Type, FMovementDelta NewDelta)
	{
#if !RELEASE
		if(!ensure(InternalIterationDeltas.States.Contains(Type), "OverrideHorizontalDelta() on a DeltaStateType that has not been initialized!"))
			return;
#endif

		FMovementDeltaWithWorldUp& State = InternalIterationDeltas.States[Type];
		State.SetHorizontalPart(NewDelta.Delta, NewDelta.Velocity);
	}	

	void OverrideHorizontalDelta(EMovementIterationDeltaStateType Type, FMovementDelta NewDelta, FVector UpVector)
	{
#if !RELEASE
		if(!ensure(InternalIterationDeltas.States.Contains(Type), "OverrideHorizontalDelta() on a DeltaStateType that has not been initialized!"))
			return;
#endif

		FMovementDeltaWithWorldUp& State = InternalIterationDeltas.States[Type];
		State.OverrideHorizontal(NewDelta.Delta, NewDelta.Velocity, UpVector);
	}	

	void ChangeDeltaWorldUp(EMovementIterationDeltaStateType Type, FVector NewUp)
	{
#if !RELEASE
		if(!ensure(InternalIterationDeltas.States.Contains(Type), "ChangeDeltaWorldUp() on a DeltaStateType that has not been initialized!"))
			return;
#endif

		FMovementDeltaWithWorldUp& TypeData = InternalIterationDeltas.States[Type];
		TypeData.ChangeWorldUp(NewUp);
	}

	protected void ApplyTerminalVelocityInternal(const UBaseMovementData Data)
	{
		if(Data.TerminalVelocity < 0)
			return;

		// Clamp the movements vertical part to terminal velocity
		// By default we only clamp "Movement", allowing "Impulse" to push beyond terminal velocity
		FMovementDelta MovementDelta = InternalIterationDeltas.GetDelta(EMovementIterationDeltaStateType::Movement);
		FMovementDelta NewVertical = MovementDelta.GetVerticalPart(WorldUp);
		
		if(NewVertical.Delta.DotProduct(WorldUp) >= -SMALL_NUMBER)
			return;
		
		NewVertical = Data.ClampToMaxVelocitySize(NewVertical, Data.TerminalVelocity);
		FMovementDelta Horizontal = MovementDelta.GetHorizontalPart(WorldUp);
		MovementDelta = Horizontal + NewVertical;
		OverrideDelta(EMovementIterationDeltaStateType::Movement, MovementDelta);
	}

	protected void ApplyMaximumSpeedInternal(const UBaseMovementData Data)
	{
		if(Data.MaximumSpeed < 0)
			return;

		for(auto It : InternalIterationDeltas.States)
		{
			if(It.Key == EMovementIterationDeltaStateType::Impulse)
				continue;

			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			MovementDelta = Data.ClampToMaxVelocitySize(MovementDelta, Data.MaximumSpeed);
			OverrideDelta(It.Key, MovementDelta);
		}
	}

	void ApplyMovement(float Alpha)
	{
		ApplyMovement(Alpha, CurrentLocation + (DeltaToTrace * Alpha));
	}

	void ApplyMovement(float Alpha, FVector NewPosition)
	{
		PreviousIterationLocation = CurrentLocation;
		CurrentLocation = NewPosition;
		PerformedMoveAmount += Alpha * DeltaToTrace.Size();

		const float FinalAlpha = RemainingMovementAlpha * AlphaModifier * Alpha;
		PerformedMovementAlpha += FinalAlpha;
		devCheck(PerformedMovementAlpha <= (1 + KINDA_SMALL_NUMBER)); // We should never be able to move longer than the amount of movement we have left
	}

	float GetRemainingMovementAlpha() const property
	{
		return 1 - PerformedMovementAlpha;
	}

	FTransform GetCurrentTransform() const
	{
		return FTransform(CurrentRotation, CurrentLocation);
	}

	const FVector& GetPreviousIterationLocation() const
	{
		return PreviousIterationLocation;
	}

	const FQuat& GetPreviousIterationRotation() const
	{
		return PreviousIterationRotation;
	}

	/**
	 * Get the center of the movement shape used for sweeps.
	 * (CurrentLocation + CollisionShapeOffset)
	 * NOTE: This is NOT the same as CurrentLocation, which is where the actor will end up.
	 */
	FVector GetShapeCenterLocation(FHazeMovementTraceSettings TraceSettings) const
	{
		return ConvertLocationToShapeCenterLocation(CurrentLocation, TraceSettings);
	}

	/**
	 * Get the highest point of the shape in the shapes Up direction.
	 */
	FVector GetShapeTopLocation(FHazeMovementTraceSettings TraceSettings) const
	{
		return ConvertLocationToShapeTopLocation(CurrentLocation, TraceSettings);
	}

	/**
	 * Get the center of the cap at the top of the capsule.
	 * Only valid for Capsule, other shapes will return ShapeCenterLocation.
	 */
	FVector GetShapeTopCapCenterLocation(FHazeMovementTraceSettings TraceSettings, float ShapeSizeForMovement) const
	{
		return ConvertLocationToShapeTopCapCenterLocation(CurrentLocation, TraceSettings, ShapeSizeForMovement);
	}

	/**
	 * Get the lowest point of the shape in the shapes Down direction.
	 */
	FVector GetShapeBottomLocation(FHazeMovementTraceSettings TraceSettings) const
	{
		return ConvertLocationToShapeBottomLocation(CurrentLocation, TraceSettings);
	}

	/**
	 * Get the center of the cap at the bottom of the capsule.
	 * Only valid for Capsule, other shapes will return ShapeCenterLocation.
	 */
	FVector GetShapeBottomCapCenterLocation(FHazeMovementTraceSettings TraceSettings, float ShapeSizeForMovement) const
	{
		return ConvertLocationToShapeBottomCapCenterLocation(CurrentLocation, TraceSettings, ShapeSizeForMovement);
	}

	/**
	 * Convert from a CurrentLocation or HitResult.Location to the shape center location.
	 */
	FVector ConvertLocationToShapeCenterLocation(FVector Location, FHazeMovementTraceSettings TraceSettings) const
	{
		return Location + TraceSettings.CollisionShapeOffset;
	}

	FVector ConvertLocationToShapeTopLocation(FVector Location, FHazeMovementTraceSettings TraceSettings) const
	{
		const FVector ShapeCenterLocation = ConvertLocationToShapeCenterLocation(Location, TraceSettings);
		return ShapeCenterLocation + (TraceSettings.CollisionShapeWorldRotation.UpVector * TraceSettings.TraceShape.Extent.Z);
	}

	FVector ConvertLocationToShapeTopCapCenterLocation(FVector Location, FHazeMovementTraceSettings TraceSettings, float ShapeSizeForMovement) const
	{
		if(!TraceSettings.TraceShape.IsCapsule())
			return GetShapeCenterLocation(TraceSettings);

		const FVector ShapeTopLocation = ConvertLocationToShapeTopLocation(Location, TraceSettings);
		return ShapeTopLocation - TraceSettings.CollisionShapeWorldRotation.UpVector * ShapeSizeForMovement;
	}

	FVector ConvertLocationToShapeBottomLocation(FVector Location, FHazeMovementTraceSettings TraceSettings) const
	{
		const FVector ShapeCenterLocation = ConvertLocationToShapeCenterLocation(Location, TraceSettings);
		return ShapeCenterLocation - (TraceSettings.CollisionShapeWorldRotation.UpVector * TraceSettings.TraceShape.Extent.Z);
	}

	FVector ConvertLocationToShapeBottomCapCenterLocation(FVector Location, FHazeMovementTraceSettings TraceSettings, float ShapeSizeForMovement) const
	{
		if(!TraceSettings.TraceShape.IsCapsule())
			return GetShapeCenterLocation(TraceSettings);

		const FVector ShapeBottomLocation = ConvertLocationToShapeBottomLocation(Location, TraceSettings);
		return ShapeBottomLocation + TraceSettings.CollisionShapeWorldRotation.UpVector * ShapeSizeForMovement;
	}

	/**
	 * Convert from a ShapeCenterLocation to the CurrentLocation.
	 */
	FVector ConvertShapeCenterLocationToCurrentLocation(FVector ShapeCenterLocation, FHazeMovementTraceSettings TraceSettings) const
	{
		return ShapeCenterLocation - TraceSettings.CollisionShapeOffset;
	}

	/**
	 * Convert from a ShapeTopLocation to the CurrentLocation.
	 */
	FVector ConvertShapeTopLocationToCurrentLocation(FVector ShapeTopLocation, FHazeMovementTraceSettings TraceSettings) const
	{
		const FVector ShapeCenterLocation = ShapeTopLocation - (TraceSettings.CollisionShapeWorldRotation.UpVector * TraceSettings.TraceShape.Extent.Z);
		return ConvertShapeCenterLocationToCurrentLocation(ShapeCenterLocation, TraceSettings);
	}

	/**
	 * Convert from a ShapeTopCapCenterLocation to the CurrentLocation.
	 */
	FVector ConvertShapeTopCapCenterLocationToCurrentLocation(FVector ShapeTopCapCenterLocation, FHazeMovementTraceSettings TraceSettings, float ShapeSizeForMovement) const
	{
		if(!TraceSettings.TraceShape.IsCapsule())
			return ConvertShapeCenterLocationToCurrentLocation(ShapeTopCapCenterLocation, TraceSettings);

		const FVector ShapeTopLocation = ShapeTopCapCenterLocation + (TraceSettings.CollisionShapeWorldRotation.UpVector * ShapeSizeForMovement);
		return ConvertShapeTopLocationToCurrentLocation(ShapeTopLocation, TraceSettings);
	}

	/**
	 * Convert from a ShapeBottomLocation to the CurrentLocation.
	 */
	FVector ConvertShapeBottomLocationToCurrentLocation(FVector ShapeBottomLocation, FHazeMovementTraceSettings TraceSettings) const
	{
		const FVector ShapeCenterLocation = ShapeBottomLocation + (TraceSettings.CollisionShapeWorldRotation.UpVector * TraceSettings.TraceShape.Extent.Z);
		return ConvertShapeCenterLocationToCurrentLocation(ShapeCenterLocation, TraceSettings);
	}

	/**
	 * Convert from a ShapeBottomCapCenterLocation to the CurrentLocation.
	 */
	FVector ConvertShapeBottomCapCenterLocationToCurrentLocation(FVector ShapeBottomCapCenterLocation, FHazeMovementTraceSettings TraceSettings, float ShapeSizeForMovement) const
	{
		if(!TraceSettings.TraceShape.IsCapsule())
			return ConvertShapeCenterLocationToCurrentLocation(ShapeBottomCapCenterLocation, TraceSettings);

		const FVector ShapeTopLocation = ShapeBottomCapCenterLocation - (TraceSettings.CollisionShapeWorldRotation.UpVector * ShapeSizeForMovement);
		return ConvertShapeBottomLocationToCurrentLocation(ShapeTopLocation, TraceSettings);
	}
};