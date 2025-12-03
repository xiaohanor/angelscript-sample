struct FInheritVelocityComponentTrackedData
{
	FTransform CurrentTransform;
	FTransform PreviousTransform;
	float DeltaTime;

	FInheritVelocityComponentTrackedData(USceneComponent Component)
	{
		CurrentTransform = Component.WorldTransform;
		PreviousTransform = CurrentTransform;
	}

	FVector GetVelocityAtPoint(FVector Point) const
	{
		if (DeltaTime < KINDA_SMALL_NUMBER)
			return FVector::ZeroVector;

		const FVector RelativeToCurrent =  CurrentTransform.InverseTransformPositionNoScale(Point);
		const FVector PreviousPoint = PreviousTransform.TransformPositionNoScale(RelativeToCurrent);
		const FVector Delta = Point - PreviousPoint;

		return Delta / DeltaTime;
	}
};

enum EInheritVelocityComponentTrackMode
{
	/**
	 * Only track the RootComponent movement, and apply that as the velocity on all other components.
	 * Cheapest, but will give wrong results if any components on this actor move relative to the root.
	 */
	TrackActorVelocity,

	/**
	 * Track only the components we specify. 
	 * Only components that move relative to their parent component (or the world) should be tracked.
	 * More expensive the more components we track.
	 */
	TrackComponents,
};

/**
 * Place on an actor to allow a moving actor to inherit the velocity from a followed component on the actor.
 * The Players can also find these components through attached actor parents.
 */
UCLASS(HideCategories = "Activation Cooking Tags Collision Navigation")
class UInheritVelocityComponent : UActorComponent
{
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PostUpdateWork;
	default PrimaryComponentTick.bStartWithTickEnabled = true;
	default PrimaryComponentTick.TickInterval = 0;

	access Movement = private, UHazeMovementComponent;
	access MovementEditDefaults = private, UHazeMovementComponent, * (editdefaults);
	access EditDefaults = private, UInheritVelocityComponentVisualizer, * (editdefaults);

	/**
	 * What components do we want to track?
	 */
	UPROPERTY(EditAnywhere, Category = "Tracking")
	access:EditDefaults EInheritVelocityComponentTrackMode TrackMode = EInheritVelocityComponentTrackMode::TrackActorVelocity;

	/**
	 * Component names we want to find and track.
	 * Every component that moves relative to it's parent will need to be tracked if it or any of its children will be followed.
	 */
	UPROPERTY(EditAnywhere, Category = "Tracking", Meta = (GetOptions="GetComponentNames", EditCondition = "TrackMode == EInheritVelocityComponentTrackMode::TrackComponents"))
	access:EditDefaults TArray<FName> TrackedComponentNames;

	/**
	 * If we are following a component, but that component is not tracked, should we try to find a tracked component in the parent chain of the followed component?
	 */
	UPROPERTY(EditAnywhere, Category = "Tracking")
	access:EditDefaults bool bFindTrackedComponentThroughParents = true;

	/**
	 * If a moving actor fails to find an InheritVelocityComponent on the followed components actor, it can optionally try to find one through the attach parent actor (if one exists).
	 * This is enabled by default on the players. If you want to exclude this component from that search, then set this to false.
	 */
	UPROPERTY(EditAnywhere, Category = "Tracking")
	access:MovementEditDefaults bool bAllowBeingFoundFromAttachedActors = true;

	UPROPERTY(EditAnywhere, Category = "Tracking")
	access:EditDefaults bool bTemporalLog = false;

	UPROPERTY(EditAnywhere, Category = "Tracking", Meta = (EditCondition = "bTemporalLog", EditConditionHides))
	access:EditDefaults FVector ActorVelocityRelativePoint = FVector::ZeroVector;

	/**
	 * When we start following, do we want to adjust the actors world space velocity to now be relative?
	 * This is usually preferred, but might have unintended effects.
	 */
	UPROPERTY(EditAnywhere, Category = "Follow")
	access:EditDefaults bool bAdjustVelocityOnFollow = true;

	/**
	 * When we stop following, do we want to maintain the same world velocity?
	 */
	UPROPERTY(EditAnywhere, Category = "Un Follow")
	access:EditDefaults bool bInheritVelocityOnUnFollow = true;

	/**
	 * How much of the follow components horizontal velocity do we want to inherit?
	 */
	UPROPERTY(EditAnywhere, Category = "Un Follow", Meta = (EditCondition = "bInheritVelocityOnUnFollow", ClampMin = "0.0", ClampMax = "1.0"))
	access:EditDefaults float UnFollowHorizontalVelocityInheritance = 1.0;

	/**
	 * How much of the follow components vertical velocity do we want to inherit?
	 */
	UPROPERTY(EditAnywhere, Category = "Un Follow", Meta = (EditCondition = "bInheritVelocityOnUnFollow", ClampMin = "0.0", ClampMax = "1.0"))
	access:EditDefaults float UnFollowVerticalVelocityInheritance = 1.0;

	/**
	 * Do we only want to inherit the follow components vertical velocity if it is moving upwards?
	 */
	UPROPERTY(EditAnywhere, Category = "Un Follow", Meta = (EditCondition = "bInheritVelocityOnUnFollow && UnFollowVerticalVelocityInheritance > 0"))
	access:EditDefaults bool bUnFollowOnlyInheritUpwardsVelocity = true;

	/**
	 * Only inherit velocity if it is in the same world direction as our current movement.
	 */
	UPROPERTY(EditAnywhere, Category = "Un Follow", Meta = (EditCondition = "bInheritVelocityOnUnFollow && UnFollowHorizontalVelocityInheritance > 0"))
	access:EditDefaults bool bUnFollowIgnoreIfInheritIsOppositeDirectionToMovement = false;

	private TMap<USceneComponent, FInheritVelocityComponentTrackedData> ComponentDataMap;
	private TArray<FInstigator> BlockedInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<USceneComponent> TrackedComponents;
		switch(TrackMode)
		{
			case EInheritVelocityComponentTrackMode::TrackActorVelocity:
				TrackedComponents.Add(Owner.RootComponent);
				break;

			case EInheritVelocityComponentTrackMode::TrackComponents:
			{
				for(auto TrackedComponentName : TrackedComponentNames)
				{
					auto TrackedComponent = USceneComponent::Get(Owner, TrackedComponentName);
					if(TrackedComponent != nullptr)
						TrackedComponents.Add(TrackedComponent);
				}
				break;
			}
		}

		for(auto TrackedComponent : TrackedComponents)
		{
			if(TrackedComponent.Mobility != EComponentMobility::Movable)
				continue;

			ComponentDataMap.Add(TrackedComponent, FInheritVelocityComponentTrackedData(TrackedComponent));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog TemporalLog = GetTemporalLog();
#endif

		for(auto& It : ComponentDataMap)
		{
			It.Value.DeltaTime = DeltaSeconds;
			It.Value.PreviousTransform = It.Value.CurrentTransform;
			It.Value.CurrentTransform = It.Key.WorldTransform;

#if !RELEASE
			if(bTemporalLog)
			{
				const bool bIsActor = It.Key == Owner.RootComponent;
				if(bIsActor)
				{
					const FVector ActorVelocityPoint = It.Key.WorldTransform.TransformPosition(ActorVelocityRelativePoint);
					const FVector ActorVelocity = It.Value.GetVelocityAtPoint(ActorVelocityPoint);
					TemporalLog.DirectionalArrow(f"Actor ({It.Key.Name}) Velocity", It.Value.CurrentTransform.Location, ActorVelocity);
				}
				else
				{
					const FVector Velocity = It.Value.GetVelocityAtPoint(It.Value.CurrentTransform.Location);
					TemporalLog.DirectionalArrow(f"{It.Key.Name} Velocity", It.Value.CurrentTransform.Location, Velocity);
				}
			}
#endif
		}
	}

	/**
	 * When we start following a moving component, we can adjust the velocity to make it relative to the followed component.
	 */
	access:Movement
	void AdjustVelocityOnFollow(UHazeMovementComponent MoveComp, USceneComponent FollowedComponent, FVector& HorizontalVelocity, FVector& VerticalVelocity) const
	{
		if(IsBlocked())
			return;

		FInheritVelocityComponentTrackedData TrackedData;
		if(!FindTrackedData(FollowedComponent, TrackedData))
			return;

		if(!bAdjustVelocityOnFollow)
			return;

#if !RELEASE
		FTemporalLog TemporalLog = GetTemporalLog().Section(f"AdjustVelocityOnFollow {MoveComp.Owner.ActorNameOrLabel}");
		if(bTemporalLog)
		{
			GetTemporalLog().Event(f"AdjustVelocityOnFollow for {MoveComp.Owner.ActorNameOrLabel}");
			TemporalLog.Section("Pre Inherit", 0)
				.DirectionalArrow("Pre Horizontal Velocity", MoveComp.Owner.ActorLocation, HorizontalVelocity)
				.DirectionalArrow("Pre Vertical Velocity", MoveComp.Owner.ActorLocation, VerticalVelocity)
			;
		}
#endif

		const FVector InheritVelocity = TrackedData.GetVelocityAtPoint(MoveComp.Owner.ActorLocation);
		FVector HorizontalInheritVelocity = InheritVelocity.VectorPlaneProject(MoveComp.WorldUp);
		FVector VerticalInheritVelocity = InheritVelocity.ProjectOnToNormal(MoveComp.WorldUp);

#if !RELEASE
		if(bTemporalLog)
		{
			TemporalLog.Section("Inherit Velocity", 1)
				.DirectionalArrow("Horizontal Inherit Velocity", MoveComp.Owner.ActorLocation, HorizontalInheritVelocity)
				.DirectionalArrow("Vertical Inherit Velocity", MoveComp.Owner.ActorLocation, VerticalInheritVelocity)
			;
		}
#endif

		// Don't remove the follow velocity if it were to speed us up further
		// float Dot = HorizontalVelocity.GetSafeNormal().DotProduct(InheritVelocity.GetSafeNormal());
		// if(Dot < 0)
		// 	return;

		// HorizontalVelocity -= InheritHorizontalVelocity * Dot;
		// VerticalVelocity -= VerticalInheritVelocity * Dot;

		HorizontalVelocity -= HorizontalInheritVelocity;
		//VerticalVelocity -= VerticalInheritVelocity;

#if !RELEASE
		if(bTemporalLog)
		{
			TemporalLog.Section("Post Inherit", 2)
				.DirectionalArrow("Post Horizontal Velocity", MoveComp.Owner.ActorLocation, HorizontalVelocity)
				.DirectionalArrow("Post Vertical Velocity", MoveComp.Owner.ActorLocation, VerticalVelocity)
			;
		}
#endif
	}
	
	/**
	 * When we stop following a moving component, we can inherit the velocity from it to keep the same world-space velocity.
	 */
	access:Movement
	void InheritVelocityOnUnFollow(UHazeMovementComponent MoveComp, USceneComponent FollowedComponent, FVector& HorizontalVelocity, FVector& VerticalVelocity) const
	{
		if(IsBlocked())
			return;

		if(!bInheritVelocityOnUnFollow)
			return;

		FInheritVelocityComponentTrackedData TrackedData;
		if(!FindTrackedData(FollowedComponent, TrackedData))
			return;

#if !RELEASE
		FTemporalLog TemporalLog = GetTemporalLog().Section(f"InheritVelocityOnUnFollow {MoveComp.Owner.ActorNameOrLabel}");
		if(bTemporalLog)
		{
			GetTemporalLog().Event(f"InheritVelocityOnUnFollow for {MoveComp.Owner.ActorNameOrLabel}");
			TemporalLog.Section("Pre Inherit", 0)
				.DirectionalArrow("Pre Horizontal Velocity", MoveComp.Owner.ActorLocation, HorizontalVelocity)
				.DirectionalArrow("Pre Vertical Velocity", MoveComp.Owner.ActorLocation, VerticalVelocity)
			;
		}
#endif

		const FVector InheritVelocity = TrackedData.GetVelocityAtPoint(MoveComp.Owner.ActorLocation);
		const FVector HorizontalInheritVelocity = InheritVelocity.VectorPlaneProject(MoveComp.WorldUp);
		const FVector VerticalInheritVelocity = InheritVelocity - HorizontalInheritVelocity;

#if !RELEASE
		if(bTemporalLog)
		{
			TemporalLog.Section("Inherit Velocity", 1)
				.DirectionalArrow("Horizontal Inherit Velocity", MoveComp.Owner.ActorLocation, HorizontalInheritVelocity)
				.DirectionalArrow("Vertical Inherit Velocity", MoveComp.Owner.ActorLocation, VerticalInheritVelocity)
			;
		}
#endif

		InheritHorizontalVelocityOnUnFollow(HorizontalVelocity, HorizontalInheritVelocity);
		InheritVerticalVelocityOnUnFollow(VerticalVelocity, VerticalInheritVelocity, MoveComp.WorldUp);

#if !RELEASE
		if(bTemporalLog)
		{
			TemporalLog.Section("Post Inherit", 2)
				.DirectionalArrow("Post Horizontal Velocity", MoveComp.Owner.ActorLocation, HorizontalVelocity)
				.DirectionalArrow("Post Vertical Velocity", MoveComp.Owner.ActorLocation, VerticalVelocity)
			;
		}
#endif
	}

	private void InheritHorizontalVelocityOnUnFollow(FVector& HorizontalVelocity, FVector HorizontalInheritVelocity) const
	{
		if(bUnFollowIgnoreIfInheritIsOppositeDirectionToMovement)
		{
			// If the inherited velocity points in a separate direction, ignore it
			if(HorizontalInheritVelocity.DotProduct(HorizontalVelocity) < 0)
				return;
		}

		HorizontalVelocity += HorizontalInheritVelocity * UnFollowHorizontalVelocityInheritance;
	}

	private void InheritVerticalVelocityOnUnFollow(FVector& VerticalVelocity, FVector VerticalInheritVelocity, FVector WorldUp) const
	{
		if(bUnFollowOnlyInheritUpwardsVelocity)
		{
			const float VerticalSpeed = VerticalInheritVelocity.DotProduct(WorldUp);

			// If we are moving downwards, ignore
			if(VerticalSpeed < 0)
				return;
		}

		VerticalVelocity += VerticalInheritVelocity * UnFollowVerticalVelocityInheritance;	
	}

	private bool FindTrackedData(USceneComponent FollowedComponent, FInheritVelocityComponentTrackedData&out OutTrackedData) const
	{
		USceneComponent TrackedComponent = FollowedComponent;

		if(TrackMode == EInheritVelocityComponentTrackMode::TrackActorVelocity)
			TrackedComponent = Owner.RootComponent;

		if(ComponentDataMap.Find(TrackedComponent, OutTrackedData))
			return true;

		if(bFindTrackedComponentThroughParents)
		{
			// We didn't find the followed component, but we will check the parents to see if they are tracked
			while(TrackedComponent.AttachParent != nullptr)
			{
				if(ComponentDataMap.Find(TrackedComponent.AttachParent, OutTrackedData))
					return true;

				TrackedComponent = TrackedComponent.AttachParent;
			}
		}

		return false;
	}

	void AddInheritBlocker(FInstigator BlockInstigator)
	{
		BlockedInstigators.AddUnique(BlockInstigator);
	}

	void RemoveInheritBlocker(FInstigator BlockInstigator)
	{
		if(!BlockedInstigators.Contains(BlockInstigator))
			return;
		
		BlockedInstigators.RemoveSingleSwap(BlockInstigator);
	}

	bool IsBlocked() const
	{
		return !BlockedInstigators.IsEmpty();
	}

#if !RELEASE
	FTemporalLog GetTemporalLog() const
	{
		return TEMPORAL_LOG(this, Owner, "Inherit Velocity");
	}
#endif

#if EDITOR
	UFUNCTION()
	private TArray<FName> GetComponentNames() const
	{
		return Editor::GetAllEditorComponentNamesOfClass(Owner, USceneComponent);
	}
#endif
};

#if EDITOR
class UInheritVelocityComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UInheritVelocityComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto InheritVelocityComp = Cast<UInheritVelocityComponent>(Component);
		if(InheritVelocityComp == nullptr)
			return;

		if(!Editor::IsComponentSelected(InheritVelocityComp))
			return;

		switch(InheritVelocityComp.TrackMode)
		{
			case EInheritVelocityComponentTrackMode::TrackActorVelocity:
			{
				DrawWorldString(
					f"{InheritVelocityComp.Name}: Tracking Actor",
					InheritVelocityComp.Owner.ActorLocation,
					FLinearColor::Green,
					bCenterText = true
				);
				break;
			}

			case EInheritVelocityComponentTrackMode::TrackComponents:
			{
				bool bFoundTrackedComponent = false;

				for(const FName& TrackedComponentName : InheritVelocityComp.TrackedComponentNames)
				{
					if(TrackedComponentName.IsNone())
						continue;

					auto TrackedComp = USceneComponent::Get(InheritVelocityComp.Owner, TrackedComponentName);
					if(TrackedComp == nullptr)
						continue;

					DrawWorldString(
						f"Tracking {TrackedComponentName} Velocity",
						TrackedComp.WorldLocation,
						FLinearColor::Green,
						bCenterText = true
					);

					bFoundTrackedComponent = true;
				}

				if(!bFoundTrackedComponent)
				{
					DrawWorldString(
						f"{InheritVelocityComp.Name}: Tracking no Components",
						InheritVelocityComp.Owner.ActorLocation,
						FLinearColor::Red,
						bCenterText = true
					);
				}
				
				break;
			}
		}
	}
}
#endif