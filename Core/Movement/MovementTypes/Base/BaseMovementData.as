/**
 * A MovementData represents the initial state of a move.
 * 
 * We start by preparing it with PrepareMove().
 * This function stores the initial state of the actor that wants to move.
 * Think original transform, collision size, delta time, and checking if spline lock should be applied.
 * 
 * Then capabilities will add velocities on this movement data, and setup custom settings.
 * 
 * We then call MovementComponent.ApplyMove() and pass in a MovementData to start resolving and applying the movement
 * in a MovementResolver to figure out how we can slide and redirect along surfaces to find a final location.
 * @see UBaseMovementResolver
 * 
 * This MovementData is copied and stored to allow for rerunning the movement in the temporal logger for debugging.
 * There is a CopyFrom function that MUST be updated with all properties on the MovementData class to ensure this.
 */
UCLASS(Abstract, NotBlueprintable)
class UBaseMovementData : UHazeMovementData
{
	access Protected = protected, UBaseMovementResolver (inherited), UMovementResolverExtension (inherited), FMovementResolverState, MovementDebug;
	access ProtectedForMovement = protected, UBaseMovementResolver (inherited), UMovementResolverExtension (inherited), UHazeMovementComponent (inherited), FMovementResolverState, FMovementIterationDeltaStates, AddMovementResolvedData, AddInitialDebugInfo, LogIgnoredPage;
	access PrivateForRerun = private, UBaseMovementResolver (inherited), UMovementResolverExtension (inherited), UHazeMovementComponent (inherited), UMovementTemporalRerunExtender;

	// This has to always be setup
	const TSubclassOf<UBaseMovementResolver> DefaultResolverType;

#if EDITOR
	access:PrivateForRerun
	bool bIsEditorRerunData = false;

	access:PrivateForRerun
	int EditorTemporalFrame = 0;
#endif

	// The movement component this belongs to
	// Should be a const reference to disallow changing the movement component or actor from this data class that should only do data stuff
	private const UHazeMovementComponent InternalMovementComponent;

	access:ProtectedForMovement
	FVector WorldUp = FVector::UpVector;

	access:ProtectedForMovement
	FHazeMovementTraceSettings TraceSettings;

	access:ProtectedForMovement
	float WalkableSlopeAngle = 0;

	access:ProtectedForMovement
	bool bAlsoUseActorUpForWalkableSlopeAngle = false;

	access:ProtectedForMovement
	bool bForceAllGroundUnwalkable = false;

	access:ProtectedForMovement
	float CeilingAngle = 0;

	access:ProtectedForMovement
	bool bConsiderImpactEdgeIfNormalsAngleHigherThanWalkableSlopeAngle = true;

	access:Protected
	float IterationTime = 0;

	access:ProtectedForMovement
	FMovementIterationDeltaStates DeltaStates;

	access:Protected
	TArray<UPrimitiveComponent> IgnoredComponents;

	access:Protected
	TArray<AActor> IgnoredActorsThisFrame;

	access:Protected
	TMap<EMovementCustomStatus, bool> CustomStatus;

	access:ProtectedForMovement
	FTransform OriginalActorTransform = FTransform::Identity;

	access:ProtectedForMovement
	FTransform OriginalShapeTransform = FTransform::Identity;

	access:ProtectedForMovement
	FQuat TargetRotation = FQuat::Identity;

	access:ProtectedForMovement
	float TerminalVelocity = -1;

	access:ProtectedForMovement
	float MaximumSpeed = -1;

	access:Protected
	float ShapeSizeForMovement = 0;

	access:Protected
	FVector2D SafetyDistance = FVector2D::ZeroVector;

	access:Protected
	int MaxRedirectIterations = 0;

	access:Protected
	int MaxDepenetrationIterations = 0;

	access:Protected
	FMovementContacts OriginalContacts;

	access:Protected
	FMovementContacts PreviousContacts;

	access:ProtectedForMovement
	bool bHasSyncedLocationInfo = false;

	access:ProtectedForMovement
	bool bHasSyncedRotationInfo = false;

	access:ProtectedForMovement
	FHazeSyncedActorPosition SyncedActorData;

#if !RELEASE
	access:Protected
	FTransform DebugFinalTransform = FTransform::Identity;

	access:ProtectedForMovement
	FName DebugMoveInstigator;

	access:ProtectedForMovement
	UClass DebugMoveInstigatorClass;

	access:ProtectedForMovement
	uint DebugPreparedFrame = 0;
#endif

	bool HasMovementComponent() const
	{
		return InternalMovementComponent != nullptr;
	}
	
	FVector GetPendingImpulse() const
	{
		return InternalMovementComponent.GetPendingImpulse();
	}

	FHazeTraceShape GetCollisionShape() const
	{
		return InternalMovementComponent.CollisionShape;
	}

	access:ProtectedForMovement
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp = FVector::ZeroVector)
	{
		InternalMovementComponent = MovementComponent;

		if(!devEnsure(InternalMovementComponent != nullptr, f"Move {this} was prepared with an invalid MovementComponent!"))
			return false;

#if !RELEASE
		DebugPreparedFrame = Time::FrameNumber;
#endif

		ShapeSizeForMovement = InternalMovementComponent.GetShapeSizeForMovement();
		IgnoredComponents.Reset();
		IgnoredActorsThisFrame.Reset();

		if(CustomWorldUp.IsUnit())
			WorldUp = CustomWorldUp;
		else
			WorldUp = InternalMovementComponent.GetWorldUp();

		OriginalActorTransform = InternalMovementComponent.HazeOwner.GetActorTransform();
		OriginalShapeTransform = InternalMovementComponent.GetShapeComponent().WorldTransform;
		TargetRotation = OriginalActorTransform.GetRotation();

		OriginalContacts = InternalMovementComponent.CurrentContacts;
		PreviousContacts = InternalMovementComponent.PreviousContacts;
		
		TraceSettings = MovementTrace::Init(InternalMovementComponent);
		IterationTime = Time::GetActorDeltaSeconds(InternalMovementComponent.HazeOwner);
		
		DeltaStates.Reset();

		// These are the two defaults that can always be added
		DeltaStates.Init(EMovementIterationDeltaStateType::Movement, WorldUp);
		DeltaStates.Init(EMovementIterationDeltaStateType::Impulse, FVector::UpVector);
	
		{
			const UMovementStandardSettings StandardSettings = InternalMovementComponent.InternalStandardSettings;
			WalkableSlopeAngle = StandardSettings.WalkableSlopeAngle;
			bAlsoUseActorUpForWalkableSlopeAngle = StandardSettings.bAlsoUseActorUpForWalkableSlopeAngle;
			bForceAllGroundUnwalkable = StandardSettings.bForceAllGroundUnwalkable;
			CeilingAngle = StandardSettings.CeilingAngle;
			bConsiderImpactEdgeIfNormalsAngleHigherThanWalkableSlopeAngle = StandardSettings.bConsiderImpactEdgeIfNormalsAngleHigherThanWalkableSlopeAngle;
		}

		{
			const UMovementResolverSettings ResolverSettings = InternalMovementComponent.InternalResolverSettings;
			MaxRedirectIterations = ResolverSettings.MaxRedirectIterations;
			devCheck(MaxRedirectIterations <= 10, f"The {GetName()}s Iteration count is set to {MaxRedirectIterations} but only 10 is allowed as a max");
			MaxRedirectIterations = Math::Min(MaxRedirectIterations, 10);
			MaxDepenetrationIterations = ResolverSettings.MaxDepenetrationIterations;
		}

		SafetyDistance.X = InternalMovementComponent.GetMovementSafetyMargin();
		SafetyDistance.Y = InternalMovementComponent.GetGroundedSafetyMargin();

		TerminalVelocity = -1;
		MaximumSpeed = -1;
		CustomStatus.Reset();

		bHasSyncedLocationInfo = false;
		bHasSyncedRotationInfo = false;
	 	SyncedActorData = FHazeSyncedActorPosition();

#if !RELEASE
		ApplyDebugMoveInstigator();
#endif

		return true;
	}

#if !RELEASE
	private void ApplyDebugMoveInstigator()
	{
		UObject InstigatorObject = nullptr;
		for(int i = 0; i < 10; i++)
		{
			InstigatorObject = Debug::EditorGetAngelscriptStackFrameObject(i);
			if(InstigatorObject == nullptr)
				continue;

			if(InstigatorObject.Class.IsChildOf(UBaseMovementData))
				continue;

			auto MoveComp = Cast<UHazeMovementComponent>(InstigatorObject);
			if(MoveComp != nullptr)
				continue;

			break;
		}

		if (InstigatorObject != nullptr)
		{
			DebugMoveInstigator = InstigatorObject.Name;
			DebugMoveInstigatorClass = InstigatorObject.Class;
		}
		else
		{
			DebugMoveInstigator = NAME_None;
			DebugMoveInstigatorClass = nullptr;
		}
	}
#endif

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData Other)
	{
		/** All the stored settings for this frame */
		InternalMovementComponent = Other.InternalMovementComponent;
		WorldUp = Other.WorldUp;
		TraceSettings = Other.TraceSettings;

		WalkableSlopeAngle = Other.WalkableSlopeAngle;
		bAlsoUseActorUpForWalkableSlopeAngle = Other.bAlsoUseActorUpForWalkableSlopeAngle;
		bForceAllGroundUnwalkable = Other.bForceAllGroundUnwalkable;
		CeilingAngle = Other.CeilingAngle;
		bConsiderImpactEdgeIfNormalsAngleHigherThanWalkableSlopeAngle = Other.bConsiderImpactEdgeIfNormalsAngleHigherThanWalkableSlopeAngle;

		IterationTime = Other.IterationTime;
		DeltaStates = Other.DeltaStates;
		IgnoredComponents = Other.IgnoredComponents;
		IgnoredActorsThisFrame = Other.IgnoredActorsThisFrame;
		CustomStatus = Other.CustomStatus;
		OriginalActorTransform = Other.OriginalActorTransform;
		OriginalShapeTransform = Other.OriginalShapeTransform;

		TargetRotation = Other.TargetRotation;

		TerminalVelocity = Other.TerminalVelocity;
		MaximumSpeed = Other.MaximumSpeed;

		ShapeSizeForMovement = Other.ShapeSizeForMovement;
		SafetyDistance = Other.SafetyDistance;

		MaxRedirectIterations = Other.MaxRedirectIterations;
		MaxDepenetrationIterations = Other.MaxDepenetrationIterations;

		OriginalContacts = Other.OriginalContacts;
		PreviousContacts = Other.PreviousContacts;

		bHasSyncedLocationInfo = Other.bHasSyncedLocationInfo;
		bHasSyncedRotationInfo = Other.bHasSyncedRotationInfo;
		SyncedActorData = Other.SyncedActorData;
		
		DebugMoveInstigator = Other.DebugMoveInstigator;
		DebugMoveInstigatorClass = Other.DebugMoveInstigatorClass;
		DebugPreparedFrame = Other.DebugPreparedFrame;
	}

	access:ProtectedForMovement
	UBaseMovementData GetRerunCopy(UBaseMovementResolver RerunOuter, int Frame) const
	{
		UBaseMovementData RerunData = Cast<UBaseMovementData>(NewObject(RerunOuter, Class));
		RerunData.CopyFrom(this);
		RerunData.bIsEditorRerunData = true;
		RerunData.EditorTemporalFrame = Frame;
		return RerunData;
	}
#endif

#if !RELEASE
	bool IsRerun() const
	{
#if EDITOR
		if(bIsEditorRerunData)
			return true;
#endif

		return false;
	}
#endif

	access:ProtectedForMovement
	FInstigator GetStatusInstigator() const property
	{
#if !RELEASE
		return FInstigator(DebugMoveInstigator);
#else
		return NAME_None;
#endif
	}

	FInstigator GetMovementInstigator() const property
	{
#if !RELEASE
		return FInstigator(DebugMoveInstigator);
#else
		return this;
#endif
	}

	bool IsValid() const
	{
#if EDITOR
		// When rerunning, we are always valid!
		if(bIsEditorRerunData)
			return true;
#endif

		if(!HasMovementComponent())
			return false;

		// Is this data old?
		if(InternalMovementComponent.LastPreparedStatusFrame != Time::FrameNumber)
			return false;

		return true;
	}

	void AddDelta(FVector Delta, EMovementDeltaType Type = EMovementDeltaType::Native)
	{
		AddDeltaWithCustomVelocity(Delta, GetVelocityFromDeltaInternal(Delta), Type);
	}

	void AddDeltaWithCustomVelocity(FVector Delta, FVector Velocity, EMovementDeltaType Type = EMovementDeltaType::Native)
	{
		devCheck(IsValid());
		devCheck(!Velocity.ContainsNaN());
		devCheck(!Delta.ContainsNaN());

		const FMovementDelta DeltaToAdd(Delta, Velocity);
		if(Type == EMovementDeltaType::Native)
		{
			AddHorizontalInternal(DeltaToAdd.GetHorizontalPart(WorldUp), false);
			AddVerticalInternal(DeltaToAdd.GetVerticalPart(WorldUp), false);
		}
		else if(Type == EMovementDeltaType::Horizontal)
		{
			AddHorizontalInternal(DeltaToAdd, true);
		}
		else if(Type == EMovementDeltaType::Vertical)
		{
			AddVerticalInternal(DeltaToAdd, true);
		}
		else if(Type == EMovementDeltaType::HorizontalExclusive)
		{
			AddHorizontalInternal(DeltaToAdd.GetHorizontalPart(WorldUp), true);
		}
		else if(Type == EMovementDeltaType::VerticalExclusive)
		{
			AddVerticalInternal(DeltaToAdd.GetVerticalPart(WorldUp), true);
		}
	}

	void AddVelocity(FVector Velocity)
	{
		const FMovementDelta DeltaToAdd(GetDeltaFromVelocityInternal(Velocity), Velocity);
		AddHorizontalInternal(DeltaToAdd.GetHorizontalPart(WorldUp), false);
		AddVerticalInternal(DeltaToAdd.GetVerticalPart(WorldUp), false);
	}

	void AddOwnerVelocity()
	{
		AddOwnerHorizontalVelocity();
		AddOwnerVerticalVelocity();
	}

	void AddOwnerHorizontalVelocity()
	{
		AddHorizontalInternal(FMovementDelta(GetDeltaFromVelocityInternal(InternalMovementComponent.HorizontalVelocity), InternalMovementComponent.HorizontalVelocity), true);
	}

	void AddOwnerVerticalVelocity()
	{
		AddVerticalInternal(FMovementDelta(GetDeltaFromVelocityInternal(InternalMovementComponent.VerticalVelocity), InternalMovementComponent.VerticalVelocity), true);
	}

	/**
	 * Add gravity acceleration to the MovementData
	 * @param bUseTerminalVelocity If true, it will also call ApplyTerminalVelocityThisFrame()
	 * @see UHazeMovementComponent::GetGravity()
	 * @see UMovementGravitySettings::SetGravityScale()
	 */
	void AddGravityAcceleration(bool bUseTerminalVelocity = true)
	{
		FVector GravityAcceleration = InternalMovementComponent.GetGravity();
		FVector GravityDelta = GetDeltaFromAcceleration(GravityAcceleration);
		FVector GravityVelocity = GetVelocityFromAcceleration(GravityAcceleration);
		AddVerticalInternal(FMovementDelta(GravityDelta, GravityVelocity), true);

		if(bUseTerminalVelocity)
		{
			ApplyTerminalVelocityThisFrame();
		}
	}

	void AddAcceleration(FVector AccelerationVelocity)
	{
		AddDeltaWithCustomVelocity(
			GetDeltaFromAcceleration(AccelerationVelocity),
			GetVelocityFromAcceleration(AccelerationVelocity),
		);
	}

	/**
	 * Adds all the pending impulses from external systems to this move.
	 * An impulse is a velocity change that is always oriented in worldspace
	 */
	void AddPendingImpulses()
	{
		const FVector FrameImpulseVelocity = InternalMovementComponent.GetPendingImpulse();	
		DeltaStates.Add(EMovementIterationDeltaStateType::Impulse, GetDeltaFromVelocityInternal(FrameImpulseVelocity), FrameImpulseVelocity);
	}

	/**
	 * Adds all the pending impulses with matching name from external systems to this move.
	 * An impulse is a velocity change that is always oriented in worldspace
	 */
	void AddPendingImpulsesWithInstigator(FInstigator WantedImpulse)
	{
		const FVector FrameImpulseVelocity = InternalMovementComponent.GetPendingImpulseWithInstigator(WantedImpulse);
		DeltaStates.Add(EMovementIterationDeltaStateType::Impulse, GetDeltaFromVelocityInternal(FrameImpulseVelocity), FrameImpulseVelocity);
	}

	/**
	 * Adds an impulse to this move.
	 * An impulse is a velocity change that is always oriented in worldspace
	 */
	void AddImpulse(FVector Impulse)
	{
		DeltaStates.Add(EMovementIterationDeltaStateType::Impulse, GetDeltaFromVelocityInternal(Impulse), Impulse);
	}


	/**
	 * @param bIsHorizontalType Is this coming from a type that is defined as a Horizontal type (Like HorizontalMovement)
	 */
	protected void AddHorizontalInternal(FMovementDelta HorizontalDelta, bool bIsHorizontalType)
	{
		devCheck(IsValid());
		devCheck(!HorizontalDelta.Delta.ContainsNaN());
		devCheck(!HorizontalDelta.Velocity.ContainsNaN());
		// By default, this is already turned into horizontal state
		DeltaStates.Add(EMovementIterationDeltaStateType::Movement, HorizontalDelta);
	}

	/**
	 * @param bIsVerticalType Is this coming from a type that is defined as a Vertical type (Like gravity)
	 */
	protected void AddVerticalInternal(FMovementDelta VerticalDelta, bool bIsVerticalType)
	{
		devCheck(IsValid());
		devCheck(!VerticalDelta.Delta.ContainsNaN());
		devCheck(!VerticalDelta.Velocity.ContainsNaN());
		// By default, this is already turned into vertical state
		DeltaStates.Add(EMovementIterationDeltaStateType::Movement, VerticalDelta);
	}

	void ApplyCrumbSyncedGroundMovement()
	{
		SyncedActorData = InternalMovementComponent.GetCrumbSyncedPosition();
		ApplySyncedGroundMovement();
	}

	void ApplyCrumbSyncedAirMovement()
	{
		SyncedActorData = InternalMovementComponent.GetCrumbSyncedPosition();
		ApplySyncedAirMovement();
	}

	void ApplyLatestSyncedGroundMovement()
	{
		float CrumbTime;
		SyncedActorData = InternalMovementComponent.GetLatestAvailableSyncedPosition(CrumbTime);
		ApplySyncedGroundMovement();
	}

	void ApplyLatestSyncedAirMovement()
	{
		float CrumbTime;
		SyncedActorData = InternalMovementComponent.GetLatestAvailableSyncedPosition(CrumbTime);
		ApplySyncedAirMovement();
	}

	private void ApplySyncedGroundMovement()
	{
		bHasSyncedLocationInfo = true;
		bHasSyncedRotationInfo = true;
		AddDeltaFromMoveToPositionWithCustomVelocity(SyncedActorData.WorldLocation, SyncedActorData.WorldVelocity, EMovementDeltaType::Horizontal);
		SetRotation(SyncedActorData.WorldRotation);
		WorldUp = SyncedActorData.WorldRotation.UpVector;

		ApplyRemoteSideEvaluateGround();
	}

	private void ApplySyncedAirMovement()
	{
		bHasSyncedLocationInfo = true;
		bHasSyncedRotationInfo = true;
		AddDeltaFromMoveToPositionWithCustomVelocity(SyncedActorData.WorldLocation, SyncedActorData.WorldVelocity, EMovementDeltaType::Native);
		SetRotation(SyncedActorData.WorldRotation);
		WorldUp = SyncedActorData.WorldRotation.UpVector;
	}

	void ApplyManualSyncedPosition(FHazeSyncedActorPosition Position, bool bGrounded = false)
	{
		SyncedActorData = Position;
		bHasSyncedLocationInfo = true;
		bHasSyncedRotationInfo = true;
		AddDeltaFromMoveToPositionWithCustomVelocity(SyncedActorData.WorldLocation, SyncedActorData.WorldVelocity, EMovementDeltaType::Native);
		SetRotation(SyncedActorData.WorldRotation);
		WorldUp = SyncedActorData.WorldRotation.UpVector;

		if (bGrounded)
			ApplyRemoteSideEvaluateGround();
	}

	void ApplyRemoteSideEvaluateGround()
	{
		// Set the remote side to perform ground traces
		CustomStatus.FindOrAdd(EMovementCustomStatus::RemoteSideEvaluateGround, true);
	}

	void ApplyManualSyncedLocationAndRotation(FVector SyncedLocation, FVector SyncedVelocity, FRotator SyncedRotation)
	{
		bHasSyncedLocationInfo = true;
		bHasSyncedRotationInfo = true;
		AddDeltaFromMoveToPositionWithCustomVelocity(SyncedLocation, SyncedVelocity, EMovementDeltaType::Native);
		SetRotation(SyncedRotation);
		WorldUp = SyncedRotation.UpVector;
	}

	void ApplyCrumbSyncedRotationOnly()
	{
		FHazeSyncedActorPosition SyncedMovement = InternalMovementComponent.GetCrumbSyncedPosition();
		SyncedActorData.WorldRotation = SyncedMovement.WorldRotation;
		SyncedActorData.RelativeRotation = SyncedMovement.RelativeRotation;
		bHasSyncedRotationInfo = true;
		SetRotation(SyncedMovement.WorldRotation);
		WorldUp = SyncedActorData.WorldRotation.UpVector;
	}

	void ApplyCrumbSyncedGroundMovementWithCustomVelocity(FVector CustomVelocity)
	{
		SyncedActorData = InternalMovementComponent.GetCrumbSyncedPosition();
		bHasSyncedLocationInfo = true;
		bHasSyncedRotationInfo = true;
		AddDeltaFromMoveToPositionWithCustomVelocity(SyncedActorData.WorldLocation, CustomVelocity, EMovementDeltaType::Horizontal);
		SetRotation(SyncedActorData.WorldRotation);
		WorldUp = SyncedActorData.WorldRotation.UpVector;

		// Adding this custom tag makes the remote side trace for the ground
		CustomStatus.FindOrAdd(EMovementCustomStatus::RemoteSideEvaluateGround, true);
	}

	void ApplyCrumbSyncedAirMovementWithCustomVelocity(FVector CustomVelocity)
	{
		SyncedActorData = InternalMovementComponent.GetCrumbSyncedPosition();
		bHasSyncedLocationInfo = true;
		bHasSyncedRotationInfo = true;
		AddDeltaFromMoveToPositionWithCustomVelocity(SyncedActorData.WorldLocation, CustomVelocity, EMovementDeltaType::Native);
		SetRotation(SyncedActorData.WorldRotation);
		WorldUp = SyncedActorData.WorldRotation.UpVector;
	}

	void AddDeltaFromMoveTo(FVector Location)
	{
		const FVector Delta = Location - InternalMovementComponent.Owner.GetActorLocation();
		const FVector Velocity = GetVelocityFromDeltaInternal(Delta);
		AddDeltaWithCustomVelocity(Delta, Velocity);
	}

	void AddDeltaFromMoveToPositionWithCustomHorizontalAndVerticalVelocity(FVector LocationToReach, FVector HorizontalVelocity, FVector VerticalVelocity)
	{
		const FVector Delta = LocationToReach - InternalMovementComponent.Owner.GetActorLocation();
		const FVector HorizontalDelta = Delta.VectorPlaneProject(WorldUp);
		const FVector VerticalDelta = Delta - HorizontalDelta;

		AddHorizontalInternal(FMovementDelta(HorizontalDelta, HorizontalVelocity), true);
		AddVerticalInternal(FMovementDelta(VerticalDelta, VerticalVelocity), true);
	}

	void AddDeltaFromMoveToPositionWithCustomVelocity(FVector LocationToReach, FVector CustomVelocity, EMovementDeltaType Type = EMovementDeltaType::Native)
	{
		FVector FrameDelta = LocationToReach - InternalMovementComponent.Owner.GetActorLocation();
		AddDeltaWithCustomVelocity(FrameDelta, CustomVelocity, Type);	
	}

	/**
	 * Should the vertical velocity pointing towards the ground be clamped?
	 * @see UMovementGravitySettings::SetTerminalVelocity()
	 * */
	void ApplyTerminalVelocityThisFrame()
	{
		TerminalVelocity = InternalMovementComponent.GetTerminalVelocity();
	}

	/**
	 * Clamp our final velocity to never be higher than this speed.
	 * Will not clamp impulses.
	 */
	void ApplyMaximumSpeed(float InMaximumSpeed)
	{
		MaximumSpeed = InMaximumSpeed;
	}

	void SetRotation(FQuat Rotation)
	{
		devCheck(IsValid());
		devCheck(!Rotation.ContainsNaN());
		TargetRotation = InternalMovementComponent.FinalizeRotation(Rotation, WorldUp);
	}

	void SetRotation(FRotator Rotation)
	{
		devCheck(IsValid());
		devCheck(!Rotation.Quaternion().ContainsNaN());
		TargetRotation = InternalMovementComponent.FinalizeRotation(Rotation.Quaternion(), WorldUp);
	}

	void InterpRotationToTargetFacingRotation(float RotationSpeed, bool bApplyWithConstantSpeed = true)
	{
		devCheck(IsValid());
		devCheck(!Math::IsNaN(RotationSpeed));

		const FQuat RotationToSet = InternalMovementComponent.GetTargetFacingRotationQuat();
		InterpRotationTo(RotationToSet, RotationSpeed, bApplyWithConstantSpeed);
	}

	void InterpRotationTo(FQuat WantedRotation, float RotationSpeed, bool bApplyWithConstantSpeed = true)
	{
		devCheck(IsValid());
		devCheck(!Math::IsNaN(RotationSpeed));

		if(RotationSpeed <= 0)
		{
			SetRotation(WantedRotation);
		}
		else if(bApplyWithConstantSpeed)
		{
			SetRotation(Math::QInterpConstantTo(
				InternalMovementComponent.Owner.GetActorQuat(),
				WantedRotation,
				IterationTime,
				RotationSpeed));
		}
		else
		{
			SetRotation(Math::QInterpTo(
				InternalMovementComponent.Owner.GetActorQuat(),
				WantedRotation,
				IterationTime,
				RotationSpeed));
		}
	}

	void IgnorePrimitiveForThisFrame(UPrimitiveComponent Component)
	{
		devCheck(IsValid());
		IgnoredComponents.Add(Component);
	}

	void IgnoreActorForThisFrame(AActor Actor)
	{
		devCheck(IsValid());
		IgnoredActorsThisFrame.Add(Actor);
	}

	void IgnoreSplineLockConstraint()
	{
		CustomStatus.FindOrAdd(EMovementCustomStatus::ShouldApplySplineLock, false);
	}

	bool GetShouldApplySplineLockConstraint() const
	{
		bool bShouldApplySplineLockConstraint;
		if(!CustomStatus.Find(EMovementCustomStatus::ShouldApplySplineLock, bShouldApplySplineLockConstraint))
			return true;
		
		return bShouldApplySplineLockConstraint;
	}

	protected FVector GetVelocityFromDeltaInternal(const FVector& Delta) const
	{
		devCheck(IsValid());
		devCheck(!Delta.ContainsNaN());
		return Delta / IterationTime;
	}

	protected FVector GetDeltaFromVelocityInternal(const FVector& Velocity) const
	{
		devCheck(IsValid());
		devCheck(!Velocity.ContainsNaN());
		return Velocity * IterationTime;
	}
	
	protected FVector GetDeltaFromAcceleration(const FVector& Acceleration) const
	{
		devCheck(IsValid());
		devCheck(!Acceleration.ContainsNaN());
		return Acceleration * (IterationTime * IterationTime * 0.5);	
	}

	protected FVector GetVelocityFromAcceleration(const FVector& Acceleration) const
	{
		devCheck(IsValid());
		devCheck(!Acceleration.ContainsNaN());
		return Acceleration * IterationTime;	
	}

	access:ProtectedForMovement
	float GetYawVelocityPostMovement(FQuat PreviousWorldTransform, bool bRelativeToFollow) const
	{
		if (IterationTime <= 0.0)
			return 0.0;

		FQuat PreviousRotation = OriginalActorTransform.Rotation;
		FQuat CurrentRotation = InternalMovementComponent.HazeOwner.ActorQuat;
		FVector CurrentWorldUp = WorldUp;

		if (bRelativeToFollow)
		{
			const FHazeMovementComponentAttachment& Attachment = InternalMovementComponent.GetCurrentMovementFollowAttachment();
			if (Attachment.IsValid())
			{
				FTransform AttachmentTransform = Attachment.GetWorldTransform();
				PreviousRotation = AttachmentTransform.InverseTransformRotation(PreviousRotation);
				CurrentRotation = AttachmentTransform.InverseTransformRotation(CurrentRotation);
				CurrentWorldUp = AttachmentTransform.InverseTransformVectorNoScale(CurrentWorldUp).GetSafeNormal();
			}
		}
		else
		{
			PreviousRotation = PreviousWorldTransform;
		}

		float PreviousYaw = Math::RadiansToDegrees(PreviousRotation.GetTwistAngle(WorldUp));
		float CurrentYaw = Math::RadiansToDegrees(CurrentRotation.GetTwistAngle(WorldUp));

		float DeltaRotation = Math::FindDeltaAngleDegrees(PreviousYaw, CurrentYaw);
		return DeltaRotation / IterationTime;
	}

	access:ProtectedForMovement
	FMovementDelta ClampToMaxVelocitySize(FMovementDelta MovementDelta, float Size) const
	{	
		FMovementDelta Out = MovementDelta;

		if(!Out.Velocity.IsNearlyZero())
		{
			float VelAlpha = Size / Out.Velocity.Size();
			VelAlpha = Math::Min(VelAlpha, 1);
			Out.Velocity *= VelAlpha;
		}

		if(!Out.Delta.IsNearlyZero())
		{
			float FinalDeltaTime = Math::Max(IterationTime, KINDA_SMALL_NUMBER);
			float DeltaVelocitySize = Out.Delta.Size() / FinalDeltaTime;
			float VelAlpha = Size / DeltaVelocitySize;
			VelAlpha = Math::Min(VelAlpha, 1);
			Out.Delta *= VelAlpha;
		}

		return Out;
	}

#if !RELEASE
	/**
	 * Owner/Movement, associated with the owning MovementComponent
	 */
	FTemporalLog GetTemporalLog() const
	{
		return InternalMovementComponent.GetTemporalLog();
	}

	access:ProtectedForMovement
	const FMovementIterationDeltaStates& GetDebugDeltaStates() const
	{
		return DeltaStates;
	}
#endif
};