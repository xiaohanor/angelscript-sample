#if !RELEASE
namespace DevTogglesMovement
{
	const FHazeDevToggleBool LogComponentValues;
};
#endif

const FStatID STAT_Movement_UpdateMovementFollowAttachment(n"Movement_UpdateMovementFollowAttachment");
const FStatID STAT_Movement_FindInheritVelocityComponent(n"Movement_FindInheritVelocityComponent");

/**
 * A component used to create advanced movement.
 */
UCLASS(NotBlueprintable, NotPlaceable, HideCategories = "Activation Cooking Tags AssetUserData Navigation")
class UHazeMovementComponent : UHazeMovementComponentBase
{
	default PrimaryComponentTick.bStartWithTickEnabled = true;
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_LastDemotable;

	access AlignmentAccess = protected, AddMovementAlignsWithGroundContact, RemoveMovementAlignsWithGroundContact, AddMovementAlignsWithAnyContact, RemoveMovementAlignsWithAnyContact, UBaseMovementResolver (inherited);
	access DataAccess = protected, UBaseMovementData (inherited), MovementDebug;
	access ResolverFunctionAccess = protected, UBaseMovementResolver (inherited);
	access SplineLock = protected, USplineLockComponent;
	access DebugAccess = protected, MovementDebug;
	access DefaultAccess = protected, * (editdefaults);

	UPROPERTY(EditDefaultsOnly, Category = "Movement Component")
	TSubclassOf<UFollowComponentMovementResolver> DefaultFollowMovementResolver;

	/**
	 * If true, movement is resolved as control on remote side too, even if the actor is networked.
	 * @see bool HasMovementControl()
	 */
	TInstigated<bool> bResolveMovementLocally;
	default bResolveMovementLocally.DefaultValue = false;

	/** If true, we can't pitch or roll */
	UPROPERTY(EditDefaultsOnly, Category = "Movement Component")
	access:DefaultAccess
	bool bConstrainRotationToHorizontalPlane = false;

	/** If true, the movement component will read the shape from the owner
	 * else, you need to call the 'SetupShapeComponent' manually
	 */
	UPROPERTY(EditDefaultsOnly, Category = "Movement Component")
	access:DefaultAccess
	bool bApplyInitialCollisionShapeAutomatically = true;

	/**
	 * Box collision is NOT recommended nor fully supported.
	 * Rotational sweeps are not a thing that exists, so when the box shape rotates, it
	 * will behave incorrectly in some situations.
	 * However, in some cases, this is acceptable to get a better shape for the object.
	 * Talk to the Movement guy to see if your case should be solved some other way or not.
	 */
	UPROPERTY(EditDefaultsOnly, Category = "Movement Component")
	access:DefaultAccess
	bool bAllowUsingBoxCollisionShape = false;

	UPROPERTY(EditDefaultsOnly, Category = "Movement Component")
	access:DefaultAccess
	bool bAllowSnappingPostSequence = false;

	/**
	 * When we follow/unfollow a component, how do we want to search for InheritVelocityComponents?
	 * @see UInheritVelocityComponent
	 */
	UPROPERTY(EditDefaultsOnly, Category = "Movement Component")
	EMovementFindInheritVelocityComponentMethod FindInheritVelocityComponentMethod = EMovementFindInheritVelocityComponentMethod::NoInheritVelocity;

	TInstigated<bool> ActiveConstrainRotationToHorizontalPlane;

	/** If true, the temporal menu will have the option to rerun movement on this component */
	UPROPERTY(EditAnywhere, Category = "Movement Component")
	bool bCanRerunMovement = false;

	protected TInstigated<float> InternalMovementSpeedMultiplier;
	default InternalMovementSpeedMultiplier.DefaultValue = 1.0;

	access:DataAccess
	FMovementDelta LastRequestedMovement;
	FMovementDelta LastRequestedImpulse;

	access:AlignmentAccess
	TInstigated<FMovementAlignWithImpactSettings> AlignWithImpacts;

	access:AlignmentAccess
	TInstigated<bool> FollowEdges;
	default FollowEdges.DefaultValue = false;

	access:AlignmentAccess
	FVector LastValidGroundAlignWorldUp = FVector::UpVector;

	protected FVector CachedWorldUp = FVector::UpVector;

	protected FMovementFallingData FallingState;

	protected TInstigated<FVector> InternalMovementInput;

	TInstigated<float> VerticalAttachmentOffset;

	// access:InputAccess
	// bool bHasTransientInput = false;
	// FVector TransientInput = FVector::ZeroVector;

	protected FQuat InternalFacingOrientation;
	private FQuat ExplicitFacingOrientation;
	private uint32 ExplicitFacingOrientationFrame;

	access:DataAccess
	UMovementStandardSettings InternalStandardSettings;

	access:DataAccess
	UMovementResolverSettings InternalResolverSettings;
	
	access:DebugAccess UMovementGravitySettings InternalGravitySettings;
	TInstigated<FMovementGravityDirection> InternalGravityDirection;
	
	access:DebugAccess
	TMap<AActor, FMovementInstigatorArray> InstigatedIgnoreActors;
	access:DebugAccess
	TArray<AActor> InternalIgnoreActors; // All the InstigatedIgnoreActors;

	access:DebugAccess
	TMap<UPrimitiveComponent, FMovementInstigatorArray> InstigatedIgnoreComponents;
	access:DebugAccess
	TArray<UPrimitiveComponent> InternalIgnoreComponents; // All the InstigatedIgnoreComponents;

	access:DataAccess
	FMovementContacts CurrentContacts;

	access:DataAccess
	FMovementContacts PreviousContacts;

	access:DataAccess
	FMovementAccumulatedImpacts AccumulatedImpacts;

	access:DataAccess
	FMovementAccumulatedImpacts FollowImpacts;

	protected TInstigated<FCustomMovementStatus> InstigatedCustomMovementStatus;

	protected UFollowComponentMovementData FollowComponentData = nullptr;
	protected FHazeMovementComponentAttachment CurrentFollow;
	protected FHazeMovementComponentAttachment CurrentReferenceFrame;

	// How fast we have been moved by follows this frame, resets automatically every frame
	protected FMovementFrameVelocity FollowFrameVelocity;
	protected FRelativeMovementAttachmentTransform PreviousTransformRelativeToFollow;
	protected FRelativeMovementAttachmentTransform PreviousTransformRelativeToReferenceFrame;
	protected FTransform PreviousFollowTransform;
	protected FVector PreviousFollowScale;
	protected FTransform PreviousFollowReferenceFrame;
	protected TArray<FHazeMovementComponentAttachment> FollowComponentAttachments;
	access:DefaultAccess TInstigated<EMovementFollowEnabledStatus> FollowEnablement;

	protected TArray<FMovementDeferredUnfollow> DeferredUnfollows;
	protected bool bIsApplyingDeferredUnfollows = false;
	private uint DeferredUnfollowID = 0;

	protected UHazeCrumbSyncedActorPositionComponent InternalNetworkSyncComponent;

	protected TArray<UBaseMovementData> InternalMovementDataTypes;
	protected TArray<UBaseMovementResolver> InternalMovementResolvers;
	protected TArray<FLinkedMovementResolverDataInformation> ResolverDataLinks;

	access:DebugAccess TArray<FMovementImpulse> Impulses;

	protected bool bHasPerformedAnyLocalMovementSinceReset = false;

	access:SplineLock
	USplineLockComponent SplineLockComponent;

	access:DebugAccess
	TArray<FInstigatedResolverExtension> InstigatedResolverExtensions;

	uint LastStuckFrame = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActiveConstrainRotationToHorizontalPlane.DefaultValue = bConstrainRotationToHorizontalPlane;
		InternalGravitySettings = UMovementGravitySettings::GetSettings(HazeOwner);
		InternalNetworkSyncComponent = UHazeCrumbSyncedActorPositionComponent::Get(HazeOwner);
		InternalFacingOrientation = Owner.GetActorQuat();

		InternalStandardSettings = UMovementStandardSettings::GetSettings(HazeOwner);
		InternalResolverSettings = UMovementResolverSettings::GetSettings(HazeOwner);

		if(DefaultFollowMovementResolver.IsValid())
		{
			auto FollowMovementDataType = Cast<UFollowComponentMovementResolver>(DefaultFollowMovementResolver.Get().DefaultObject).RequiredDataType;
			FollowComponentData = Cast<UFollowComponentMovementData>(SetupMovementData(FollowMovementDataType));
		}

#if EDITOR
		// All movement components should log the transform of the owner
		// so we can see how it moves.
		const int MaxFrames = 100000;
		auto TransformLogger = UTemporalLogTransformLoggerComponent::GetOrCreate(HazeOwner);
		TransformLogger.Initialize(MaxFrames);
		if(CanRerunMovement())
		{		
			TemporalLog::RegisterExtender(this, HazeOwner, "Movement", n"MovementTemporalRerunExtender");
			TemporalFrames.Reserve(MaxFrames);
		}
#endif
		
		if(bApplyInitialCollisionShapeAutomatically)
		{
			auto DefaultShape = UShapeComponent::Get(HazeOwner);
			if (DefaultShape != nullptr)
				SetupShapeComponent(DefaultShape);
		}

		HazeOwner.OnPostSequencerControl.AddUFunction(this, n"PostSequencerControl");

#if !RELEASE
		DevTogglesMovement::LogComponentValues.MakeVisible();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// If we didn't apply our deferred unfollows this frame (we didn't move), we must do so now to prevent following along for another frame
		ApplyDeferredUnfollows();

		// Reset our followed impacts at the end of the frame
		FollowImpacts.Reset();

#if !RELEASE
		// We always want to log extensions, because active extensions will be logged from MovementDebug
		// Any applied, but inactive resolvers will never be shown unless we log them here, making it confusing if they are applied or not
		LogExtensions();

		// Optional verbose component logging
		if(DevTogglesMovement::LogComponentValues.IsEnabled())
			LogComponent();

#endif // !RELEASE
	}

	UFUNCTION(BlueprintOverride)
	void OnReset(FVector NewWorldUp, bool bValidateGround, float OverrideTraceDistance)
	{
#if !RELEASE
		GetTemporalLog().Event("Reset Movement");
#endif

		CurrentContacts = FMovementContacts();
		PreviousContacts = FMovementContacts();
		AccumulatedImpacts.Reset();
		FollowImpacts.Reset();
		Impulses.Reset();
		InternalFacingOrientation = Owner.GetActorQuat();
		FallingState = FMovementFallingData();
		LastValidGroundAlignWorldUp = FVector::UpVector;
		LastRequestedMovement.Clear();
		LastRequestedImpulse.Clear();
		bHasPerformedAnyLocalMovementSinceReset = false;
		ExplicitFacingOrientationFrame = 0;

		if(!NewWorldUp.IsZero())
			StoreWorldUpInternal(NewWorldUp);

		if(bValidateGround)
			FindGround(OverrideTraceDistance);
	}

	/**
	 * Sweep down to find ground under the movement shape.
	 * @param OverrideTraceDistance If > 0, we sweep that distance instead of the default distance (1)
	 */
	protected void FindGround(float OverrideTraceDistance = -1)
	{
		// Default to no ground, since if we fail to find ground, we don't want to be grounded
		CurrentContacts.GroundContact = FMovementHitResult();

		const float WalkableSlopeAngleSetting = GetWalkableSlopeAngle();
		if(WalkableSlopeAngleSetting < 0)
		{
			// Can't find ground if nothing is walkable :c
			return;
		}

		FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(this);
		if(!TraceSettings.IsValid())
			return;

		const FVector TraceStart = ShapeComponent.WorldLocation + WorldUp * GetShapeSizeForMovement() * 2;

		const float TraceDistance = OverrideTraceDistance > 0 ? OverrideTraceDistance : GetGroundedSafetyMargin();
		const FVector TraceEnd = ShapeComponent.WorldLocation - WorldUp * TraceDistance;
		
		const FHitResult GroundHit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);
		
#if !RELEASE
		const FTemporalLog TemporalLog = GetGroundPage().Section("Find Ground");
		TemporalLog.HitResults("Ground Hit", GroundHit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
#endif

		if(GroundHit.IsValidBlockingHit())
		{
			const FVector ImpactNormal = GroundHit.ImpactNormal;
			const float ImpactAngle = WorldUp.GetAngleDegreesTo(ImpactNormal);
			const float HitResultWalkableSlopeAngle = GroundHit.Component.GetWalkableSlopeAngle(WalkableSlopeAngleSetting);

			if(HitResultWalkableSlopeAngle >= 0 && ImpactAngle < HitResultWalkableSlopeAngle)
			{
				CurrentContacts.GroundContact = FMovementHitResult(GroundHit, 0);
				CurrentContacts.GroundContact.Type = EMovementImpactType::Ground;
				CurrentContacts.GroundContact.bIsWalkable = GroundHit.Component.HasTag(ComponentTags::Walkable);

				// Make sure that the previous ground is the current ground
				// so we don't perform stepdowns when starting
				OverridePreviousGroundContactWithCurrent();
				return;
			}
		}

		// No ground found, we are airborne
		CurrentContacts.GroundContact = FMovementHitResult(GroundHit, 0);
	}

	/**
	 * Place the actor on the ground, using the movement shape.
	 * @param bValidateGround Should we do a ground check to find valid ground?
	 * @param OverrideTraceDistance If > 0, we sweep that distance instead of the default distance (1)
	 * @param bLerpVerticalOffset Do we want to smoothly lerp away the vertical offset to prevent a visual snap?
	 */
	void SnapToGround(bool bValidateGround = true, float OverrideTraceDistance = -1, bool bLerpVerticalOffset = false)
	{
		if(HazeOwner.bIsControlledByCutscene)
			return;

#if !RELEASE
		GetGroundPage().Event("SnapToGround");

		const FTemporalLog TemporalLog = GetGroundPage().Section("SnapToGround");
		TemporalLog.Value("Validate Ground", bValidateGround);
#endif

		if(bValidateGround)
			FindGround(OverrideTraceDistance);

		if(!GroundContact.IsAnyGroundContact())
		{
#if !RELEASE
			GetGroundPage().Event("Snap to ground failed! No valid ground found.");
#endif
			return;
		}

#if !RELEASE
		LogMovementShapeAtLocation(TemporalLog, "Before Snap", Owner.ActorLocation, FLinearColor::Red);
#endif

		if(bLerpVerticalOffset)
			SnapToLocationWithVerticalLerp(GroundContact.Location);
		else
			Owner.SetActorLocation(GroundContact.Location);

#if !RELEASE
		LogMovementShapeAtLocation(TemporalLog, "After Snap", Owner.ActorLocation, FLinearColor::Green);
#endif
	}

	/**
	 * Snap to Location, but apply a lerp over movement.
	 * This means that we only lerp when we move, and based on how fast we are moving, instead of a constant duration.
	 * This performs the same vertical lerp that would occur with SnapToGround() using bLerpVerticalOffset, but without the ground trace.
	 */
	void SnapToLocationWithVerticalLerp(FVector Location, float LerpSpeed = 0.2)
	{
#if !RELEASE
		const FTemporalLog TemporalLog = GetTemporalLog();
		TemporalLog.Event("SnapToLocationWithVerticalLerp");
#endif

		const FVector PreSnapVerticalLocation = Owner.ActorLocation.ProjectOnToNormal(WorldUp);
		if (Owner.ActorLocation.Equals(Location))
			return;

		Owner.SetActorLocation(Location);

		UHazeOffsetComponent RootOffsetComponent = UHazeOffsetComponent::Get(Owner, n"RootOffsetComponent");
		if(RootOffsetComponent != nullptr)
		{
			const FVector PostSnapVerticalLocation = Owner.ActorLocation.ProjectOnToNormal(WorldUp);
			const FVector RelativeVerticalLocation = PreSnapVerticalLocation - PostSnapVerticalLocation;

			const FInstigator Instigator = FInstigator(this, n"SnapToGround");
			RootOffsetComponent.SnapToRelativeLocation(Instigator, RootOffsetComponent.AttachParent, RelativeVerticalLocation);
			RootOffsetComponent.ResetOffsetWithActorMovement(Instigator, LerpSpeed);
		}
	}

	void ClearVerticalLerp()
	{
		UHazeOffsetComponent RootOffsetComponent = UHazeOffsetComponent::Get(Owner, n"RootOffsetComponent");
		if(RootOffsetComponent == nullptr)
			return;

		const FInstigator Instigator = FInstigator(this, n"SnapToGround");
		RootOffsetComponent.ClearOffset(Instigator);
	}

	UFUNCTION()
	protected void PostSequencerControl(FHazePostSequencerControlParams Params)
	{
		if(HasControl())
		{
			if(Params.bSmoothSnapToGround && bAllowSnappingPostSequence)
			{
				// We crumb send the snap, this allows some positional crumbs
				// to arrive to the remote before the snap occurs
				CrumbSnapToGroundPostSequencer();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSnapToGroundPostSequencer()
	{
		if (!Owner.HasActorBegunPlay())
			return;
		SnapToGround(true, 10, true);
		InternalNetworkSyncComponent.TransitionSync(this);
	}

	protected void BroadcastAllImpactCallbacks()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnCollisionSizeChanged()
	{
#if !RELEASE
		GetTemporalLog().Event("Collision Size Changed");
#endif

		bHasPerformedAnyLocalMovementSinceReset = false;

		if(!bAllowUsingBoxCollisionShape)
		{
			// It is possible to allow boxes but it is a very complicated task to make the movement system handle these type of shapes / Tyko
			// I added an override anyway because it seems to work alright. If any issues arise, we will investigate and reassess how valid box collisions are / Filip B
			devCheck(!ShapeComponent.IsA(UBoxComponent), f"Using a box collision shape for the movement component is not supported by the movement system. {Owner}");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnPostMovement()
	{
		// Reset all movement state that should not be kept into the next frame
		ClearPendingImpulses();

		// Apply changes from this frames movement
		ApplyImpacts();
		
		// This is the first frame since a reset
		// So we need to update all the previous values
		if(!bHasPerformedAnyMovementSinceReset)
		{
			PreviousContacts = CurrentContacts;
		}

		bHasPerformedAnyLocalMovementSinceReset = true;	
	}

	protected void ApplyImpacts()
	{
#if !RELEASE
		MovementDebug::LogImpactsPage(this);
#endif
	}

	void AddComponentSpecificDebugInfo(FTemporalLog& TemporalLog) const{}

	bool GetbHasPerformedAnyMovementSinceReset() const property
	{
		return bHasPerformedAnyLocalMovementSinceReset;
	}
	
	access:DataAccess
	float GetShapeSizeForMovement() const
	{
		auto Capsule = Cast<UCapsuleComponent>(GetShapeComponent());
		if(Capsule != nullptr)
		{
			return Capsule.GetScaledCapsuleRadius();
		}

		auto Sphere = Cast<USphereComponent>(GetShapeComponent());
		if(Sphere != nullptr)
		{
			return Sphere.GetScaledSphereRadius();
		}

		auto Box = Cast<UBoxComponent>(GetShapeComponent());
		if(Box != nullptr)
		{
			return Box.GetScaledBoxExtent().Size();
		}

		devError(f"Shape type for {GetShapeComponent().Class} not implemented in movement component.");
		return 0.0;
	}

	FQuat FinalizeRotation(FQuat Rotation, FVector UpVector) const
	{
		if(ActiveConstrainRotationToHorizontalPlane.Get())
			return FQuat::MakeFromZX(UpVector, Rotation.GetForwardVector());
		else
			return Rotation;
	}

	access:ResolverFunctionAccess
	void SetContactsAndImpactsInternal(FMovementContacts NewContacts, FVector GroundAlignmentWorldUp, FMovementAccumulatedImpacts& NewImpacts)
	{
		// Store the previous contacts
		PreviousContacts = CurrentContacts;
		FallingState.bWasFalling = FallingState.bIsFalling;
		LastValidGroundAlignWorldUp = GroundAlignmentWorldUp;

		// Change the current contacts
		CurrentContacts = NewContacts;
		CurrentContacts.CustomStatus = InstigatedCustomMovementStatus.Get();
		StoreWorldUpInternal(-GetGravityDirection());

		// Store all impacts we got during this resolve
		AccumulatedImpacts.Swap(NewImpacts);

		// Make sure we don't replace the follow impacts
		AccumulatedImpacts.AppendAccumulatedImpacts(FollowImpacts);
	}

	FHazeTraceShape GetCollisionShape() const property
	{
		return FHazeTraceShape::MakeFromComponent(GetShapeComponent());
	}

	UFUNCTION(BlueprintOverride)
	void OnFacingDirectionChanged(FQuat WantedFacingDirection)
	{
		InternalFacingOrientation = FinalizeRotation(WantedFacingDirection, WorldUp);
		ExplicitFacingOrientation = InternalFacingOrientation;
		ExplicitFacingOrientationFrame = Time::FrameNumber;
	}

	float GetGravityMultiplier() const property
	{
		return InternalGravitySettings.GravityScale;
	}

	float GetTerminalVelocity() const property
	{
		if(InternalGravitySettings.TerminalVelocity >= 0)
			return InternalGravitySettings.TerminalVelocity;
		else
			return -1;
	}

	float GetGravityForce() const property 
	{
		float FinalForce = 0;

		if(InternalGravitySettings.bUseWorldSettingsGravity)
			FinalForce = Math::Abs(World.GetWorldSettings().GlobalGravityZ);
		else
			FinalForce =  Math::Abs(InternalGravitySettings.GravityAmount);

		return FinalForce * InternalGravitySettings.GravityScale;
	}

	FVector GetGravityDirection() const property
	{
		FMovementGravityDirection GravityDir = InternalGravityDirection.Get();
		
		switch(GravityDir.Mode)
		{
			case EMovementGravityDirectionMode::WorldUp:
			{
				return -WorldUp;
			}

			case EMovementGravityDirectionMode::Direction:
			{
				check(GravityDir.Direction.IsUnit(), "Invalid GravityDirection!");

				if(GravityDir.Direction.IsNearlyZero())
					return -WorldUp;

				return GravityDir.Direction;
			}

			case EMovementGravityDirectionMode::TargetComponent:
			{
				if(!ensure(IsValid(GravityDir.TargetComponent), "Invalid TargetComponent used as gravity target! Don't destroy an actor used as a gravity target without clearing the override first."))
					return -WorldUp;

				const FVector DirectionToComponent = (GravityDir.TargetComponent.WorldLocation - HazeOwner.ActorLocation).GetSafeNormal();

				if(DirectionToComponent.IsNearlyZero())
					return -WorldUp;

				return DirectionToComponent;
			}

			case EMovementGravityDirectionMode::AlignWithGround:
			{
				if(!ensure(LastValidGroundAlignWorldUp.IsUnit(), "Invalid LastValidGroundAlignWorldUp used as GravityDirection!"))
					return LastValidGroundAlignWorldUp.GetSafeNormal(ResultIfZero = -WorldUp);

				return -LastValidGroundAlignWorldUp;
			}
		}
	}

	FVector GetGravity() const property
	{
		return GetGravityDirection() * GetGravityForce();
	}

	FVector GetPendingImpulse() const property
	{
		FVector TotalImpulse = FVector::ZeroVector;
		for(auto Impulse : Impulses)
		{
			// If the impulse is older than last frame, ignore it
			// It will be cleared in OnPostMovement
			if(Impulse.AddedFrame < Time::GetFrameNumber() - 1)
				continue;
			
			TotalImpulse += Impulse.Impulse;
		}

		return TotalImpulse;
	}

	FVector GetPendingImpulseWithInstigator(FInstigator Instigator) const
	{
		FVector TotalImpulse = FVector::ZeroVector;
		for(auto Impulse : Impulses)
		{
			if(Impulse.Instigator != Instigator)
				continue;

			// If the impulse is older than last frame, ignore it
			// It will be cleared in OnPostMovement
			if(Impulse.AddedFrame < Time::GetFrameNumber() - 1)
				continue;

			TotalImpulse += Impulse.Impulse;
		}
		return TotalImpulse;
	}

	const FVector& GetWorldUp() const property
	{
		return CachedWorldUp;
	}

	protected void StoreWorldUpInternal(FVector NewWorldUp)
	{
		if(NewWorldUp.Equals(CachedWorldUp))
			return;

		CachedWorldUp = NewWorldUp;
		CacheWorldUpInternal(NewWorldUp);
	
#if EDITOR
		devCheck(CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't change the world up direction'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
#endif
	}

	const FQuat& GetTargetFacingRotationQuat() const property
	{
		return InternalFacingOrientation;
	}

	const FQuat& GetExplicitTargetFacingRotation()
	{
		return ExplicitFacingOrientation;
	}

	bool HasExplicitTargetFacingRotation() const
	{
		return ExplicitFacingOrientationFrame >= Time::FrameNumber - 1;
	}

	void SnapRemoteCrumbSyncedPosition()
	{
		if (!HasControl())
			return;

		if(!ValidateNetworkCall(n"SnapRemoteCrumbSyncedPosition"))
			return;

		InternalNetworkSyncComponent.SnapRemote();
	}

	void TransitionCrumbSyncedPosition(FInstigator Instigator)
	{
		if(!ValidateNetworkCall(n"TransitionCrumbSyncedPosition"))
			return;

		InternalNetworkSyncComponent.TransitionSync(Instigator);
	}

	FHazeSyncedActorPosition GetCrumbSyncedPosition() const
	{
		if(!ValidateNetworkCall(n"GetCrumbSyncedPosition"))
			return FHazeSyncedActorPosition();

		return InternalNetworkSyncComponent.GetPosition();
	}

	FHazeSyncedActorPosition GetLatestAvailableSyncedPosition(float&out OutCrumbTrailTime) const
	{
		if(!ValidateNetworkCall(n"GetLatestAvailableSyncedPosition"))
			return FHazeSyncedActorPosition();

		FHazeSyncedActorPosition Position;
		InternalNetworkSyncComponent.GetLatestAvailableData(Position, OutCrumbTrailTime);

		return Position;
	}

	bool HasAnyDataInCrumbTrail() const
	{
		if(!ValidateNetworkCall(n"HasAnyDataInCrumbTrail"))
			return false;

		return InternalNetworkSyncComponent.HasAnyDataInCrumbTrail();
	}

	void ApplyCrumbSyncedRelativePosition(
		FInstigator Instigator,
		USceneComponent RelativeToComponent,
		FName Socket = NAME_None,
		EInstigatePriority Priority = EInstigatePriority::Normal,
		bool bRelativeRotation = true)
	{
		if(!ValidateNetworkCall(n"ApplyCrumbSyncedRelativePosition"))
			return;

		InternalNetworkSyncComponent.ApplyRelativePositionSync(
			Instigator,
			RelativeToComponent,
			Socket,
			Priority,
			bRelativeRotation
		);
	}

	void ClearCrumbSyncedRelativePosition(FInstigator Instigator)
	{
		if(!ValidateNetworkCall(n"ClearCrumbSyncedRelativePosition"))
			return;

		InternalNetworkSyncComponent.ClearRelativePositionSync(Instigator);
	}

	private bool ValidateNetworkCall(FName FunctionName) const
	{
		if(bResolveMovementLocally.Get())
		{
			devError(f"{HazeOwner.Name} has bResolveMovementLocally set to true, so you can't call {FunctionName} on its movement component.");
			return false;
		}

		if (InternalNetworkSyncComponent == nullptr)
		{
			devError(f"{HazeOwner.Name} is missing a UHazeCrumbSyncedActorPositionComponent so you can't call {FunctionName} on its movement component.");
			return false;
		}

		return true;
	}

	void ApplyMovementInput(FVector InputVector, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Low)
	{
		InternalMovementInput.Apply(InputVector, Instigator, Priority);

		if (InternalNetworkSyncComponent != nullptr)
			InternalNetworkSyncComponent.SetSyncedMovementInput(InternalMovementInput.Get());
	}

	void ClearMovementInput(FInstigator Instigator)
	{
		InternalMovementInput.Clear(Instigator);

		if (InternalNetworkSyncComponent != nullptr)
			InternalNetworkSyncComponent.SetSyncedMovementInput(InternalMovementInput.Get());
	}

	FVector GetMovementInput() const property
	{
		FVector InputVector = InternalMovementInput.Get();
		if(ActiveConstrainRotationToHorizontalPlane.Get())
			return InputVector.VectorPlaneProject(WorldUp).GetSafeNormal() * InputVector.Size();
		else
			return InputVector;
	}

	FVector GetNonLockedMovementInput() const property
	{
		return GetMovementInput();
	}

	void OverridePreviousGroundContactWithCurrent()
	{
		PreviousContacts.GroundContact = CurrentContacts.GroundContact;
	}

	FVector GetSyncedMovementInputForAnimationOnly() const property
	{
		if (HasMovementControl() || InternalNetworkSyncComponent == nullptr)
			return GetMovementInput();
		else
			return InternalNetworkSyncComponent.GetPosition().MovementInput;
	}

	FVector GetSyncedLocalSpaceMovementInputForAnimationOnly() const property
	{
		return Owner.ActorTransform.InverseTransformVectorNoScale(GetSyncedMovementInputForAnimationOnly());
	}

	const FVector& GetCurrentGroundNormal() const property
	{
		return GroundContact.Normal;
	}

	const FVector& GetCurrentGroundImpactNormal() const property
	{
		return GroundContact.ImpactNormal;
	}

	/** Current state is  ground */
	bool IsOnAnyGround() const
	{
		return IsOnWalkableGround() || IsOnSlidingGround();
	}

	/** Current state is on walkable ground */
	bool IsOnWalkableGround() const
	{
		if(CurrentContacts.HasCustomStatus())
			return false;

		return CurrentContacts.GroundContact.IsWalkableGroundContact();
	}

	/** Current state is on walkable ground */
	bool IsOnSlidingGround() const
	{
		if(CurrentContacts.HasCustomStatus())
			return false;

		return CurrentContacts.GroundContact.IsSlidingGroundContact();
	}
	
	/** Current state is in air */
	bool IsInAir() const
	{
		if(CurrentContacts.HasCustomStatus())
			return false;

		return !CurrentContacts.GroundContact.IsAnyGroundContact();
	}

	/** Previous state was on walkable ground */
	bool WasOnWalkableGround() const
	{
		if(PreviousContacts.HasCustomStatus())
			return false;

		return PreviousContacts.GroundContact.IsWalkableGroundContact();
	}

	/** Previous state was on unwalkable ground */
	bool WasOnSlidingGround() const
	{
		if(PreviousContacts.HasCustomStatus())
			return false;

		return PreviousContacts.GroundContact.IsSlidingGroundContact();
	}
	
	/** Previous state was in air */
	bool WasInAir() const
	{
		if(PreviousContacts.HasCustomStatus())
			return false;

		return !PreviousContacts.GroundContact.IsAnyGroundContact();
	}

	UFUNCTION(BlueprintPure)
	FMovementFallingData GetFallingData() const property
	{
		return FallingState;
	}

	bool IsFalling() const
	{
		return FallingState.bIsFalling;
	}

	bool NewStateIsFalling() const
	{
		return FallingState.bIsFalling && !FallingState.bWasFalling;
	}

	bool WasFalling() const
	{
		return FallingState.bWasFalling;
	}

	bool HasImpulse(float ErrorTolerance = KINDA_SMALL_NUMBER, FInstigator WithInstigator = FInstigator()) const
	{
		if(!WithInstigator.IsValid())
			return !GetPendingImpulse().IsNearlyZero(ErrorTolerance);
		else
			return !GetPendingImpulseWithInstigator(WithInstigator).IsNearlyZero(ErrorTolerance);
	}

	bool HasUpwardsImpulse(float ErrorTolerance = KINDA_SMALL_NUMBER) const
	{
		return GetPendingImpulse().DotProduct(WorldUp) > ErrorTolerance;
	}

	float GetVerticalSpeed() const property
	{
		return Velocity.DotProduct(WorldUp);
	}
		
	/** We were not on walkable ground, but now we are */
	bool NewStateIsOnWalkableGround() const
	{
		const bool bIsOnValidGround = IsOnWalkableGround();
		const bool bWasOnValidGround = WasOnWalkableGround();
		
		return bIsOnValidGround && !bWasOnValidGround;
	}

	/** We were not on sliding ground, but now we are */
	bool NewStateIsOnSlidingGround() const
	{
		const bool bIsOnValidGround = IsOnSlidingGround();
		const bool bWasOnValidGround = WasOnSlidingGround();

		return bIsOnValidGround && !bWasOnValidGround;
	}
	
	/** Did we used to be on the ground, but no longer */
	bool NewStateIsInAir() const
	{
		const bool bIsInAir = IsInAir();
		const bool bWasInAir = WasInAir();

		return bIsInAir && !bWasInAir;
	}

	/** Did the ceiling contact change from last frame to this frame */
	bool CeilingContactChanged() const
	{
		return HasContactChangedInternal(CurrentContacts.CeilingContact, PreviousContacts.CeilingContact);
	}
	
	/** Did the wall contact change from last frame to this frame */
	bool WallContactChanged() const
	{
		return HasContactChangedInternal(CurrentContacts.WallContact, PreviousContacts.WallContact);
	}

	/** Did the ground contact change from last frame to this frame */
	bool GroundContactChanged() const
	{
		return HasContactChangedInternal(CurrentContacts.GroundContact, PreviousContacts.GroundContact);
	}	

	bool HasAnyValidBlockingContacts() const
	{
		return CurrentContacts.HasAnyValidBlockingContacts();
	}

	private bool HasContactChangedInternal(FMovementHitResult From, FMovementHitResult To) const
	{
		if(From.Component != To.Component)
			return true;

		if(From.Type != To.Type)
			return true;

		if(From.bIsWalkable != To.bIsWalkable)
			return true;
		
		return false;
	}

	/**
	 * Are we currently in contact with ground?
	 * NOTE: This is not the same as if we have impacted ground during the last move. @see HasImpactedGround()
	 */
	bool HasGroundContact() const
	{
		return CurrentContacts.GroundContact.IsAnyGroundContact();
	}

	/**
	 * Are we currently in contact with a wall?
	 * NOTE: This is not the same as if we have impacted a wall during the last move. @see HasImpactedWall()
	 */
	bool HasWallContact() const
	{
		return CurrentContacts.WallContact.IsWallImpact();
	}

	/**
	 * Are we currently in contact with a ceiling?
	 * NOTE: This is not the same as if we have impacted a ceiling during the last move. @see HasImpactedWall()
	 */
	bool HasCeilingContact() const
	{
		return CurrentContacts.CeilingContact.IsCeilingImpact();
	}

	/**
	 * Are we grounded, but on an unstable edge?
	 */
	bool HasUnstableGroundContactEdge() const
	{
		if(!HasGroundContact())
			return false;

		const FMovementEdge& EdgeResult = CurrentContacts.GroundContact.EdgeResult;
		if(!EdgeResult.IsEdge())
			return false;

		if(!EdgeResult.IsUnstable())
			return false;

		if(CurrentContacts.GroundContact.IsStepupGroundContact())
			return false;

		return true;
	}

	/**
	 * Were we touching ground the previous frame?
	 * NOTE: This is not the same as if we had any ground impacts the previous frame.
	 * If this is required, we can add a function for it.
	 */
	bool PreviousHadGroundContact() const
	{
		return PreviousContacts.GroundContact.IsAnyGroundContact();
	}

	/**
	 * Were we touching a wall the previous frame?
	 * NOTE: This is not the same as if we had any wall impacts the previous frame.
	 * If this is required, we can add a function for it.
	 */
	bool PreviousHadWallContact() const
	{
		return PreviousContacts.WallContact.IsWallImpact();
	}

	/**
	 * Were we touching a ceiling the previous frame?
	 * NOTE: This is not the same as if we had any ceiling impacts the previous frame.
	 * If this is required, we can add a function for it.
	 */
	bool PreviousHadCeilingContact() const
	{
		return PreviousContacts.CeilingContact.IsCeilingImpact();
	}

	/**
	 * Get the first contact that is valid of any type.
	 * @param Order The priority order used when returning valid contacts.
	 * @return True if a valid contact was found.
	 */
	bool GetAnyValidContact(FMovementHitResult&out OutContact, EMovementAnyContactOrder Order = EMovementAnyContactOrder::GroundWallCeiling) const no_discard
	{
		return CurrentContacts.GetAnyValidContact(OutContact, Order);
	}

	const FMovementHitResult& GetContact(EMovementImpactType ImpactType) const
	{
		return CurrentContacts.GetContact(ImpactType);
	}

	const FMovementHitResult& GetGroundContact() const property
	{
		return CurrentContacts.GroundContact;
	}

	const FMovementHitResult& GetWallContact() const property
	{
		return CurrentContacts.WallContact;
	}

	const FMovementHitResult& GetCeilingContact() const property
	{
		return CurrentContacts.CeilingContact;
	}

	const FMovementHitResult& GetPreviousGroundContact() const property
	{
		return PreviousContacts.GroundContact;
	}

	const FMovementHitResult& GetPreviousWallContact() const property
	{
		return PreviousContacts.WallContact;
	}

	const FMovementHitResult& GetPreviousCeilingContact() const property
	{
		return PreviousContacts.CeilingContact;
	}

	void OverrideGroundContact(FHitResult NewGroundContact, FInstigator Instigator)
	{
#if EDITOR
		devCheck(CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't OverrideGroundContact'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
#endif

		CurrentContacts.GroundContact = FMovementHitResult(NewGroundContact, 0);

		if(NewGroundContact.IsValidBlockingHit())
			CurrentContacts.GroundContact.Type = EMovementImpactType::Ground;
		else if(NewGroundContact.bStartPenetrating)
			CurrentContacts.GroundContact.Type = EMovementImpactType::Invalid;
		else
			CurrentContacts.GroundContact.Type = EMovementImpactType::NoImpact;

#if !RELEASE
		GetTemporalLog().Event(f"Ground Contact overridden by {Instigator}");
		CurrentContacts.GroundContactOverrideInstigators.Add(Instigator);
		MovementDebug::LogContactsPage(this);
#endif
	}

	void OverrideWallContact(FHitResult NewWallContact, FInstigator Instigator)
	{
#if EDITOR
		devCheck(CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't OverrideWallContact'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
#endif

		CurrentContacts.WallContact = FMovementHitResult(NewWallContact, 0);

		if(NewWallContact.IsValidBlockingHit())
			CurrentContacts.WallContact.Type = EMovementImpactType::Wall;
		else if(NewWallContact.bStartPenetrating)
			CurrentContacts.WallContact.Type = EMovementImpactType::Invalid;
		else
			CurrentContacts.WallContact.Type = EMovementImpactType::NoImpact;

#if !RELEASE
		GetTemporalLog().Event(f"Wall Contact overridden by {Instigator}");
		CurrentContacts.WallContactOverrideInstigators.Add(Instigator);
		MovementDebug::LogContactsPage(this);
#endif
	}

	void OverrideCeilingContact(FHitResult NewCeilingContact, FInstigator Instigator)
	{
#if EDITOR
		devCheck(CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't OverrideCeilingContact'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
#endif

		CurrentContacts.CeilingContact = FMovementHitResult(NewCeilingContact, 0);

		if(NewCeilingContact.IsValidBlockingHit())
			CurrentContacts.CeilingContact.Type = EMovementImpactType::Ceiling;
		else if(NewCeilingContact.bStartPenetrating)
			CurrentContacts.CeilingContact.Type = EMovementImpactType::Invalid;
		else
			CurrentContacts.CeilingContact.Type = EMovementImpactType::NoImpact;

#if !RELEASE
		GetTemporalLog().Event(f"Ceiling Contact overridden by {Instigator}");
		CurrentContacts.CeilingContactOverrideInstigators.Add(Instigator);
		MovementDebug::LogContactsPage(this);
#endif
	}


	FMovementEdge GetGroundContactEdge() const property
	{
		return CurrentContacts.GroundContact.EdgeResult;
	}

	/**
	 * Did we have any impacts at all during the last move?
	 */
	bool HasAnyValidBlockingImpacts() const
	{
		return AccumulatedImpacts.HasImpactedAnything();
	}

	/**
	 * Did we impact ground during the last move?
	 */
	bool HasImpactedGround() const
	{
		return AccumulatedImpacts.HasImpactedGround();
	}

	/**
	 * Did we impact a wall during the last move?
	 */
	bool HasImpactedWall() const
	{
		return AccumulatedImpacts.HasImpactedWall();
	}

	/**
	 * Did we impact a ceiling during the last move?
	 */
	bool HasImpactedCeiling() const
	{
		return AccumulatedImpacts.HasImpactedCeiling();
	}

	/**
	 * Get all impacts from the last move.
	 */
	const TArray<FMovementHitResult>& GetAllImpacts() const property
	{
		return AccumulatedImpacts.GetAllImpacts();
	}

	/**
	 * Get all ground impacts from the last move.
	 */
	const TArray<FHitResult>& GetAllGroundImpacts() const property
	{
		return AccumulatedImpacts.GetGroundImpacts();
	}

	/**
	 * Get all wall impacts from the last move.
	 */
	const TArray<FHitResult>& GetAllWallImpacts() const property
	{
		return AccumulatedImpacts.GetWallImpacts();
	}

	/**
	 * Get all ceiling impacts from the last move.
	 */
	const TArray<FHitResult>& GetAllCeilingImpacts() const property
	{
		return AccumulatedImpacts.GetCeilingImpacts();
	}

	/**
	 * Get the first impact that is valid of any type.
	 * @param Order The priority order used when returning valid impacts.
	 * @return True if a valid impact was found.
	 */
	bool GetFirstValidImpact(FHitResult&out OutImpact, EMovementAnyContactOrder Order = EMovementAnyContactOrder::GroundWallCeiling) const no_discard
	{
		return AccumulatedImpacts.GetFirstValidImpact(OutImpact, Order);
	}

	FMovementAlignWithImpactSettings GetImpactAlignmentSettings() const
	{
		return AlignWithImpacts.Get();
	}

	bool ShouldFollowEdges() const
	{
		return FollowEdges.Get();
	}

	FVector GetLastRequestedVelocityWithoutImpulse() const
	{
		return LastRequestedMovement.Velocity;
	}

	bool IsIgnoringActor(AActor Actor) const
	{
		return InternalIgnoreActors.Contains(Actor);
	}

	/** The actor will be ignore by the movement component */
	void AddMovementIgnoresActor(FInstigator Instigator, AActor Actor)
	{
		if(Actor == nullptr)
			return;

		// Make sure we don't have any nullptr actors
		InstigatedIgnoreActors.Remove(nullptr);

		auto& Index = InstigatedIgnoreActors.FindOrAdd(Actor);
		devCheck(!Index.Instigators.Contains(Instigator), f"{Instigator.ToString()} has already added {Actor} to MovementIgnore");
		Index.Instigators.Add(Instigator);

		RemakeInternalIgnoreActors();
	}

	void AddMovementIgnoresActors(FInstigator Instigator, TArray<AActor> Actors)
	{
		bool bWasModified = false;
		
		// Make sure we don't have any nullptr actors
		if(InstigatedIgnoreActors.Remove(nullptr))
			bWasModified = true;

		for(auto It : Actors)
		{
			if(It == nullptr)
				continue;

			auto& Index = InstigatedIgnoreActors.FindOrAdd(It);
			devCheck(!Index.Instigators.Contains(Instigator), f"{Instigator.ToString()} has already added {It} to MovementIgnore");
			Index.Instigators.Add(Instigator);
			bWasModified = true;
		}
		
		if(bWasModified)
			RemakeInternalIgnoreActors();
	}

	/** Remove all the actors that the instigator wants to ignore. */
	void RemoveMovementIgnoresActor(FInstigator Instigator)
	{
		bool bWasModified = false;

		// Make sure we don't have any nullptr actors
		if(InstigatedIgnoreActors.Remove(nullptr))
			bWasModified = true;

		for(auto It : InstigatedIgnoreActors)
		{
			if(It.Value.Instigators.RemoveSingleSwap(Instigator) >= 0)
				bWasModified = true;
		}

		if(bWasModified)
			RemakeInternalIgnoreActors();
	}
	
	// Collect all the actors we should ignore from all the instigators
	private void RemakeInternalIgnoreActors()
	{
		InternalIgnoreActors.Reset();
		for(auto It : InstigatedIgnoreActors)
		{
			if(It.Value.Instigators.Num() == 0)
				continue;

			InternalIgnoreActors.Add(It.Key);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool GetIgnoreActors(TArray<AActor>& ActorsToIgnore) const
	{
		ActorsToIgnore = InternalIgnoreActors;
		return InternalIgnoreActors.Num() > 0;
	}

	bool IsIgnoringComponent(UPrimitiveComponent Component) const
	{
		return InternalIgnoreComponents.Contains(Component);
	}

	/** The component will be ignore by the movement component */
	void AddMovementIgnoresComponent(FInstigator Instigator, UPrimitiveComponent Component)
	{
		if(Component == nullptr)
			return;

		// Make sure we don't have any nullptr components
		InstigatedIgnoreComponents.Remove(nullptr);

		auto& Index = InstigatedIgnoreComponents.FindOrAdd(Component);
		devCheck(!Index.Instigators.Contains(Instigator), f"{Instigator.ToString()} has already added {Component} to MovementIgnore");
		Index.Instigators.Add(Instigator);

		RemakeInternalIgnoreComponents();
	}

	void AddMovementIgnoresComponents(FInstigator Instigator, TArray<UPrimitiveComponent> Components)
	{
		bool bWasModified = false;

		// Make sure we don't have any nullptr components
		if(InstigatedIgnoreComponents.Remove(nullptr))
			bWasModified = true;

		for(auto It : Components)
		{
			if(It == nullptr)
				continue;

			auto& Index = InstigatedIgnoreComponents.FindOrAdd(It);
			devCheck(!Index.Instigators.Contains(Instigator), f"{Instigator.ToString()} has already added {It} to MovementIgnore");
			Index.Instigators.Add(Instigator);
			bWasModified = true;
		}
		
		if(bWasModified)
			RemakeInternalIgnoreComponents();
	}

	/** Remove all the components that the instigator wants to ignore. */
	void RemoveMovementIgnoresComponents(FInstigator Instigator)
	{
		bool bWasModified = false;

		// Make sure we don't have any nullptr components
		if(InstigatedIgnoreComponents.Remove(nullptr))
			bWasModified = true;

		for(auto It : InstigatedIgnoreComponents)
		{
			if(It.Value.Instigators.RemoveSingleSwap(Instigator) >= 0)
				bWasModified = true;
		}

		if(bWasModified)
			RemakeInternalIgnoreComponents();
	}

	// Collect all the components we should ignore from all the instigators
	private void RemakeInternalIgnoreComponents()
	{
		InternalIgnoreComponents.Reset();
		for(auto It : InstigatedIgnoreComponents)
		{
			if(It.Value.Instigators.Num() == 0)
				continue;

			InternalIgnoreComponents.Add(It.Key);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool GetIgnoreComponents(TArray<UPrimitiveComponent>& ComponentsToIgnore) const
	{
		ComponentsToIgnore = InternalIgnoreComponents;
		return InternalIgnoreComponents.Num() > 0;
	}

	void StartFalling(FVector StartLocation)
	{
		FallingState.bIsFalling = true;
		FallingState.StartLocation = StartLocation;
		FallingState.StartTime = Time::GameTimeSeconds;
	}

	void StopFalling(FVector StopLocation, FVector EndVelocity)
	{
		FallingState.bIsFalling = false;
		FallingState.EndLocation = StopLocation;
		FallingState.EndTime = Time::GameTimeSeconds;
		FallingState.EndVelocity = EndVelocity;
	}

	bool PrepareMove(UBaseMovementData DataType, FVector CustomWorldUp = FVector::ZeroVector)
	{
		if(HasMovedThisFrame())
			return false;

#if EDITOR
		ValidateTickGroup("PrepareMove");
#endif

#if !RELEASE
		devCheck(DataType.DebugPreparedFrame == 0, f"Movedata {GetName()} was prepared by {DataType.DebugMoveInstigator} but never applied to the movement component.");
		devCheck(CustomWorldUp.IsNearlyZero() || CustomWorldUp.IsUnit(), f"Movedata {GetName()} was prepared by {DataType.DebugMoveInstigator} with an invalid world up.");
		devCheck(Owner.AttachParentActor == nullptr, f"{Owner} has performed a move while attached to {Owner.AttachParentActor}. This is not allowed. Attach the player by using the 'FollowComponentMovement' functions instead");
		devCheck(CanPrepareMove(), "Failed to prepare move.");
#endif

		// If we have any unfollows deferred from the previous frame, apply them now so that we have the correct velocity this move
		ApplyDeferredUnfollows();

		if(DataType.PrepareMove(this, CustomWorldUp))
		{
			#if !RELEASE
			if(!ensure(DataType.DebugPreparedFrame == Time::FrameNumber, f"PrepareMove was called on {DataType.Name}, but it seems that UBaseMovementData::PrepareMove() was never called. Did you forget to call Super?"))
				return false;
			#endif

			SetPreparingStatus(DataType.StatusInstigator);

			if(CustomWorldUp.IsUnit())
				InternalGravityDirection.SetDefaultValue(FMovementGravityDirection::TowardsDirection(-CustomWorldUp));
			else
				InternalGravityDirection.SetDefaultValue(FMovementGravityDirection::TowardsDirection(-FVector::UpVector));

			return true;
		}
		else
		{
			return false;
		}
	}

	protected void ApplyDeferredUnfollows()
	{
		if(DeferredUnfollows.IsEmpty())
			return;
		
		bIsApplyingDeferredUnfollows = true;

		for(int i = 0; i < DeferredUnfollows.Num(); i++)
		{
			const FMovementDeferredUnfollow& DeferredUnfollow = DeferredUnfollows[i];
			UnFollowComponentMovement(DeferredUnfollow.Instigator, DeferredUnfollow.TransferVelocityType);
		}

		DeferredUnfollows.Empty();

		bIsApplyingDeferredUnfollows = false;
	}

	/**
	 * This function will apply all the data to the movement component
	 */
	void ApplyMove(UBaseMovementData MoveData)
	{
#if EDITOR
		ValidateTickGroup("ApplyMove");
#endif

#if !RELEASE
		devCheck(MoveData != nullptr, "ApplyMove was called from using invalid data");
		devCheck(MoveData.IsValid(), "ApplyMove was called from using invalid data");
		devCheck(CurrentMovementStatus == EHazeMovementComponentStatus::Preparing, "ApplyMove was called from but movement is not prepared");
		check(!IsPerformingDebugRerun());
#endif

		auto Resolver = GetLinkedResolver(MoveData);
		devCheck(Resolver != nullptr, "ApplyMove was called using invalid resolver");

		// This tells the movement component that we have started to resolve a move.
		// No changed to the movement component should be done while this status is set
		SetResolvingStatus(MoveData.StatusInstigator, false);

		// Add extensions to the resolver
		{
			Resolver.Extensions.Reset();

			for(auto ResolverExtension : InstigatedResolverExtensions)
			{
				if(!ResolverExtension.Extension.SupportsResolver(Resolver))
				{
					// This extension does not extend the current resolver
					continue;
				}

				Resolver.Extensions.Add(ResolverExtension.Extension);
			}
		}

		// Initialize the resolvers data for this frame.
		Resolver.PrepareResolver(MoveData);
		Resolver.PostPrepareResolver(MoveData);

	#if !RELEASE
		devCheck(MoveData.DebugPreparedFrame == Time::FrameNumber, "PrepareMove was never called on"  + MoveData + ". Did you forget to call 'Super' ?");
		devCheck(Resolver.DebugPreparedFrame == Time::FrameNumber, "PrepareResolver was never called on"  + Resolver + ". Did you forget to call 'Super' ?");
		MoveData.DebugPreparedFrame = 0; // Make sure we always reset the frame data so we validate it the next frame.
	#endif

		// Resolve the movement
		Resolver.ResolveAndApplyMovementRequest(this);
		PostResolve(MoveData);
	}

	/**
	 * This function will apply all the data to the movement component in multiple threads
	 */
	void ApplyMoveParallel(UBaseMovementData DataType)
	{
		#if !RELEASE
		if(Console::GetConsoleVariableInt("Haze.Movement.Parallel.Enabled") <= 0)
		{
			// We have disabled Parallel movement, apply as usual instead
			ApplyMove(DataType);
			return;
		}
		#endif

		#if !RELEASE
		devCheck(DataType != nullptr, "ApplyMove was called from using invalid data");
		devCheck(DataType.IsValid(), "ApplyMove was called from using invalid data");
		devCheck(CurrentMovementStatus == EHazeMovementComponentStatus::Preparing, "ApplyMove was called from but movement is not prepared");
		check(!IsPerformingDebugRerun());
		#endif

		auto Resolver = GetLinkedResolver(DataType);
		if(Resolver == nullptr)
		{
			devError("ApplyMove was called using invalid resolver");
			return;
		}

#if EDITOR
		if(!UHazeMovementParallelManager::Get().IsMoveDataSupported(DataType))
		{
			devError(f"Trying to apply a move in parallel, but the {DataType.Name} MovementData does not support it!");
			ApplyMove(DataType);
			return;
		}

		if(!UHazeMovementParallelManager::Get().IsResolverSupported(Resolver))
		{
			devError(f"Trying to apply a move in parallel, but the {Resolver.Name} MovementResolver does not support it!");
			ApplyMove(DataType);
			return;
		}
#endif

		// This tells the movement component that we have started to resolve a move.
		// No changed to the movement component should be done while this status is set
		SetResolvingStatus(DataType.StatusInstigator, true);

		// Add extensions to the resolver
		{
			Resolver.Extensions.Reset();

			for(auto ResolverExtension : InstigatedResolverExtensions)
			{
				bool bSupported = false;
				for(auto SupportedResolverClass : ResolverExtension.Extension.SupportedResolverClasses)
				{
					if(Resolver.IsA(SupportedResolverClass))
					{
						bSupported = true;
						break;
					}
				}

				if(!bSupported)
				{
					// This extension does not extend the current resolver
					continue;
				}

				Resolver.Extensions.Add(ResolverExtension.Extension);
			}
		}

		// Initialize the resolvers data for this frame.
		Resolver.PrepareResolver(DataType);

		#if !RELEASE
		devCheck(DataType.DebugPreparedFrame == Time::FrameNumber, "PrepareMove was never called on"  + DataType + ". Did you forget to call 'Super' ?");
		devCheck(Resolver.DebugPreparedFrame == Time::FrameNumber, "PrepareResolver was never called on"  + Resolver + ". Did you forget to call 'Super' ?");
		DataType.DebugPreparedFrame = 0; // Make sure we always reset the frame data so we validate it the next frame.
		#endif

		FHazeMovementOnParallelResolveFinished OnCompleted;
		OnCompleted.BindUFunction(this, n"OnParallelResolveFinished");
		UHazeMovementParallelManager::Get().ScheduleParallelResolve(this, Resolver, DataType, OnCompleted);
	}

	UFUNCTION()
	private void OnParallelResolveFinished(UHazeMovementData DataType)
	{
		UBaseMovementData MoveData = Cast<UBaseMovementData>(DataType);
		PostResolve(MoveData);
	}

	protected void PostResolve(UBaseMovementData DataType)
	{
		// Add the original requested deltas
	 	LastRequestedImpulse = DataType.DeltaStates.GetDelta(EMovementIterationDeltaStateType::Impulse);
		LastRequestedMovement = DataType.DeltaStates.GetDelta() - LastRequestedImpulse;

		// This tells the movement component that we are done with the move
		// This also calls 'OnPostMovement'
		SetMovementPerformedStatus(DataType.StatusInstigator);
		BroadcastOnPostMovement();

		// Give the movement component a chance to automatically follow the floor
		if (HasMovementControl() || !DataType.bHasSyncedLocationInfo)
			UpdateAutoGroundFollow();
		else
			UpdateAutoFollowCrumbSyncedComponent(DataType.SyncedActorData);

		CleanupInvalidFollowComponents();
		UpdateMovementFollowAttachment();

		// If this actor uses crumbs for its position, we need to inform the component of our follow attachment
		// This will make the position crumbs we leave relative to it.
		if (!bResolveMovementLocally.Get() && InternalNetworkSyncComponent != nullptr && InternalNetworkSyncComponent.HasControl())
		{
			const FHazeMovementComponentAttachment& Attachment = GetCurrentMovementFollowAttachment();

			if (CanApplyCrumbSyncedRelativePosition(Attachment))
				ApplyCrumbSyncedRelativePosition(this, Attachment.Component, Attachment.SocketName, Priority = EInstigatePriority::Low);
			else
				InternalNetworkSyncComponent.ClearRelativePositionSync(this);
		}
	}

	bool CanApplyCrumbSyncedRelativePosition(FHazeMovementComponentAttachment Attachment) const
	{
		// No attachment to be relative to
		if(!Attachment.IsValid())
			return false;

		// Non-networked components can't be sent with RPCs
		if(!Attachment.Component.IsObjectNetworked())
			return false;

		// We have explicitly disabled relative sync on this component
		if(!Attachment.Component.HasTag(ComponentTags::AllowRelativePositionSyncing))
			return false;

		// If we don't allow inheriting horizontal movement, we disallow relative sync
		if(!Attachment.bFollowHorizontal)
			return false;

		return true;
	}

	void UpdateAutoGroundFollow()
	{
		if(InternalStandardSettings.AutoFollowGround == EMovementAutoFollowGroundType::Never)
			return;

		FMovementHitResult AutoFollowContact;
		if(TryGetAutoFollowGround(CurrentContacts, AutoFollowContact))
		{
			// Apply auto follow
			ApplyAutoFollowGroundContact(AutoFollowContact, EMovementFollowComponentType::ResolveCollision, FInstigator(this, n"UpdateAutoGroundFollow_Current"));
		}
		else if(TryGetAutoFollowGround(PreviousContacts, AutoFollowContact))
		{
			// If we don't have any ground this frame, we use the last frames ground
			// so we don't jitter when getting on an edge
			ApplyAutoFollowGroundContact(AutoFollowContact, EMovementFollowComponentType::ResolveCollision, FInstigator(this, n"UpdateAutoGroundFollow_Previous"));
		}
	}

	protected bool TryGetAutoFollowGround(FMovementContacts Contacts, FMovementHitResult&out OutAutoFollowContact) const
	{
		switch(InternalStandardSettings.AutoFollowGround)
		{
			case EMovementAutoFollowGroundType::Never:
				return false;

			case EMovementAutoFollowGroundType::FollowWalkable:
			{
				OutAutoFollowContact = Contacts.GetContact(EMovementImpactType::Ground);
				return OutAutoFollowContact.IsWalkableGroundContact();
			}

			case EMovementAutoFollowGroundType::FollowAnyGround:
			{
				OutAutoFollowContact = Contacts.GetContact(EMovementImpactType::Ground);
				return OutAutoFollowContact.IsAnyGroundContact();
			}
		}
	}

	/**
	 * Apply FollowComponent to a ground contact, but it will also be automatically cleared next frame if not applied again.
	 */
	protected void ApplyAutoFollowGroundContact(FMovementHitResult Ground, EMovementFollowComponentType FollowType, FInstigator FollowInstigator, EInstigatePriority Priority = EInstigatePriority::Low)
	{
		USceneComponent ComponentToFollow = Ground.Component;
		if(ComponentToFollow == nullptr)
			return;

		if(!CanFollowComponent(ComponentToFollow))
			return;

		FHazeMovementComponentAttachment NewAttachment;
		NewAttachment.Instigator = FollowInstigator;
		NewAttachment.Priority = Priority;

		NewAttachment.Component = ComponentToFollow;
		NewAttachment.SocketName = Ground.BoneName;
		NewAttachment.Type = EHazeMovementComponentAttachmentType::InternalAutoGround;
		NewAttachment.UpdateShouldFollowHorizontalAndVertical();
		NewAttachment.InheritType = FollowType;

		NewAttachment.FrameToBeRemovedAt = Time::FrameNumber + 1;

		FollowComponentAttachments.Add(NewAttachment);

		UpdateMovementFollowAttachment();
	}

	void UpdateAutoFollowCrumbSyncedComponent(FHazeSyncedActorPosition SyncedActorData)
	{
		// If we're using crumb synced locations, always and only follow the relative component from it
		FHazeMovementComponentAttachment NewAttachment;
		NewAttachment.Instigator = this;
		NewAttachment.Component = SyncedActorData.RelativeComponent;
		NewAttachment.SocketName = SyncedActorData.RelativeSocket;
		NewAttachment.Type = EHazeMovementComponentAttachmentType::InternalAutoSynced;
		NewAttachment.InheritType = EMovementFollowComponentType::Teleport;
		NewAttachment.Priority = EInstigatePriority::Override;
		NewAttachment.FrameToBeRemovedAt = Time::FrameNumber + 1;
		FollowComponentAttachments.Add(NewAttachment);
	}

	UFUNCTION(BlueprintOverride)
	UHazeMovementData OnSetupMovementData(TSubclassOf<UHazeMovementData> Type)
	{
		// Check if the data is already added
		for(auto Data : InternalMovementDataTypes)
		{
			if(Data.IsA(Type))
				return Data;
		}

		// Create the data type
		auto NewData = Cast<UBaseMovementData>(NewObject(this, Type));

		#if EDITOR
		devCheck(NewData.DefaultResolverType.IsValid(), "'DefaultResolverType' has not been setup for " + NewData);
		#endif

		InternalMovementDataTypes.Add(NewData);

		// Make sure the default resolver is created
		auto Resolver = GetOrCreateResolver(NewData.DefaultResolverType);

		#if EDITOR	
		auto ClassOne = Resolver.RequiredDataType.Get();
		auto ClassTwo = NewData.Class;
		devCheck(ClassOne == ClassTwo, "Resolver " + Resolver + " can't handle " + NewData + ". Its the wrong type");
		#endif

		// Create the link for the new data type
		FLinkedMovementResolverDataInformation NewLink;
		NewLink.Init(NewData, Resolver);
		ResolverDataLinks.Add(NewLink);
	
		return InternalMovementDataTypes.Last();
	}

	protected UBaseMovementResolver GetOrCreateResolver(TSubclassOf<UBaseMovementResolver> SolverClass)
	{
		devCheck(SolverClass.IsValid(), "GetOrCreateResolver requires a class");

		for(int i = 0; i < InternalMovementResolvers.Num(); ++i)
		{
			auto Resolver = InternalMovementResolvers[i];
			if(Resolver.IsA(SolverClass))
				return Resolver;
		}

		auto NewSolver = NewObject(this, SolverClass);
		NewSolver.InternalMovementComponent = this;
		NewSolver.MutableData = NewObject(NewSolver, NewSolver.MutableDataClass);
		InternalMovementResolvers.Add(NewSolver);

#if EDITOR
		devCheck(NewSolver.RequiredDataType.IsValid(), f"'RequiredDataType' has not been setup for {NewSolver}");
		devCheck(NewSolver.MutableDataClass.IsValid(), f"'MutableDataClass' has not been setup for {NewSolver}");
#endif

		return NewSolver;
	}

	UBaseMovementResolver GetLinkedResolver(UBaseMovementData ForData) const
	{
		for(auto It : ResolverDataLinks)
		{
			if(It.MovementData != ForData)
				continue;

			return It.GetResolver();
		}

		return nullptr;
	}

	void OverrideResolver(TSubclassOf<UBaseMovementResolver> ResolverClass, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		#if EDITOR
		devCheck(CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't call OverrideResolver'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
		#endif

		// Make sure we have the default values to override
		auto Resolver = GetOrCreateResolver(ResolverClass);
		SetupMovementData(Resolver.RequiredDataType);

		FInstigatedMovementResolverInternal NewOverride;
		NewOverride.Instigator = Instigator;
		NewOverride.Priority = Priority;
		NewOverride.Resolver = Resolver;

		for(FLinkedMovementResolverDataInformation& It : ResolverDataLinks)
		{
			if(Resolver.RequiredDataType != It.MovementData.Class)
				continue;

			It.Apply(NewOverride);
		}
	}

	void ClearResolverOverride(TSubclassOf<UBaseMovementResolver> ResolverClass, FInstigator Instigator)
	{
		for(auto& It : ResolverDataLinks)
		{
			if(Cast<UBaseMovementResolver>(ResolverClass.Get().DefaultObject).RequiredDataType != It.MovementData.Class)
				continue;

			It.Clear(Instigator);
		}
	}

	USimpleMovementData SetupSimpleMovementData()
	{
		return SetupMovementData(USimpleMovementData);
	}

	USweepingMovementData SetupSweepingMovementData()
	{
		return SetupMovementData(USweepingMovementData);
	}

	UFloatingMovementData SetupFloatingMovementData()
	{
		return SetupMovementData(UFloatingMovementData);
	}

	USteppingMovementData SetupSteppingMovementData()
	{
		return SetupMovementData(USteppingMovementData);
	}

	UTeleportingMovementData SetupTeleportingMovementData()
	{
		return SetupMovementData(UTeleportingMovementData);
	}

	void FollowComponentMovement(
		USceneComponent InComponent, 
		FInstigator Instigator, 
		EMovementFollowComponentType FollowType = EMovementFollowComponentType::ResolveCollision, 
		EInstigatePriority Priority = EInstigatePriority::Normal,
		FName FollowSocketName = NAME_None,
		bool bFollowHorizontal = true,
		bool bFollowVerticalUp = true,
		bool bFollowVerticalDown = true
		)
	{
		if (!CanFollowComponent(InComponent))
			return;

#if !RELEASE
			GetFollowPage().Event(f"Follow {InComponent}");
			
			const FTemporalLog FollowsPage = GetNewFollowsPage();
			FollowsPage.Status("New Follow", FLinearColor::Green);

			FollowsPage.Section(f"New Follow {InComponent}, Instigator {Instigator}")
				.Value("Component", InComponent)
				.Value("Instigator", Instigator)
				.Value("Follow Type", FollowType)
				.Value("Priority", Priority)
				.Value("Follow Socket Name", FollowSocketName)
				.Value("Follow Horizontal", bFollowHorizontal)
				.Value("Follow Vertical Up", bFollowVerticalUp)
				.Value("Follow Vertical Down", bFollowVerticalDown)
			;
#endif

		FHazeMovementComponentAttachment NewAttachment;
		NewAttachment.Instigator = Instigator;
		NewAttachment.Priority = Priority;

		NewAttachment.Component = InComponent;
		NewAttachment.SocketName = FollowSocketName;
		NewAttachment.Type = EHazeMovementComponentAttachmentType::Standard;
		NewAttachment.InheritType = FollowType;
		NewAttachment.bFollowHorizontal = bFollowHorizontal;
		NewAttachment.bFollowVerticalUp = bFollowVerticalUp;
		NewAttachment.bFollowVerticalDown = bFollowVerticalDown;

		NewAttachment.FrameToBeRemovedAt = -1;

#if !RELEASE
		NewAttachment.DebugableInstigatorObject = Instigator.GetWeakObjectInstigator().Get();
#endif

		bool bFoundExistingAttachment = false;
		for (int i = FollowComponentAttachments.Num() - 1; i >= 0; --i)
		{
		 	const FHazeMovementComponentAttachment& Attachment = FollowComponentAttachments[i];
			
			if (Attachment.Instigator != Instigator)
				continue;
			if (Attachment.InheritType != NewAttachment.InheritType)
				continue;
			if (Attachment.Type != NewAttachment.Type)
				continue;
			if (Attachment.FrameToBeRemovedAt != -1)
				continue;

			if(Attachment.bDeferredUnfollow)
			{
				// Remove this attachments deferred unfollow, since we are replacing it
				for(int j = DeferredUnfollows.Num() - 1; j >= 0; j--)
				{
					const FMovementDeferredUnfollow& DeferredUnfollow = DeferredUnfollows[j];
					if(DeferredUnfollow.ID != Attachment.DeferredUnfollowID)
						continue;

					DeferredUnfollows.RemoveAt(j);
				}
			}

			FollowComponentAttachments[i] = NewAttachment;
			bFoundExistingAttachment = true;
			break;
		}
		
		if (!bFoundExistingAttachment)
		{
			// Add a new follow if we didn't overwrite an existing one
			FollowComponentAttachments.Add(NewAttachment);

			// Check if this follow should prevent a deferred unfollow
			for(int i = DeferredUnfollows.Num() - 1; i >= 0; i--)
			{
				const FMovementDeferredUnfollow& DeferredUnfollow = DeferredUnfollows[i];
				if(!DeferredUnfollow.IsSameTarget(NewAttachment, Instigator))
					continue;

				// We have previously said to unfollow this attachment with the same instigator and target
				// Since we now want to follow it again, remove the deferred unfollow.
				// The bDeferredUnfollow flag on the attachment will be cleared in the next for loop.
				DeferredUnfollows.RemoveAt(i);
			}

		}

		UpdateMovementFollowAttachment();
	}

	void UnFollowComponentMovement(
		FInstigator Instigator,
		EMovementUnFollowComponentTransferVelocityType TransferVelocityType = EMovementUnFollowComponentTransferVelocityType::Release)
	{
		for(int i = FollowComponentAttachments.Num() - 1; i >= 0; --i)
		{
		 	FHazeMovementComponentAttachment& Attachment = FollowComponentAttachments[i];
			
			if(Attachment.Instigator != Instigator)
				continue;

			if(!bIsApplyingDeferredUnfollows)
			{
				// We have already deferred unfollowing this attachment
				if(Attachment.bDeferredUnfollow)
					continue;
				
				if(ShouldDeferUnfollow(TransferVelocityType))
				{
					// We have already moved, and the component we are following has not.
					// Unfollowing now would lead to us not following when the component most likely moves later this frame,
					// but we also don't apply the inherited velocity until next frame since we have already moved this frame.
					// This means that we do a slight pop as we move slower than we should relative to the world during the frame we detach.
					// Usually we want to handle this with tick order, anything we follow should move before we do, or before we unfollow.
					// To handle this, we defer this unfollow until we prepare the move next frame, or next tick if we don't move next frame.

					// The attachment could be the current follow
					// FB TODO: This should instead check if we would lose our current follow if this unfollow was applied now, but that's complicated and might not be needed for now.
					const bool bIsCurrent = CurrentFollow.Equals(Attachment);

					DeferUnfollow(Instigator, TransferVelocityType, Attachment, bIsCurrent);
					continue;
				}
			}

#if !RELEASE
			GetFollowPage().Event(f"Unfollow {Attachment.ToString()}");

			const FTemporalLog UnfollowPage = GetUnfollowsPage();
			UnfollowPage.Status("New Unfollow", FLinearColor::Red);

			UnfollowPage.Section(f"Unfollow {Attachment.ToString()}, Instigator: {Instigator}", i)
				.Value("Instigator", Instigator)
				.Value("Transfer Velocity Type", TransferVelocityType)
				.Value("Component", Attachment.Component)
				.Value("SocketName", Attachment.SocketName)
			;
#endif

			// Save the previous follow, allowing us to compare and use it after unfollowing
			FHazeMovementComponentAttachment PreviousFollow = CurrentFollow;
			
			// Remove the attachment, but keep the order
			FollowComponentAttachments.RemoveAt(i);

			// Update our current attachment
			UpdateMovementFollowAttachment();

			// Check if our current follow has been changed by this unfollow
			if (!PreviousFollow.IsSameFollowTarget(CurrentFollow))
				OnCurrentFollowChanged(PreviousFollow, CurrentFollow, Instigator, TransferVelocityType);

			break;
		}
	}

	protected bool ShouldDeferUnfollow(EMovementUnFollowComponentTransferVelocityType TransferVelocityType) const
	{
		switch(TransferVelocityType)
		{
			// We don't want to defer when using Release, since we expect a pop anyway.
			case EMovementUnFollowComponentTransferVelocityType::Release:
				return false;

			case EMovementUnFollowComponentTransferVelocityType::KeepInheritedVelocity:
				break;
		}

		// If we haven't moved yet, there's no need to defer the unfollow.
		if(!HasMovedThisFrame())
			return false;

		// But if we have moved this frame, but our follow has not, then we must defer.
		return true;
	}

	/**
	 * Store the instigator of an unfollow so that we can apply it the next frame,
	 * either before PrepareMove or at the end of the frame, whichever is first.
	 */
	protected void DeferUnfollow(FInstigator Instigator, EMovementUnFollowComponentTransferVelocityType TransferVelocityType, FHazeMovementComponentAttachment& Attachment, bool bIsCurrent)
	{
		check(!Attachment.bDeferredUnfollow);

		// This ever incrementing ID is used to link an attachment to it's deferred unfollow,
		// allowing us to find them even when the instigator and targets might change.
		DeferredUnfollowID++;

		FMovementDeferredUnfollow DeferredUnfollow;
		DeferredUnfollow.Instigator = Instigator;
		DeferredUnfollow.Component = Attachment.Component;
		DeferredUnfollow.SocketName = Attachment.SocketName;

		DeferredUnfollow.TransferVelocityType = TransferVelocityType;
		DeferredUnfollow.ID = DeferredUnfollowID;

		DeferredUnfollows.Add(DeferredUnfollow);

		if(bIsCurrent)
		{
			// Since CurrentFollow is not a ref into the attachments array, we must update it too
			CurrentFollow.bDeferredUnfollow = true;
			CurrentFollow.DeferredUnfollowID = DeferredUnfollowID;

			// Only the CurrentFollow will have it's velocity set, so copy that to the attachment entry
			Attachment.SetFollowVelocity(CurrentFollow.GetFollowVelocity());
		}

		// Mark this attachment as deferred to unfollow, meaning that it's velocity will remain unchanged, and we will not follow if it moves.
		Attachment.bDeferredUnfollow = true;
		Attachment.DeferredUnfollowID = DeferredUnfollowID;

#if !RELEASE
		GetFollowPage().Event(f"Deferred Unfollow {Attachment.ToString()}");

		const FTemporalLog UnfollowPage = GetUnfollowsPage();
		UnfollowPage.Status("Deferred Unfollow", FLinearColor::Yellow);

		UnfollowPage.Section(f"Defer Unfollow {Attachment.ToString()}, Instigator: {Instigator}")
			.Value("Instigator", Instigator)
			.Value("Transfer Velocity Type", TransferVelocityType)
			.Value("Component", Attachment.Component)
			.Value("SocketName", Attachment.SocketName)
			.Value("FollowVelocity", Attachment.GetFollowVelocity())
		;
#endif
	}

	/**
	 * The component we are currently following has been changed.
	 * @param PreviousAttachment What we were previously attached to.
	 * @param NewAttachment What we are now attached to. Same as CurrentFollow.
	 * @param Instigator The instigator we cleared that lead to the current follow changing.
	 * @param TransferVelocityType How we want to transfer velocity from the previous attachment into this one.
	 */
	protected void OnCurrentFollowChanged(
		FHazeMovementComponentAttachment PreviousAttachment,
		FHazeMovementComponentAttachment NewAttachment,
		FInstigator Instigator,
		EMovementUnFollowComponentTransferVelocityType TransferVelocityType
	)
	{
#if !RELEASE
		GetFollowPage().Event(f"Current Follow Changed from {PreviousAttachment.ToString()}} to {NewAttachment.ToString()}");
#endif

		FVector FollowVelocity = PreviousAttachment.GetFollowVelocity();
		ApplyTransferVelocityOnUnfollow(FollowVelocity, PreviousAttachment.Component, Instigator, TransferVelocityType);
	}

	protected void ApplyTransferVelocityOnUnfollow(
		FVector FollowVelocity,
		USceneComponent Component,
		FInstigator Instigator,
		EMovementUnFollowComponentTransferVelocityType TransferVelocityType
	)
	{
		switch(TransferVelocityType)
		{
			// Release is a bad name for not inheriting, but ok Tyko, you do you
			case EMovementUnFollowComponentTransferVelocityType::Release:
				break;

			case EMovementUnFollowComponentTransferVelocityType::KeepInheritedVelocity:
			{
				// Add the attachments follow velocity to our velocities
				FVector NewHorizontal = HorizontalVelocity;
				FVector NewVertical = VerticalVelocity;
				NewHorizontal += FollowVelocity.VectorPlaneProject(WorldUp);
				NewVertical += FollowVelocity.ProjectOnToNormal(WorldUp);

#if !RELEASE
				const FTemporalLog UnfollowPage = GetUnfollowsPage();

				UnfollowPage.Section(f"ApplyTransferVelocityOnUnfollow {Component}, Instigator: {Instigator}")
					.Value("Instigator", Instigator)
					.Value("Transfer Velocity Type", TransferVelocityType)
					.DirectionalArrow("Follow Velocity", ShapeComponent.WorldLocation, FollowVelocity, Color = FLinearColor::Yellow)

					.Section("Before")
						.DirectionalArrow("HorizontalVelocity", ShapeComponent.WorldLocation, HorizontalVelocity)
						.DirectionalArrow("VerticalVelocity", ShapeComponent.WorldLocation, VerticalVelocity)

					.Section("After")
						.DirectionalArrow("PostHorizontalVelocity", ShapeComponent.WorldLocation, NewHorizontal, Color = FLinearColor::Green)
						.DirectionalArrow("PostVerticalVelocity", ShapeComponent.WorldLocation, NewVertical, Color = FLinearColor::Green)
				;
#endif

				SetHorizontalAndVerticalVelocityInternal(NewHorizontal, NewVertical);
				break;
			}
		}
	}

	protected void FollowComponentMovementForThisFrame(USceneComponent InComponent, 
		FInstigator Instigator, 
		EMovementFollowComponentType FollowType = EMovementFollowComponentType::ResolveCollision, 
		EInstigatePriority Priority = EInstigatePriority::High,
		FName FollowSocketName = NAME_None)
	{
		if(!CanFollowComponent(InComponent))
			return;
		
		FHazeMovementComponentAttachment NewAttachment;
		NewAttachment.Instigator = Instigator;
		NewAttachment.Component = InComponent;
		NewAttachment.SocketName = FollowSocketName;
		NewAttachment.Type = EHazeMovementComponentAttachmentType::ForOneFrame;
		NewAttachment.InheritType = FollowType;
		NewAttachment.FrameToBeRemovedAt = Time::FrameNumber;
		NewAttachment.Priority = Priority;
		FollowComponentAttachments.Add(NewAttachment);
		UpdateMovementFollowAttachment();
	}

	UFUNCTION(BlueprintOverride)
	void OnOwnerTransformChanged(bool bFromMovementComponent)
	{
		FTransform ActorTransform = Owner.ActorTransform;
		ActorTransform.SetScale3D(FVector::OneVector);
		FVector Offset = GetAttachmentOffset();
		ActorTransform.AddToTranslation(Offset);

		if (CurrentFollow.IsValid())
		{
			PreviousFollowTransform = CurrentFollow.WorldTransform;
			PreviousFollowScale = PreviousFollowTransform.Scale3D;
			PreviousFollowTransform.SetScale3D(FVector::OneVector);

			PreviousTransformRelativeToFollow.RelativeTransform = ActorTransform.GetRelativeTransform(PreviousFollowTransform);
			PreviousTransformRelativeToFollow.Offset = PreviousTransformRelativeToFollow.RelativeTransform.InverseTransformVector(Offset);
		}

		if (CurrentReferenceFrame.IsValid())
		{
			PreviousFollowReferenceFrame = CurrentReferenceFrame.WorldTransform;
			PreviousFollowReferenceFrame.SetScale3D(FVector::OneVector);

			PreviousTransformRelativeToReferenceFrame.RelativeTransform = ActorTransform.GetRelativeTransform(PreviousFollowReferenceFrame);
			PreviousTransformRelativeToReferenceFrame.Offset = PreviousTransformRelativeToReferenceFrame.RelativeTransform.InverseTransformVector(Offset);
		}
	}

	uint LastFollowMovedFrame = 0;
	int FollowMovesThisFrame = 0;

	UFUNCTION(BlueprintOverride)
	void ApplyMovementAttachmentTransform(USceneComponent ChangedComponent)
	{
		if (ChangedComponent != CurrentFollow.Component)
		{
			check(false);
			return;
		}

		if(!HasMovedThisFrame())
		{
			// We have not moved yet, so we haven't applied the unfollow velocity,
			// but we still do not want to follow this component being moved, so ignore it's transform changing.
			if(CurrentFollow.bDeferredUnfollow)
				return;
		}

#if !RELEASE
		if(LastFollowMovedFrame < Time::FrameNumber)
		{
			// First follow of this frame
			LastFollowMovedFrame = Time::FrameNumber;
			FollowMovesThisFrame = 1;

			// Make sure we haven't included any old follow impacts
			FollowImpacts.Reset();
		}
		else
		{
			FollowMovesThisFrame++;
		}

		const FTemporalLog TemporalLog = GetFollowMovesPage().Section(f"Follow {FollowMovesThisFrame}", FollowMovesThisFrame);
		TemporalLog.Value("Tick Group", HazeTick::CurrentTickGroup);

#if EDITOR
		UObject InstigatorObject = FindExternalInstigator(true);

		if(InstigatorObject != nullptr)
		{
			UActorComponent Component = Cast<UActorComponent>(InstigatorObject);
			if(Component != nullptr)
				TemporalLog.Value("Move Instigator", f"Component: {Component.ToString()}\nActor: {Component.Owner}");
			else
				TemporalLog.Value("Move Instigator", InstigatorObject.ToString());
		}
#endif	// EDITOR
#endif	// !RELEASE

		FTransform FollowTransform = CurrentFollow.GetWorldTransform();
		FTransform RelativeToFollow = PreviousTransformRelativeToFollow.RelativeTransform;

		// Transform relative position to follow the scale of the follow component
		const FVector FollowScaleDeltaMultiplier = FollowTransform.Scale3D / PreviousFollowScale;
		RelativeToFollow.ScaleTranslation(FollowScaleDeltaMultiplier);

		FVector WantedLocation = FollowTransform.TransformPositionNoScale(RelativeToFollow.Location);
		WantedLocation -= PreviousTransformRelativeToFollow.RelativeTransform.TransformVector(PreviousTransformRelativeToFollow.Offset);
		FQuat WantedRotation = FollowTransform.TransformRotation(RelativeToFollow.Rotation);
		
		// If we have a reference frame, first apply a teleport from any movement
		// that the reference frame has done, then resolve any additional movement
		// we have from the follow.
		FVector ReferenceFrameDelta;
		if (CurrentReferenceFrame.IsValid())
		{
			FTransform RelativeRefTransform = PreviousTransformRelativeToReferenceFrame.RelativeTransform;
			FTransform ReferenceFrameTransform = CurrentReferenceFrame.WorldTransform;
			FTransform NewActorTransformInReferenceFrame = FTransform(
				ReferenceFrameTransform.TransformRotation(RelativeRefTransform.Rotation),
				ReferenceFrameTransform.TransformPositionNoScale(RelativeRefTransform.Location),
			);

			FVector Offset = PreviousTransformRelativeToReferenceFrame.RelativeTransform.TransformVector(PreviousTransformRelativeToReferenceFrame.Offset);
			NewActorTransformInReferenceFrame.AddToTranslation(-Offset);

#if !RELEASE
			TemporalLog.Point("ReferenceFrame", ReferenceFrameTransform.Location);
			TemporalLog.Point("RelativeToReferenceFrame", RelativeRefTransform.Location);

			ReferenceFrameDelta = (NewActorTransformInReferenceFrame.Location - HazeOwner.ActorLocation);
			if (!ReferenceFrameDelta.IsNearlyZero())
				TemporalLog.DirectionalArrow("ReferenceFrameDelta", CurrentReferenceFrame.Component.WorldLocation, ReferenceFrameDelta);
#endif

			UpdateActorTransformFromFollowMovement(NewActorTransformInReferenceFrame, true);
		}

		// Then do the last bit of movement, which could be resolving collisions
		FVector WantedDelta = WantedLocation - HazeOwner.GetActorLocation();
		FinalizeMovementAttachmentWantedLocationAndDelta(CurrentFollow, WantedLocation, WantedDelta);

		// Prepare the follow velocity
		FVector FollowVelocity = WantedDelta / Time::GetActorDeltaSeconds(HazeOwner);

		// Update the facing rotation to follow the follow attachment
		FVector PreviousFacingVector = InternalFacingOrientation.ForwardVector;
		FVector FacingRelativeToPreviousRotation = PreviousFollowTransform.InverseTransformVectorNoScale(PreviousFacingVector);
		InternalFacingOrientation = FQuat::MakeFromZX(WantedRotation.UpVector, FollowTransform.TransformVectorNoScale(FacingRelativeToPreviousRotation));

#if !RELEASE
		TemporalLog.Point("FollowLocation", FollowTransform.Location);
		TemporalLog.Rotation("FollowRotation", FollowTransform.Rotation, FollowTransform.Location);
		TemporalLog.DirectionalArrow("FollowVelocity", FollowTransform.Location, CurrentFollow.GetFollowVelocity());
		TemporalLog.Value("RelativeToFollow", RelativeToFollow.Location);
#endif

		if (FollowComponentData != nullptr && CurrentFollow.InheritType == EMovementFollowComponentType::ResolveCollision)
		{
			if (!WantedDelta.IsNearlyZero() && FollowComponentData.PrepareFollowMove(this, ChangedComponent))
			{
				FollowComponentData.AddDelta(WantedDelta);
				FollowComponentData.SetRotation(WantedRotation);

				auto Resolver = Cast<UFollowComponentMovementResolver>(GetLinkedResolver(FollowComponentData));
				Resolver.PrepareResolver(FollowComponentData);
				Resolver.ResolveTransform(WantedLocation, WantedRotation, FollowVelocity);

				// We might get impacts from the follow resolver
				if(Resolver.AccumulatedImpacts.HasImpactedAnything())
				{
					// Append, broadcast, and re-log the impacts
					AccumulatedImpacts.AppendAccumulatedImpacts(Resolver.AccumulatedImpacts);

					// We also need to store the follow impacts separately, to prevent them being removed when we perform a move
					FollowImpacts.AppendAccumulatedImpacts(Resolver.AccumulatedImpacts);

					/**
					 * FB TODO: Is it a problem to broadcast here? Should we defer this to the end of the frame?
					 */
					BroadcastAllImpactCallbacks();
#if !RELEASE
					MovementDebug::LogImpactsPage(this);
#endif
				}
			}

			FTransform NewActorTransform(WantedRotation, WantedLocation);

#if !RELEASE
			// Clear the prepare frame since it has been applied
			FollowComponentData.DebugPreparedFrame = 0;
			TemporalLog.DirectionalArrow("Resolve Delta", HazeOwner.ActorLocation, WantedDelta, Color = FLinearColor::Red);
			TemporalLog.DirectionalArrow("Final Delta", HazeOwner.ActorLocation, (NewActorTransform.Location - HazeOwner.ActorLocation), Color = FLinearColor::Green);

			LogMovementShapeAtLocation(TemporalLog, "Before Follow", HazeOwner.ActorLocation, FLinearColor::Red);
			LogMovementShapeAtLocation(TemporalLog, "After Follow", NewActorTransform.Location, FLinearColor::Green);
#endif

			UpdateActorTransformFromFollowMovement(NewActorTransform, false);
		}
		else
		{
#if !RELEASE
			TemporalLog.DirectionalArrow("TeleportDelta", HazeOwner.ActorLocation, (WantedLocation - HazeOwner.ActorLocation));
#endif

			UpdateActorTransformFromFollowMovement(FTransform(WantedRotation, WantedLocation), false);
		}

		// Add the current follow velocity to the accumulated velocity
		FollowFrameVelocity.AddVelocity(FollowVelocity, ChangedComponent);

#if !RELEASE
		TemporalLog.DirectionalArrow("FollowFrameVelocity", HazeOwner.ActorLocation, FollowFrameVelocity.GetVelocity());
#endif

		// Store the velocity in the follow so we can use it for exits.
		CurrentFollow.SetFollowVelocity(FollowFrameVelocity.GetVelocity());

		// Update the previous transforms now that we've done our follow movement
		PreviousFollowTransform = CurrentFollow.WorldTransform;
		PreviousFollowTransform.SetScale3D(FVector::OneVector);

		FVector AttachOffset = GetAttachmentOffset();
		FTransform ActorTransform = Owner.ActorTransform;
		ActorTransform.SetScale3D(FVector::OneVector);
		ActorTransform.AddToTranslation(AttachOffset);

		PreviousTransformRelativeToFollow.RelativeTransform = ActorTransform.GetRelativeTransform(PreviousFollowTransform);
		PreviousTransformRelativeToFollow.Offset = PreviousTransformRelativeToFollow.RelativeTransform.InverseTransformVector(AttachOffset);

		if (CurrentReferenceFrame.IsValid())
		{
			PreviousFollowReferenceFrame = CurrentReferenceFrame.WorldTransform;
			PreviousFollowReferenceFrame.SetScale3D(FVector::OneVector);
			PreviousTransformRelativeToReferenceFrame.RelativeTransform = ActorTransform.GetRelativeTransform(PreviousFollowReferenceFrame);
			PreviousTransformRelativeToReferenceFrame.Offset = PreviousTransformRelativeToReferenceFrame.RelativeTransform.InverseTransformVector(AttachOffset);
		}
	}

	protected FVector GetShapeWorldOffset() const
	{
		const FVector ComponentLocalOffset = Owner.ActorTransform.InverseTransformPosition(ShapeComponent.WorldLocation);
		return Owner.ActorQuat.RotateVector(ComponentLocalOffset);
	}

	protected FVector GetAttachmentOffset() const
	{
		return Owner.ActorUpVector * VerticalAttachmentOffset.Get();
	}

	protected void UpdateActorTransformFromFollowMovement(FTransform NewActorTransform, bool bFromRefFrame)
	{
		SnapActorFromTransformChange(NewActorTransform);
	}

	protected void FinalizeMovementAttachmentWantedLocationAndDelta(FHazeMovementComponentAttachment& Attachment, FVector& WantedLocation, FVector& WantedDelta)
	{
		FVector FinalWantedDelta = FVector::ZeroVector;

		const FVector HorizontalDelta = WantedDelta.VectorPlaneProject(WorldUp);

		// We may need to update these values with the current followed component tags
		Attachment.UpdateShouldFollowHorizontalAndVertical();
		
		if(Attachment.bFollowHorizontal)
		{
			// Only add horizontal if tagged to inherit horizontal
			FinalWantedDelta += HorizontalDelta;
		}

		const FVector VerticalDelta = WantedDelta - HorizontalDelta;
		const bool bVerticalIsUp = VerticalDelta.DotProduct(WorldUp) > 0;

		if(bVerticalIsUp && Attachment.bFollowVerticalUp)
		{
			// If tagged to inherit vertical up, and the vertical delta is upwards, add it
			FinalWantedDelta += VerticalDelta;
		}
		else if(!bVerticalIsUp && Attachment.bFollowVerticalDown)
		{
			// If tagged to inherit vertical down, and the vertical delta is downwards, add it
			FinalWantedDelta += VerticalDelta;
		}

		WantedLocation -= WantedDelta;
		WantedLocation += FinalWantedDelta;
		WantedDelta = FinalWantedDelta;
	}

	protected void CleanupInvalidFollowComponents()
	{
		// OBS! Keep the order when we clean up
		for(int i = FollowComponentAttachments.Num() - 1; i >= 0; --i)
		{
			FHazeMovementComponentAttachment& Attachment = FollowComponentAttachments[i];
			if(!IsValid(Attachment.Component) && Attachment.Type != EHazeMovementComponentAttachmentType::InternalAutoSynced)
			{
				FollowComponentAttachments.RemoveAt(i);
			}
			else if(Attachment.Type == EHazeMovementComponentAttachmentType::None)		
			{
				FollowComponentAttachments.RemoveAt(i);
			}
			else if(Attachment.FrameToBeRemovedAt >= 0 && Time::GetFrameNumber() >= uint(Attachment.FrameToBeRemovedAt))
			{
				FollowComponentAttachments.RemoveAt(i);
			}
		}
	}

	protected void UpdateMovementFollowAttachment()
	{
		FScopeCycleCounter CycleCounter(STAT_Movement_UpdateMovementFollowAttachment);

		int WantedFollowIndex = FindBestMovementAttachmentIndex(bReferenceFrame = false);
		int WantedReferenceFrameIndex = FindBestMovementAttachmentIndex(bReferenceFrame = true);

		// If we have a reference frame but not a follow component,
		// we still follow the reference frame
		if (WantedFollowIndex == -1 && WantedReferenceFrameIndex != -1)
			WantedFollowIndex = WantedReferenceFrameIndex;

		// Update the current follow component
		bool bChangedFollow = false;
		if (CurrentFollow.IsValid())
		{
			if (WantedFollowIndex == -1)
			{
				// We stopped following anything
				bChangedFollow = true;
			}
			else if (!CurrentFollow.IsSameFollowTarget(FollowComponentAttachments[WantedFollowIndex]))
			{
				// We changed what we are following
				bChangedFollow = true;
			}
		}
		else if (WantedFollowIndex != -1)
		{
			// We found something to follow
			bChangedFollow = true;
		}

		if (bChangedFollow)
		{
			if (CurrentFollow.IsValid())
			{
				OnStopFollowing(CurrentFollow);
				DetachMovementFromComponent(CurrentFollow.Component);
			}

			if (WantedFollowIndex != -1)
			{
				bool bHasSameFollowTarget = CurrentFollow.IsSameFollowTarget(FollowComponentAttachments[WantedFollowIndex]);
				CurrentFollow = FollowComponentAttachments[WantedFollowIndex];

				if (CurrentFollow.IsValid() && !bHasSameFollowTarget)
				{
					PreviousFollowTransform = CurrentFollow.WorldTransform;
					PreviousFollowScale = PreviousFollowTransform.Scale3D;
					PreviousFollowTransform.SetScale3D(FVector::OneVector);
					FollowFrameVelocity.Invalidate();

					FVector AttachOffset = GetAttachmentOffset();
					FTransform ActorTransform = Owner.ActorTransform;
					ActorTransform.SetScale3D(FVector::OneVector);
					ActorTransform.AddToTranslation(AttachOffset);

					PreviousTransformRelativeToFollow.RelativeTransform = ActorTransform.GetRelativeTransform(PreviousFollowTransform);
					PreviousTransformRelativeToFollow.Offset = PreviousTransformRelativeToFollow.RelativeTransform.InverseTransformVector(AttachOffset);
				}

				if (CurrentFollow.IsValid())
				{
					OnStartFollowing(CurrentFollow);
					AttachMovementToComponent(CurrentFollow.Component, CurrentFollow.SocketName);
				}
			}
			else
			{
				CurrentFollow.Clear();
			}
		}	

		// Update the current reference frame
		bool bChangedReferenceFrame = false;
		if (CurrentReferenceFrame.IsValid())
		{
			if (WantedReferenceFrameIndex == -1)
				bChangedReferenceFrame = true;
			else if (!CurrentReferenceFrame.Equals(FollowComponentAttachments[WantedReferenceFrameIndex]))
				bChangedReferenceFrame = true;
		}
		else if (WantedReferenceFrameIndex != -1)
		{
			bChangedReferenceFrame = true;
		}

		if (bChangedReferenceFrame)
		{
			if (WantedReferenceFrameIndex != -1)
			{
				bool bHasSameReferenceFrameTarget = CurrentReferenceFrame.IsSameFollowTarget(FollowComponentAttachments[WantedReferenceFrameIndex]);
				CurrentReferenceFrame = FollowComponentAttachments[WantedReferenceFrameIndex];

				if (CurrentReferenceFrame.IsValid() && !bHasSameReferenceFrameTarget)
				{
					PreviousFollowReferenceFrame = CurrentReferenceFrame.WorldTransform;
					PreviousFollowReferenceFrame.SetScale3D(FVector::OneVector);
					
					FVector AttachOffset = GetAttachmentOffset();
					FTransform ActorTransform = Owner.ActorTransform;
					ActorTransform.SetScale3D(FVector::OneVector);
					ActorTransform.AddToTranslation(AttachOffset);

					PreviousTransformRelativeToReferenceFrame.RelativeTransform = ActorTransform.GetRelativeTransform(PreviousFollowReferenceFrame);
					PreviousTransformRelativeToReferenceFrame.Offset = PreviousTransformRelativeToReferenceFrame.RelativeTransform.InverseTransformVector(AttachOffset);
				}
			}
			else
			{
				CurrentReferenceFrame.Clear();
			}
		}	
	}

	protected void OnStartFollowing(FHazeMovementComponentAttachment& Attachment)
	{
		Attachment.InheritVelocityComp = FindInheritVelocityComponent(Attachment.Component);
		if(Attachment.InheritVelocityComp != nullptr)
		{
			FVector NewHorizontal = HorizontalVelocity;
			FVector NewVertical = VerticalVelocity;
			Attachment.InheritVelocityComp.AdjustVelocityOnFollow(this, Attachment.Component, NewHorizontal, NewVertical);
			SetHorizontalAndVerticalVelocityInternal(NewHorizontal, NewVertical);
		}

		if(Attachment.Component.HasTag(ComponentTags::CameraInheritMovement))
		{
			UCameraInheritMovementSettings::SetInheritMovement(HazeOwner, true, this);
		}
	}

	protected void OnStopFollowing(FHazeMovementComponentAttachment Attachment)
	{
		if(IsValid(Attachment.InheritVelocityComp))
		{
			FVector NewHorizontal = HorizontalVelocity;
			FVector NewVertical = VerticalVelocity;
			Attachment.InheritVelocityComp.InheritVelocityOnUnFollow(this, Attachment.Component, NewHorizontal, NewVertical);
			SetHorizontalAndVerticalVelocityInternal(NewHorizontal, NewVertical);
		}

		if(Attachment.Component.HasTag(ComponentTags::CameraInheritMovement))
		{
			UCameraInheritMovementSettings::ClearInheritMovement(HazeOwner, this);
		}
	}

	protected UInheritVelocityComponent FindInheritVelocityComponent(USceneComponent Component)
	{
		FScopeCycleCounter CycleCounter(STAT_Movement_FindInheritVelocityComponent);

		if(FindInheritVelocityComponentMethod == EMovementFindInheritVelocityComponentMethod::NoInheritVelocity)
			return nullptr;

		UInheritVelocityComponent InheritVelocityComp = UInheritVelocityComponent::Get(Component.Owner);
		if(InheritVelocityComp != nullptr)
			return InheritVelocityComp;
		
		if(FindInheritVelocityComponentMethod == EMovementFindInheritVelocityComponentMethod::FindOnFollowedActorAndParents)
		{
			AActor Actor = Component.Owner;
			while(Actor.AttachParentActor != nullptr)
			{
				InheritVelocityComp = UInheritVelocityComponent::Get(Actor.AttachParentActor);
				if(InheritVelocityComp != nullptr)
				{
					if(!InheritVelocityComp.bAllowBeingFoundFromAttachedActors)
						return nullptr;
					
					return InheritVelocityComp;
				}

				Actor = Actor.AttachParentActor;
			}
		}

		return nullptr;
	}

	protected void GetExternalMovementFollows(TArray<FHazeMovementComponentAttachment>& OutAttachments)
	{
		for (const FHazeMovementComponentAttachment& Attachment : FollowComponentAttachments)
		{
			if (Attachment.Type == EHazeMovementComponentAttachmentType::InternalAutoGround)
				continue;
			if (Attachment.Type == EHazeMovementComponentAttachmentType::InternalAutoSynced)
				continue;
			OutAttachments.Add(Attachment);
		}
	}

	void ApplyFollowEnabledOverride(FInstigator Instigator, EMovementFollowEnabledStatus EnabledStatus, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		EMovementFollowEnabledStatus PreviousStatus = FollowEnablement.Get();
		FollowEnablement.Apply(EnabledStatus, Instigator, Priority);

		if (PreviousStatus != FollowEnablement.Get())
		{
			UpdateMovementFollowAttachment();
			if (FollowEnablement.Get() == EMovementFollowEnabledStatus::FollowDisabled)
			{
				FollowFrameVelocity.Invalidate();
			}
		}
	}

	void ClearFollowEnabledOverride(FInstigator Instigator)
	{
		EMovementFollowEnabledStatus PreviousStatus = FollowEnablement.Get();
		FollowEnablement.Clear(Instigator);

		if (PreviousStatus != FollowEnablement.Get())
		{
			UpdateMovementFollowAttachment();
			if (FollowEnablement.Get() == EMovementFollowEnabledStatus::FollowDisabled)
			{
				FollowFrameVelocity.Invalidate();
			}
		}
	}

	EMovementFollowEnabledStatus GetFollowEnabledStatus() const
	{
		return FollowEnablement.Get();
	}

	access:DebugAccess
	FInstigator GetFollowEnabledStatusInstigator() const
	{
		return FollowEnablement.CurrentInstigator;
	}

	access:DebugAccess
	EInstigatePriority GetFollowEnabledStatusPriority() const
	{
		return FollowEnablement.CurrentPriority;
	}

	access:DebugAccess
    bool GetFollowEnabledStatusIsDefault() const
    {
        return FollowEnablement.IsDefaultValue();
    }

    access:DebugAccess
    FInstigator GetFollowEnabledCurrentInstigator() const
    {
        return FollowEnablement.GetCurrentInstigator();
    }

	protected int FindBestMovementAttachmentIndex(bool bReferenceFrame) const
	{
		if (bReferenceFrame)
		{
			if (FollowEnablement.Get() == EMovementFollowEnabledStatus::FollowDisabled)
				return -1;
		}
		else
		{
			if (FollowEnablement.Get() != EMovementFollowEnabledStatus::FollowEnabled)
				return -1;
		}

		int BestIndex = -1;
		int BestPrio = -1;

		for(int i = FollowComponentAttachments.Num() - 1; i >= 0; --i)
		{
			const FHazeMovementComponentAttachment& Attachment = FollowComponentAttachments[i];
			
			if (Attachment.Type == EHazeMovementComponentAttachmentType::None)
				continue;

			// If we have an auto-synced attachment, never do anything else
			if(Attachment.Type == EHazeMovementComponentAttachmentType::InternalAutoSynced)
			{
				if (bReferenceFrame)
					return -1;
				else
					return i;
			}

			if (bReferenceFrame)
			{
				if (Attachment.InheritType != EMovementFollowComponentType::ReferenceFrame)
					continue;
			}
			else
			{
				if (Attachment.InheritType == EMovementFollowComponentType::ReferenceFrame)
					continue;
			}
		
			if(Attachment.FrameToBeRemovedAt >= 0 && Time::FrameNumber > uint(Attachment.FrameToBeRemovedAt))
				continue;

			if(Attachment.Component == nullptr)
				continue;

			// Pick the most valid attachment
			int AttachmentPrio = int(Attachment.Priority) * 100;
			if(Attachment.Type == EHazeMovementComponentAttachmentType::InternalAutoGround)
				AttachmentPrio += 1;
			else if(Attachment.Type == EHazeMovementComponentAttachmentType::ForOneFrame)
				AttachmentPrio += 2;
			
			if(AttachmentPrio > BestPrio)
			{
				BestPrio = AttachmentPrio;
				BestIndex = i;
			}
		}

		return BestIndex;
	}

	const FHazeMovementComponentAttachment& GetCurrentMovementFollowAttachment() const
	{
		return CurrentFollow;
	}

	USceneComponent GetCurrentMovementAttachmentComponent() const
	{
		return CurrentFollow.Component;
	}

	const FHazeMovementComponentAttachment& GetCurrentMovementReferenceFrame() const
	{
		return CurrentReferenceFrame;
	}

	USceneComponent GetCurrentMovementReferenceFrameComponent() const
	{
		return CurrentReferenceFrame.Component;
	}

	void GetFollowedComponents(TArray<USceneComponent>&out OutComponents) const
	{
		OutComponents.Reserve(FollowComponentAttachments.Num());

		for (const auto& Attachment : FollowComponentAttachments)
		{
			if (Attachment.Component != nullptr)
				OutComponents.Add(Attachment.Component);
		}
	}

	/**
	 * Whether any follow velocity is available for the current follow component.
	 */
	bool HasValidFollowVelocity() const
	{
		return FollowFrameVelocity.IsValid();
	}

	/**
	 * This is the velocity provided by the movement from the thing that we are set to follow
	 */
	FVector GetFollowVelocity() const
	{
		return FollowFrameVelocity.GetVelocity();
	}

	protected bool CanFollowComponent(USceneComponent InComponent) const
	{
		if(InComponent == nullptr)
			return false;

		if(InComponent.Mobility != EComponentMobility::Movable)
			return false;

		if(InComponent.IsSimulatingPhysics())
			return false;

		return true;
	}

	void AddPendingImpulse(FVector Impulse, FInstigator ImpulseInstigator = FInstigator())
	{
#if EDITOR
		devCheck(CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't set 'Add impulses'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
#endif

		FMovementImpulse NewImpulse;
		NewImpulse.Impulse = Impulse;
		NewImpulse.Instigator = ImpulseInstigator;
		NewImpulse.AddedFrame = Time::FrameNumber;

#if !RELEASE
		NewImpulse.bDebugOnlyMovementPerformedWhenAdded = HasMovedThisFrame();
#endif

		Impulses.Add(NewImpulse);
	}

	void AddPendingImpulseWithCooldown(FVector Impulse, FInstigator Instigator, float Cooldown)
	{
#if EDITOR
		devCheck(CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't set 'Add impulses'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
#endif

		// Check if we have a cooldown on this instigator already
		for (FMovementImpulse& PreviousImpulse : Impulses)
		{
			if (PreviousImpulse.Instigator == Instigator)
			{
				if (PreviousImpulse.CooldownUntil != 0 && PreviousImpulse.CooldownUntil > Time::GameTimeSeconds)
					return;
			}
		}

		FMovementImpulse NewImpulse;
		NewImpulse.Impulse = Impulse;
		NewImpulse.Instigator = Instigator;
		NewImpulse.AddedFrame = Time::FrameNumber;
		NewImpulse.CooldownUntil = Time::GameTimeSeconds + Cooldown;

#if !RELEASE
		NewImpulse.bDebugOnlyMovementPerformedWhenAdded = HasMovedThisFrame();
#endif

		Impulses.Add(NewImpulse);
	}

	void ClearPendingImpulses()
	{
#if EDITOR
		devCheck(CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't set 'Add impulses'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
#endif

		// Remove pending impulses, except anything with an unexpired cooldown: those should be zeroed out and kept until the cooldown expires
		float GameTime = Time::GameTimeSeconds;
		for (int i = Impulses.Num() - 1; i >= 0; --i)
		{
			if (Impulses[i].CooldownUntil == 0 || Impulses[i].CooldownUntil < GameTime)
			{
				// Remove old impulses
				Impulses.RemoveAtSwap(i);
			}
			else
			{
				// Zero out impulses that are still on cooldown
				Impulses[i].Impulse = FVector::ZeroVector;
			}
		}
	}

	void SetPendingTargetFacingRotationInternal(FQuat Orientation)
	{
		#if EDITOR
		devCheck(CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't set 'TargetFacingRotation'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
		#endif

		InternalFacingOrientation = Orientation;
	}

	void OverrideGravityDirection(FMovementGravityDirection GravityType, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		#if EDITOR
		devCheck(CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't change the gravity direction. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
		#endif

		InternalGravityDirection.Apply(GravityType, Instigator, Priority);
		StoreWorldUpInternal(-GetGravityDirection());

		UHazeSkeletalMeshComponentBase SkelMeshComp = UHazeSkeletalMeshComponentBase::Get(HazeOwner);
		if (SkelMeshComp != nullptr)
			SkelMeshComp.SetOverrideGravityDirection(GetGravityDirection());
	}

	void ClearGravityDirectionOverride(FInstigator Instigator)
	{
		InternalGravityDirection.Clear(Instigator);
		StoreWorldUpInternal(-GetGravityDirection());

		UHazeSkeletalMeshComponentBase SkelMeshComp = UHazeSkeletalMeshComponentBase::Get(HazeOwner);
		if (SkelMeshComp != nullptr)
		{
			if (InternalGravityDirection.IsDefaultValue())
				SkelMeshComp.ClearOverrideGravityDirection();
			else
				SkelMeshComp.SetOverrideGravityDirection(GetGravityDirection());
		}
	}

	float GetWalkableSlopeAngle() const property
	{
		return InternalStandardSettings.WalkableSlopeAngle;
	}

	float GetCeilingAngle() const property
	{
		return InternalStandardSettings.CeilingAngle;
	}

	void ApplyMoveSpeedMultiplier(float Value, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InternalMovementSpeedMultiplier.Apply(Value, Instigator, Priority);
	}

	void ClearMoveSpeedMultiplier(FInstigator Instigator)
	{
		InternalMovementSpeedMultiplier.Clear(Instigator);
	}

	float GetMovementSpeedMultiplier() const property
	{
		return InternalMovementSpeedMultiplier.Get();
	}

	float GetMovementSafetyMargin() const property final
	{
		// You should REALLY know what you are doing if you change this... / Tyko
		return 0.125;
	}

	float GetGroundedSafetyMargin() const property final
	{	
		// You should REALLY know what you are doing if you change this... / Tyko
		// NOTE: This value needs to match on the player capsule "AdditiveOffsetFromBottom"
		return 1.0;
	}

	void ClearCurrentGroundedState()
	{
		#if EDITOR
		devCheck(CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't clear 'CurrentGroundedState'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
		#endif

		CurrentContacts.GroundContact = FMovementHitResult();
	}

	access:DebugAccess
	FCustomMovementStatus GetCustomMovementStatusDebugInformation() const
	{
		return CurrentContacts.CustomStatus;
	}

	bool HasCustomMovementStatus(FName Status) const
	{
		return CurrentContacts.CustomStatus.Name == Status;
	}

	/** Allows for settings a custom movement status with custom debug colors. Use the 'HasCustomMovementStatus' to validate the status */
	void ApplyCustomMovementStatus(FName Status, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Low, FLinearColor DebugColor = FLinearColor::DPink)
	{
		FCustomMovementStatus NewStatus;
		NewStatus.Name = Status;
		NewStatus.DebugColor = DebugColor;
		InstigatedCustomMovementStatus.Apply(NewStatus, Instigator, Priority);
		CurrentContacts.CustomStatus = InstigatedCustomMovementStatus.Get();
	}

	void ClearCustomMovementStatus(FInstigator Instigator)
	{
		InstigatedCustomMovementStatus.Clear(Instigator);
		CurrentContacts.CustomStatus = InstigatedCustomMovementStatus.Get();
	}

	/**
	 * Should we act as a Control or Remote side when performing movement?
	 * If we are running movement locally, this will always return true.
	 * @see bool bResolveMovementLocally
	 */
	bool HasMovementControl() const
	{
		if(bResolveMovementLocally.Get())
			return true;
		
		return HasControl();
	}

	/**
	 * Apply a resolver extension.
	 * Multiple instigators can apply the same extension. As long as at least one instigator has applied an extension, it will be active.
	 * Keep in mind that extensions don't always support all kinds of resolvers.
	 * @see UMovementResolverExtension::SupportedResolverClasses
	 */
	void ApplyResolverExtension(TSubclassOf<UMovementResolverExtension> ExtensionClass, FInstigator Instigator)
	{
		if(!ensure(ExtensionClass.IsValid()))
			return;

		if(!ensure(Instigator.IsValid()))
			return;

		for(int i = 0; i < InstigatedResolverExtensions.Num(); i++)
		{
			if(InstigatedResolverExtensions[i].ExtensionClass == ExtensionClass)
			{
				InstigatedResolverExtensions[i].Instigators.AddUnique(Instigator);
				return;
			}
		}

		FInstigatedResolverExtension InstigatedResolverExtension;
		InstigatedResolverExtension.ExtensionClass = ExtensionClass;
		InstigatedResolverExtension.Extension = NewObject(this, ExtensionClass);
		InstigatedResolverExtension.Instigators.Add(Instigator);
		InstigatedResolverExtensions.Add(InstigatedResolverExtension);

		InstigatedResolverExtension.Extension.OnAdded(this);
	}

	/**
	 * Clear Instigator from only the resolver extension of a specific class.
	 * If there are no instigators left after the removal, the resolver extension will be removed.
	 */
	void ClearResolverExtension(TSubclassOf<UMovementResolverExtension> ExtensionClass, FInstigator Instigator)
	{
		if(!ensure(Instigator.IsValid()))
			return;

		for(int i = InstigatedResolverExtensions.Num() - 1; i >= 0; i--)
		{
			// Only clear the specified extension class
			if(InstigatedResolverExtensions[i].ExtensionClass.Get() != ExtensionClass.Get())
				continue;

			int RemovedIndex = InstigatedResolverExtensions[i].Instigators.RemoveSingleSwap(Instigator);
			if(RemovedIndex < 0)
				continue;

			if(InstigatedResolverExtensions[i].Instigators.IsEmpty())
			{
				InstigatedResolverExtensions[i].Extension.OnRemoved(this);
				InstigatedResolverExtensions.RemoveAtSwap(i);
			}
		}
	}

	/**
	 * Clear Instigator from all the applied resolver extensions.
	 * If there are no instigators left after the removal, the resolver extension will be removed.
	 */
	void ClearResolverExtensions(FInstigator Instigator)
	{
		if(!ensure(Instigator.IsValid()))
			return;

		for(int i = InstigatedResolverExtensions.Num() - 1; i >= 0; i--)
		{
			int RemovedIndex = InstigatedResolverExtensions[i].Instigators.RemoveSingleSwap(Instigator);
			if(RemovedIndex < 0)
				continue;

			if(InstigatedResolverExtensions[i].Instigators.IsEmpty())
			{
				InstigatedResolverExtensions[i].Extension.OnRemoved(this);
				InstigatedResolverExtensions.RemoveAtSwap(i);
			}
		}
	}

#if EDITOR
	bool CanRerunMovement() const
	{
		if(IsApplyingInParallel())
			return false;
		else
			return bCanRerunMovement;
	}
#endif

#if !RELEASE
	/**
	 * Owner/Movement, associated with this MovementComponent
	 */
	FTemporalLog GetTemporalLog() const final
	{
		return TEMPORAL_LOG(this, Owner, "Movement");
	}

	/**
	 * Owner/Movement/Ground
	 */
	FTemporalLog GetGroundPage() const final
	{
		return GetTemporalLog().Page("Ground");
	}

	/**
	 * Owner/Movement/Follow
	 */
	FTemporalLog GetFollowPage() const final
	{
		return GetTemporalLog().Page("Follow");
	}

	/**
	 * Owner/Movement/Follow/New Follows
	 */
	FTemporalLog GetNewFollowsPage() const final
	{
		return GetFollowPage().Page("New Follows", 1);
	}

	/**
	 * Owner/Movement/Follow/Moves
	 */
	FTemporalLog GetFollowMovesPage() const final
	{
		return GetFollowPage().Page("Moves", 2);
	}

	/**
	 * Owner/Movement/Follow/Unfollows
	 */
	FTemporalLog GetUnfollowsPage() const final
	{
		return GetFollowPage().Page("Unfollows", 3);
	}

	/**
	 * Provide an actor location, and the shape will be logged at that location, with ShapeWorldOffset applied.
	 */
	void LogMovementShapeAtLocation(FTemporalLog InTemporalLog, FString InName, FVector InLocation, FLinearColor InColor = FLinearColor::Red, float InLineWeight = 1.0) const
	{
		InTemporalLog.Shape(InName, InLocation + GetShapeWorldOffset(), CollisionShape.Shape, ShapeComponent.WorldRotation, InColor, InLineWeight);
	}

	protected void LogExtensions() const
	{
		const FTemporalLog ExtensionsLog = GetTemporalLog().Page("Extensions");
		const FTemporalLog AppliedExtensionsLog = ExtensionsLog.Section("Applied Extensions");
		AppliedExtensionsLog.Value("Count", InstigatedResolverExtensions.Num());

		for(int i = 0; i < InstigatedResolverExtensions.Num(); i++)
		{
			const FString ExtensionName = InstigatedResolverExtensions[i].ExtensionClass.Get().Name.ToString();
			const FTemporalLog ExtensionLog = AppliedExtensionsLog.Section(ExtensionName);
			for(int j = 0; j < InstigatedResolverExtensions[i].Extension.SupportedResolverClasses.Num(); j++)
			{
				ExtensionLog.Value(f"Supported Resolver Classes;[{j}]", InstigatedResolverExtensions[i].Extension.SupportedResolverClasses[j]);
			}
			for(int j = 0; j < InstigatedResolverExtensions[i].Instigators.Num(); j++)
			{
				ExtensionLog.Value(f"Instigators;[{j}]", InstigatedResolverExtensions[i].Instigators[j]);
			}
		}
	}

	protected void LogComponent() const
	{
		const FTemporalLog ComponentLog = GetTemporalLog().Page("Component");
		FVector LogLocation = Owner.ActorLocation;
		if(ShapeComponent != nullptr)
			LogLocation = ShapeComponent.WorldLocation;

		FName DefaultFollowMovementResolverName = DefaultFollowMovementResolver.IsValid() ? DefaultFollowMovementResolver.Get().Name : NAME_None;
		ComponentLog.Value("Internal;Default Follow Movement Resolver", DefaultFollowMovementResolverName);
		ComponentLog.Value("Internal;Can Rerun Movement", bCanRerunMovement);

		ComponentLog.Value("Resolve Movement Locally;Value", bResolveMovementLocally.Get());
		ComponentLog.Value("Resolve Movement Locally;Instigator", bResolveMovementLocally.CurrentInstigator);

		ComponentLog.Value("Defaults;Constrain Rotation To Horizontal Plane", bConstrainRotationToHorizontalPlane);
		ComponentLog.Value("Defaults;Apply Initial Collision Shape Automatically", bApplyInitialCollisionShapeAutomatically);
		ComponentLog.Value("Defaults;Allow Using Box Collision Shape", bAllowUsingBoxCollisionShape);

		ComponentLog.Value("Active Constrain Rotation To Horizontal Plane;Value", ActiveConstrainRotationToHorizontalPlane.Get());
		ComponentLog.Value("Active Constrain Rotation To Horizontal Plane;Instigator", ActiveConstrainRotationToHorizontalPlane.CurrentInstigator);

		ComponentLog.Value("Internal Movement Speed Multiplier;Value", InternalMovementSpeedMultiplier.Get());
		ComponentLog.Value("Internal Movement Speed Multiplier;Instigator", InternalMovementSpeedMultiplier.CurrentInstigator);

		ComponentLog.Value("Last Requested Movement;Delta", LastRequestedMovement.Delta);
		ComponentLog.Value("Last Requested Movement;Velocity", LastRequestedMovement.Velocity);
		
		ComponentLog.Value("Last Requested Impulse;Delta", LastRequestedImpulse.Delta);
		ComponentLog.Value("Last Requested Impulse;Velocity", LastRequestedImpulse.Velocity);

		if(AlignWithImpacts.IsDefaultValue())
		{
			ComponentLog.Value("Align With Impacts;Is Default", true);
		}
		else
		{
			FMovementAlignWithImpactSettings AlignWithImpactsSettings = AlignWithImpacts.Get();
			ComponentLog.Value("Align With Impacts;Is Active", AlignWithImpactsSettings.IsActive());
			ComponentLog.Value("Align With Impacts;Align With Ground", AlignWithImpactsSettings.bAlignWithGround);
			ComponentLog.Value("Align With Impacts;Align With Wall", AlignWithImpactsSettings.bAlignWithWall);
			ComponentLog.Value("Align With Impacts;Align With Ceiling", AlignWithImpactsSettings.bAlignWithCeiling);
			ComponentLog.Value("Align With Impacts;Instigator", AlignWithImpacts.CurrentInstigator);
		}

		ComponentLog.Value("Follow Edges;Value", FollowEdges.Get());
		ComponentLog.Value("Follow Edges;Instigator", FollowEdges.CurrentInstigator);

		ComponentLog.DirectionalArrow("WorldUp;Last Valid Ground Align WorldUp", LogLocation, LastValidGroundAlignWorldUp * 100);
		ComponentLog.DirectionalArrow("WorldUp;Cached WorldUp", LogLocation, CachedWorldUp * 100);

		ComponentLog.Value("Falling State;Was Falling", FallingState.bWasFalling);
		ComponentLog.Value("Falling State;Is Falling", FallingState.bIsFalling);
		ComponentLog.Value("Falling State;Start Time", FallingState.StartTime);
		ComponentLog.Value("Falling State;End Time", FallingState.EndTime);
		ComponentLog.Point("Falling State;Start Location", FallingState.StartLocation);
		ComponentLog.Point("Falling State;End Location", FallingState.EndLocation);
		ComponentLog.DirectionalArrow("Falling State;End Velocity", FallingState.EndLocation, FallingState.EndVelocity);

		ComponentLog.DirectionalArrow("Internal Movement Input;Value", LogLocation, InternalMovementInput.Get() * 100);
		ComponentLog.Value("Internal Movement Input;Instigator", InternalMovementInput.CurrentInstigator);

		ComponentLog.Value("Vertical Attachment Offset;Value", VerticalAttachmentOffset.Get());
		ComponentLog.Value("Vertical Attachment Offset;Instigator", VerticalAttachmentOffset.CurrentInstigator);

		ComponentLog.Value("Facing Orientation;Internal Facing Orientation", InternalFacingOrientation);
		ComponentLog.Value("Facing Orientation;Explicit Facing Orientation", ExplicitFacingOrientation);
		ComponentLog.Value("Facing Orientation;Explicit Facing Orientation Frame", ExplicitFacingOrientationFrame);

		ComponentLog.Section("Internal Gravity Direction")
			.Value("Mode", InternalGravityDirection.Get().Mode)
			.DirectionalArrow("Direction", LogLocation, InternalGravityDirection.Get().Direction)
			.Value("TargetComponent", InternalGravityDirection.Get().TargetComponent)
			.Value("Instigator", InternalGravityDirection.CurrentInstigator)
		;
	}
#endif

#if EDITOR
	UBaseMovementData AddRerunData(const UBaseMovementData Movement, UBaseMovementResolver Resolver)
	{
		if(!CanRerunMovement())
			return nullptr;

		auto RerunConfig = UMovementDebugConfig::Get();
		if(RerunConfig == nullptr)
			return nullptr;
		if(!RerunConfig.bEnableRerun)
			return nullptr;

		check(!Movement.bIsEditorRerunData);
		int Frame = UHazeTemporalLog::Get().CurrentLogFrameNumber;

		FMovementTemporalRerunData TemporalFrameState;
		
		TemporalFrameState.Frame = Frame;

		TemporalFrameState.Resolver = Resolver;

		TemporalFrameState.Data = Movement.GetRerunCopy(Resolver, Frame);

		for(const UMovementResolverExtension Extension : Resolver.Extensions)
		{
			TemporalFrameState.Extensions.Add(Extension.GetRerunCopy(Resolver, Frame));
		}

		TemporalFrames.Add(TemporalFrameState);
		return TemporalFrameState.Data;
	}
#endif	

#if EDITOR
	/**
	 * Iterate through the call stack to find the first UObject that is not this movement component.
	 */
	UObject FindExternalInstigator(bool bIgnoreResolvers, int SearchDepth = 10) const
	{
		for(int i = 0; i < SearchDepth; i++)
		{
			UObject InstigatorObject = Debug::EditorGetAngelscriptStackFrameObject(i);

			if(InstigatorObject == nullptr)
				continue;

			if(InstigatorObject == this)
				continue;

			auto MoveComp = Cast<UHazeMovementComponent>(InstigatorObject);
			if(MoveComp != nullptr)
				continue;

			if(bIgnoreResolvers)
			{
				if(InstigatorObject.Class.IsChildOf(UBaseMovementResolver))
					continue;
			}

			return InstigatorObject;
		}

		return nullptr;
	}

	private uint LastValidationFailTick = 0;
	/**
	 * Print (or throw) an error if the current tick group does not allow movement
	 */
	void ValidateTickGroup(FString FunctionName)
	{
		// No need to print multiple times per frame
		if(Time::FrameNumber == LastValidationFailTick)
			return;

		bool bIsValidTickGroup = false;
		if(HazeTick::CurrentTickGroup == EHazeTickGroup::MAX)
		{
			// MAX indicates we are not within a HazeTick, so we are in a Actor of Component tick. We allow these (for now 😈)
			bIsValidTickGroup = true;
		}
		else if(HazeTick::CurrentTickGroup >= EHazeTickGroup::BeforeMovement && HazeTick::CurrentTickGroup <= EHazeTickGroup::LastMovement)
		{
			bIsValidTickGroup = true;
		}

		//devCheck(bIsValidTickGroup, f"Trying to prepare move from Tick Group {Tick::CurrentTickGroup:n}, but it is only valid to apply movement from one of the movement tick groups!");
		if(!bIsValidTickGroup)
		{
			UObject InstigatorObject = FindExternalInstigator(true);
			if(InstigatorObject != nullptr)
				PrintToScreen(f"{InstigatorObject} called {FunctionName} on {Owner.GetActorNameOrLabel()} from Tick Group {HazeTick::CurrentTickGroup:n}, but it is only valid to apply movement from one of the movement tick groups! Please fix as this will soon be an error!", 0, FLinearColor::Red);
			
			LastValidationFailTick = Time::FrameNumber;
		}
	}
#endif

#if EDITOR
	TArray<FMovementTemporalRerunData> TemporalFrames;

	FMovementTemporalRerunData BinaryFindIndex(int ValueToFind) const
	{
		int StartIndex = 0;
		int EndIndex = TemporalFrames.Num() - 1;

		while (EndIndex >= StartIndex) 
		{
			const int MiddleIndex = StartIndex + Math::IntegerDivisionTrunc((EndIndex - StartIndex ), 2); 
			const FMovementTemporalRerunData& FrameData = TemporalFrames[MiddleIndex];
	
			if (FrameData.Frame == ValueToFind)
			 	return TemporalFrames[MiddleIndex];
			
			if(FrameData.Frame < ValueToFind)
				StartIndex = MiddleIndex + 1;
			else
				EndIndex = MiddleIndex - 1;
		}
		return FMovementTemporalRerunData();
	}

	// UFUNCTION(DevFunction)
	// private void DevSnapToGround(float OverrideTraceDistance = -1, bool bLerpVerticalOffset = false)
	// {
	// 	SnapToGround(true, OverrideTraceDistance, bLerpVerticalOffset);
	// }

	// UFUNCTION(DevFunction)
	// private void DevSnapToGroundMoveIntoGround()
	// {
	// 	Owner.AddActorWorldOffset(WorldUp * -10);
	// 	SnapToGround();
	// }
#endif

}