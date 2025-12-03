enum EMovementCustomStatus
{
	RemoteSideEvaluateGround,
	WantsToFall,
	ShouldApplySplineLock,
};

enum EMovementImpactType
{
	Unset,
	Invalid,
	NoImpact,
	Ground,
	Wall,
	Ceiling
};

enum EMovementDeltaType
{
	// The each part (horizontal and vertical) are added separately
	Native,

	// The entire delta is added as horizontal
	Horizontal,

	// The entire delta is added as vertical
	Vertical,

	// Only the horizontal part is added as horizontal
	HorizontalExclusive,

	// Only the vertical part is added as vertical
	VerticalExclusive,
};

enum EMovementEdgeType
{
	// Nothing has updated this
	Unset,

	// This is not an edge
	NoEdge,

	// This is an edge
	Edge,
};

enum EMovementEdgeHandlingType
{
	// We don't handled edges
	None,

	// Default movement, we can move over edges
	Leave,

	// We move over edges, but should change the world up
	Follow,

	// Stop the movement where an edge is
	Stop
};

enum EMovementEdgeNormalRedirectType
{
	// No changes to the impact normal is made
	None,

	// Smooth out the impact normal with the edge normal
	Soft,

	// Change the impact normal to be perpendicular to the edge normal
	Hard
};

namespace FMovementGravityDirection
{
	FMovementGravityDirection TowardsNegativeWorldUp()
	{
		FMovementGravityDirection GravityDirection;
		GravityDirection.Mode = EMovementGravityDirectionMode::WorldUp;
		return GravityDirection;
	}

	FMovementGravityDirection TowardsDirection(FVector Direction)
	{
		FMovementGravityDirection GravityDirection;
		GravityDirection.Mode = EMovementGravityDirectionMode::Direction;
		GravityDirection.Direction = Direction;
		return GravityDirection;
	}

	FMovementGravityDirection TowardsComponent(const USceneComponent TargetComponent)
	{
		FMovementGravityDirection GravityDirection;
		GravityDirection.Mode = EMovementGravityDirectionMode::TargetComponent;
		GravityDirection.TargetComponent = TargetComponent;
		return GravityDirection;
	}

	FMovementGravityDirection AlignWithGround()
	{
		FMovementGravityDirection GravityDirection;
		GravityDirection.Mode = EMovementGravityDirectionMode::AlignWithGround;
		return GravityDirection;
	}
};

/**
 * 
 */
struct FMovementGravityDirection
{
	EMovementGravityDirectionMode Mode = EMovementGravityDirectionMode::WorldUp;
	FVector Direction = FVector::ZeroVector;
	const USceneComponent TargetComponent = nullptr;
};

enum EMovementGravityDirectionMode
{
	WorldUp,
	Direction,
	TargetComponent,
	AlignWithGround,
};

/**
 * 
 */
struct FMovementAlignWithImpactSettings
{
	bool bAlignWithGround = false;
	bool bAlignWithWall = false;
	bool bAlignWithCeiling = false;	

	bool IsActive() const
	{
		return bAlignWithGround || bAlignWithWall || bAlignWithCeiling;
	}
};

struct FMovementInstigatorArray
{
	TArray<FInstigator> Instigators;
};

enum EMovementAnyContactOrder
{
	GroundWallCeiling,
	GroundCeilingWall,
	WallGroundCeiling,
	WallCeilingGround,
	CeilingGroundWall,
	CeilingWallGround,
};

/**
 * Contains the edge information of an impact
 */
struct FMovementEdge
{
	EMovementEdgeType Type = EMovementEdgeType::Unset;

	// Normal pointing in the direction of the edge, towards the "cliff"
	FVector EdgeNormal = FVector::ZeroVector;

	// Normal of the ground at the top of the edge
	FVector GroundNormal = FVector::ZeroVector;

	FVector OverrideRedirectNormal = FVector::ZeroVector;

	// How great must our distance be from the edge to be considered unstable?
	float UnstableDistance = -1;

	float Distance = 0;
	bool bIsOnEmptySideOfLedge = false;
	bool bMovingPastEdge = false;

	bool IsEdge() const
	{
		return Type == EMovementEdgeType::Edge;
	}

	/**
	 * Also checks if the edge normal and ground normal are normalized
	 */
	bool IsValidEdge() const
	{
		if(!IsEdge())
			return false;

		if(!EdgeNormal.IsNormalized())
			return false;

		if(!GroundNormal.IsNormalized())
			return false;

		return true;
	}

	/**
	 * Are we currently in the process of moving from the non-empty side of the edge to the empty side?
	 */
	bool IsMovingPastEdge() const
	{
		if(!IsEdge())
			return false;

		return bMovingPastEdge;
	}

	/**
	 * An unstable edge means that the movement shape is too far away from the edge and should start moving off of it.
	 */
	bool IsUnstable() const
	{
		// Can't be unstable if we are on the "solid" side of the ledge
		if(!bIsOnEmptySideOfLedge)
			return false;

		// This is a tyko remnant, and in my mind it does not make sense :serioustyko:
		// if(bMovingPastEdge)
		// 	return true;

		// If we are further from the edge than the UnstableDistance allows, we are unstable
		if(UnstableDistance >= 0 && Distance > UnstableDistance)
			return true;

		return false;
	}
};

enum EMovementResolverHandleMovementImpactResult
{
	/**
	 * The default result.
	 * Continue this iteration as if nothing happened.
	 */
	Continue,

	/**
	 * Skip this iteration, calculate new delta and perform a new iteration.
	 * If you have modified the iteration state, you most likely want to return this.
	 */
	Skip,

	/**
	 * Stop resolving entirely, finishing the resolve with the current iteration state.
	 */
	Finish
};

enum EMovementResolverAnyShapeTraceImpactType
{
	/**
	 * This is a regular Iteration movement sweep, which means that we actively moved.
	 */
	Iteration,

	/**
	 * This is a ground sweep.
	 */
	Ground,

	/**
	 * While we are pushing against a wall, we do an extra ground sweep to validate that we are grounded.
	 */
	GroundAtWall,

	/**
	 * The impact was that a MoveIntoPlayerShapeComponent moved into us.
	 */
	MoveIntoPlayer,
};

/**
 * 
 */
struct FMovementFallingData
{	
	bool bWasFalling = false;
	bool bIsFalling = false;
	float StartTime;
	float EndTime;

	UPROPERTY(BlueprintReadOnly)
	FVector StartLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector EndLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector EndVelocity;
};

struct FLinkedMovementResolverDataInformation
{
	void Init(const UBaseMovementData InMovementData, UBaseMovementResolver InResolver)
	{
		MovementData = InMovementData;
		DefaultResolver = InResolver;
		CachedResolver = GetResolverInternal();
	}

	UBaseMovementResolver GetResolver() const
	{
		return CachedResolver;
	}

	void Apply(FInstigatedMovementResolverInternal NewOverride)
	{
		bool bFound = false;
		for(FInstigatedMovementResolverInternal& It : OverrideResolvers)
		{
			if(It.Instigator == NewOverride.Instigator)
			{
				It.Resolver = NewOverride.Resolver;
				It.Priority = NewOverride.Priority;
				bFound = true;
				break;
			}
		}

		if(!bFound)
		{
			OverrideResolvers.Add(NewOverride);
		}

		// Cache the resolver
		CachedResolver = GetResolverInternal();
	}

	void Clear(FInstigator Instigator)
	{
		for(int i = OverrideResolvers.Num() - 1; i >= 0; --i)
		{
			FInstigatedMovementResolverInternal& It = OverrideResolvers[i];
			if(It.Instigator != Instigator)
				continue;

			OverrideResolvers.RemoveAtSwap(i);
			break; // there is always only one instigator
		}

		// Cache the resolver
		CachedResolver = GetResolverInternal();
	}

	private UBaseMovementResolver GetResolverInternal() const
	{
		UBaseMovementResolver BestFound = DefaultResolver;

		int BestPrio = -1;
		for(auto It : OverrideResolvers)
		{
			if(It.Resolver == nullptr)
				continue;

			if(int(It.Priority) > BestPrio)
			{
				BestPrio = int(It.Priority);
				BestFound = It.Resolver;
			}
		}

		return BestFound;
	}

	const UBaseMovementData MovementData;
	UBaseMovementResolver DefaultResolver;
	TArray<FInstigatedMovementResolverInternal> OverrideResolvers;
	private UBaseMovementResolver CachedResolver;
};

struct FInstigatedMovementResolverInternal
{
	UBaseMovementResolver Resolver;
	EInstigatePriority Priority;
	FInstigator Instigator;
};



/**
* 
*/
struct FMovementImpulse
{
	FVector Impulse = FVector::ZeroVector;
	FInstigator Instigator;
	uint AddedFrame = 0;
	float CooldownUntil = 0.0;

#if !RELEASE
	bool bDebugOnlyMovementPerformedWhenAdded = false;
#endif
};

/**
 *	 
 */
enum EMovementFollowComponentType
{
	// When the platform moves, the player is teleported to the new location regardless of collision
	Teleport,
	// When the platform moves, resolve collisions on the player as if the player moved normally
	ResolveCollision,

	/**
	 * This follow indicates a reference frame follow.
	 * Within a reference frame, any movement of the reference frame is treated as if it doesn't exist at all.
	 */
	ReferenceFrame,
};

/**
 *	 
 */
enum EMovementUnFollowComponentTransferVelocityType
{
	// The actor will lose the inherited velocity amount
	Release,

	// The inherited velocity amount will be transfer over as regular velocity 
	KeepInheritedVelocity
};

/**
 *	 
 */
enum EHazeMovementComponentAttachmentType
{
	/**
	 * Not set.
	 */
	None,

	/**
	 * Normal attachment. Stays until removed.
	 */
	Standard,

	/**
	 * Manually applied for this frame only.
	 */
	ForOneFrame,

	/**
	 * Internally added by the movement component.
	 * @see FollowGroundContact()
	 */
	InternalAutoGround,

	/**
	 * Internally added by the movement component.
	 * @see UpdateAutoFollowCrumbSyncedComponent()
	 */
	InternalAutoSynced,
};

/**
* 
*/
struct FHazeMovementComponentAttachment
{
	access Debug = private, MovementDebug;

	FInstigator Instigator;
	EInstigatePriority Priority = EInstigatePriority::Normal;

	USceneComponent Component;
	FName SocketName;
	EHazeMovementComponentAttachmentType Type = EHazeMovementComponentAttachmentType::Standard;
	EMovementFollowComponentType InheritType = EMovementFollowComponentType::Teleport;
	bool bFollowHorizontal = true;
	bool bFollowVerticalUp = true;
	bool bFollowVerticalDown = true;

	UInheritVelocityComponent InheritVelocityComp;

	access:Debug
	FVector Velocity = FVector::ZeroVector;
	access:Debug
	uint VelocityAddedFrame = 0;

	int64 FrameToBeRemovedAt = -1;

	// Has this attachment been marked for unfollowing before the next move?
	bool bDeferredUnfollow = false;

	// Used to link an attachment to a deferred unfollow
	uint DeferredUnfollowID;

#if !RELEASE
	const UObject DebugableInstigatorObject;
#endif

	FString ToString() const
	{
		if(SocketName != NAME_None)
		{
			return f"{Component}";
		}
		else
		{
			return f"{Component} {SocketName}";
		}
	}

	bool Equals(const FHazeMovementComponentAttachment& Other) const
	{
		return Instigator == Other.Instigator
			&& Priority == Other.Priority
			&& Component == Other.Component
			&& SocketName == Other.SocketName
			&& Type == Other.Type
			&& InheritType == Other.InheritType
			&& bFollowHorizontal == Other.bFollowHorizontal
			&& bFollowVerticalUp == Other.bFollowVerticalUp
			&& bFollowVerticalDown == Other.bFollowVerticalDown
		;
	}

	bool IsSameFollowTarget(const FHazeMovementComponentAttachment& Other) const
	{
		return Component == Other.Component
			&& SocketName == Other.SocketName
			&& InheritType == Other.InheritType
		;
	}

	bool IsValid() const
	{
		return Component != nullptr;
	}

	bool IsReferenceFrame() const
	{
		return InheritType == EMovementFollowComponentType::ReferenceFrame;
	}

	void Clear()
	{
		Instigator = FInstigator();
		Component = nullptr;
		SocketName = NAME_None;
		InheritVelocityComp = nullptr;
	}

	FTransform GetWorldTransform() const property
	{
		if (Component == nullptr)
			return FTransform();
		if (SocketName == NAME_None)
			return Component.GetWorldTransform();
		else
			return Component.GetSocketTransform(SocketName);
	}

	void UpdateShouldFollowHorizontalAndVertical()
	{
		if(Type == EHazeMovementComponentAttachmentType::InternalAutoGround)
		{
			// Only auto ground follows can update these values
			bFollowHorizontal = Component.HasTag(ComponentTags::InheritHorizontalMovementIfGround);
			bFollowVerticalUp = Component.HasTag(ComponentTags::InheritVerticalUpMovementIfGround);
			bFollowVerticalDown = Component.HasTag(ComponentTags::InheritVerticalDownMovementIfGround);
		}
	}

	void SetFollowVelocity(FVector InVelocity)
	{
		// Don't allow changing the velocity after we have deferred an unfollow
		if(bDeferredUnfollow)
			return;

		Velocity = InVelocity;
		VelocityAddedFrame = Time::FrameNumber;
	}

	FVector GetFollowVelocity() const
	{
		// If the velocity is old, we have no velocity
		if(!bDeferredUnfollow && Time::FrameNumber > VelocityAddedFrame + 1)
			return FVector::ZeroVector;
		
		return Velocity;
	}
};

/**
 * Adds up velocities during one frame, then resets them on the next frame.
 */
struct FMovementFrameVelocity
{
	private bool bIsValid = false;
	private FVector FrameVelocity = FVector::ZeroVector;
	private uint LastAddedFrame = 0;

#if EDITOR
	private TArray<FInstigator> DebugInstigators;
#endif

	void AddVelocity(FVector InVelocity, FInstigator Instigator)
	{
		const uint CurrentFrame = Time::FrameNumber;
		if(LastAddedFrame < CurrentFrame)
		{
			// The velocity we are representing is old, invalidate it
			Invalidate();
		}

		bIsValid = true;

		// Add together all follow velocities from this frame
		FrameVelocity += InVelocity;
		LastAddedFrame = CurrentFrame;

#if EDITOR
		DebugInstigators.Add(Instigator);
#endif
	}

	bool IsValid() const
	{
		if(!bIsValid)
			return false;

		if(Time::FrameNumber > LastAddedFrame + 1)
			return false;

		return true;
	}

	FVector GetVelocity() const
	{
		if(!IsValid())
			return FVector::ZeroVector;

		return FrameVelocity;
	}

	void Invalidate()
	{
		bIsValid = false;
		FrameVelocity = FVector::ZeroVector;
		LastAddedFrame = 0;

#if EDITOR
		DebugInstigators.Reset();
#endif
	}
}

enum EMovementOverrideFinalGroundType
{
	// Not active
	None,

	// Use the request
	Active,

	// If the request is an impact,
	// use that location to validate the ground location
	ActiveWithValidation
};

/**
 * 
 */
 struct FCustomMovementStatus
{
	FName Name = NAME_None;
	FLinearColor DebugColor = FLinearColor::DPink;
}

enum EMovementResolverNormalForImpactTypeGenerationType
{
	// Usually 'GetNormalForImpactTypeGeneration'
	Default,

	// Force use the normal of the impact
	Normal,

	// Force use the impact normal of the impact
	ImpactNormal,
};

struct FMovementResolverGroundTraceSettings
{
	/**
	 * If the ground is a start penetrating trace,
	 * we can resolve upwards trying to find a location
	 * we can actually stand on.
	 */
	bool bResolveStartPenetrating = true;

	/**
	 * If the grounded trace hits a wall,
	 * we redirect using the impact normal
	 * so we trace down to where the ground is.
	 */
	bool bRedirectTraceIfInvalidGround = false;

	/**
	 * This will ignore the 'GetNormalForImpactTypeGeneration'
	 * and make the ground trace use this.
	 */
	EMovementResolverNormalForImpactTypeGenerationType NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::Default;

	/**
	 * If we want to use a custom trace id.
	 */
	FName CustomTraceTag = NAME_None;

	/**
	 * EXPERIMENTAL: Ground trace with a "flat" bottom.
	 * This is faked since we still trace with a capsule.
	 * We do this by sweeping extra far, an extra cap radius to be exact, so that the edges where the capsule caps meets the flat sides reach as far down as the bottom of the capsule.
	 * On a valid blocking hit, we then pull this distance back depending on how far the impact point is from the capsule center, to fake a flat bottom.
	 */
	bool bFlatCapsuleBottom = false;
};

/**
* The movement may need to consider the orientation of the shape when using the shape,
* so for example, simply knowing that it is a capsule may not be enough information.
* This shape type is more specific in how the shape should be handled.
*/
enum EMovementShapeType
{
	Invalid,

	// A sphere, where the orientation does not matter. A capsule will be considered a sphere if the half height is less than or equal to the radius.
	Sphere,

	// The preferred capsule orientation, where the top and bottoms are the caps of the capsule, and the shape up aligns with world up.
	AlignedCapsule,

	// A flipped capsule, where up is down and down is up.
	FlippedCapsule,

	// A rotated capsule, where we cannot assume that the top and bottom is a cap of the capsule.
	NonAlignedCapsule,

	// A box, with any orientation.
	Box,
};

enum EMovementCapsuleImpactSide
{
	Unset,
	Bottom,
	Side,
	Top
};

struct FRelativeMovementAttachmentTransform
{
	FTransform RelativeTransform = FTransform::Identity;
	FVector Offset = FVector::ZeroVector;
};

struct FInstigatedResolverExtension
{
	TSubclassOf<UMovementResolverExtension> ExtensionClass;
	UMovementResolverExtension Extension;
	TArray<FInstigator> Instigators;
};

enum EMovementAutoFollowGroundType
{
	// Never perform any auto following
	Never,

	// Auto follow the ground if it is walkable
	FollowWalkable,

	// Auto follow any ground, walkable or not
	FollowAnyGround,
};

enum EMovementFindInheritVelocityComponentMethod
{
	/**
	 * Never try to find InheritVelocityComponent.
	 */
	NoInheritVelocity,

	/**
	 * Only look for a InheritVelocityComponent on the followed components actor.
	 */
	FindOnFollowedActor,

	/**
	 * Try and find a InheritVelocityComponent on the followed components actor.
	 * If it is not found, iterate through the attach parent actors too until one is found.
	 */
	FindOnFollowedActorAndParents,
};

struct FMovementDeferredUnfollow
{
	FInstigator Instigator;
	USceneComponent Component = nullptr;
	FName SocketName = NAME_None;

	// Used to link an attachment to a deferred unfollow
	uint ID;

	EMovementUnFollowComponentTransferVelocityType TransferVelocityType;

	bool IsSameTarget(FHazeMovementComponentAttachment InAttachment, FInstigator InInstigator) const
	{
		if(Instigator != InInstigator)
			return false;
		if(Component != InAttachment.Component)
			return false;
		if(SocketName != InAttachment.SocketName)
			return false;
		return true;
	}
};