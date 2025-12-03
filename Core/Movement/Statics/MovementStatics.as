/**
 * Apply that we want our world up to align with the ground contact while resolving movement.
 * This can help with traveling up slopes, such as ramps since the walkable slope angle is relative to the world up.
 */
UFUNCTION(NotBlueprintCallable, meta = (NotInLevelBlueprint))
mixin void AddMovementAlignsWithGroundContact(AHazeActor Actor, FInstigator Instigator, bool bCanFallOfEdges = true, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return;

#if EDITOR
	devCheck(MoveComp.CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't set 'Impact alignment'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
#endif

	FMovementAlignWithImpactSettings AlignSettings;
	AlignSettings.bAlignWithGround = true;
	
	MoveComp.AlignWithImpacts.Apply(AlignSettings, Instigator, Priority);

	if(!bCanFallOfEdges)
		MoveComp.FollowEdges.Apply(true, Instigator, Priority);

	// This will activate the get custom gravity function in the movement component
	Actor.OverrideGravityAlignWithGround(Instigator, Priority);
}

UFUNCTION(NotBlueprintCallable, meta = (NotInLevelBlueprint))
mixin void RemoveMovementAlignsWithGroundContact(AHazeActor Actor, FInstigator Instigator)
{
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return;

#if EDITOR
	devCheck(MoveComp.CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't remove 'Impact alignment'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
#endif

	MoveComp.AlignWithImpacts.Clear(Instigator);
	MoveComp.FollowEdges.Clear(Instigator);
	Actor.ClearGravityDirectionOverride(Instigator);
}

/**
 * Apply that we want our world up to align with any contact while resolving movement.
 * This basically pretends that everything is ground, and we want to stand on it.
 */
UFUNCTION(NotBlueprintCallable, meta = (NotInLevelBlueprint))
mixin void AddMovementAlignsWithAnyContact(AHazeActor Actor, FInstigator Instigator, bool bCanFallOfEdges = true, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return;

#if EDITOR
	devCheck(MoveComp.CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't set 'Impact alignment'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
#endif

	FMovementAlignWithImpactSettings AlignSettings;
	AlignSettings.bAlignWithGround = true;
	AlignSettings.bAlignWithWall = true;
	AlignSettings.bAlignWithCeiling = true;

	MoveComp.AlignWithImpacts.Apply(AlignSettings, Instigator, Priority);

	if(!bCanFallOfEdges)
		MoveComp.FollowEdges.Apply(true, Instigator, Priority);

	// This will activate the get custom gravity function in the movement component
	Actor.OverrideGravityAlignWithGround(Instigator, Priority);
}

UFUNCTION(NotBlueprintCallable, meta = (NotInLevelBlueprint))
mixin void RemoveMovementAlignsWithAnyContact(AHazeActor Actor, FInstigator Instigator)
{
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return;

#if EDITOR
	devCheck(MoveComp.CurrentMovementStatus != EHazeMovementComponentStatus::Preparing, "Can't remove 'Impact alignment'. The movement component is locked for movement. All changes must be done before 'PrepareMove' is called.");
#endif

	MoveComp.AlignWithImpacts.Clear(Instigator);
	MoveComp.FollowEdges.Clear(Instigator);
	Actor.ClearGravityDirectionOverride(Instigator);
}

/**
 * Returns the raw velocity (performed translation / deltatime) the actor has this frame.
 * DevError if we could not get a RawTranslationVelocity from the actor.
 */
UFUNCTION(BlueprintPure)
mixin FVector GetRawLastFrameTranslationVelocity(AHazeActor Actor)
{
	if (Actor == nullptr)
    	return FVector::ZeroVector;

	if(!Actor.HasActorBegunPlay())
		return FVector::ZeroVector;

	FVector Velocity = FVector::ZeroVector;
	const bool bSuccess = Actor.TryGetRawLastFrameTranslationVelocity(Velocity);

	if(!bSuccess)
		devError(f"The actor {Actor} needs either a movement component or a HazeTranslationVelocityComponent to handle 'GetRawTranslationVelocity' function calls");

	return Velocity;
}

// Returns the raw velocity (performed translation / deltatime) the actor has this frame
UFUNCTION(BlueprintPure)
mixin bool TryGetRawLastFrameTranslationVelocity(AHazeActor Actor, FVector& OutVelocity)
{
	if (Actor == nullptr)
    	return false;

	if(!Actor.HasActorBegunPlay())
		return false;

	auto VelocityComp = UHazeRawVelocityTrackerComponent::Get(Actor);
	if(VelocityComp != nullptr)
	{
  		OutVelocity = VelocityComp.GetLastFrameTranslationVelocity();
		return true;
	}
	
	return false;
}

// Returns the raw performed translation the actor has this frame
UFUNCTION(BlueprintPure)
mixin bool TryGetRawLastFrameTranslationDelta(AHazeActor Actor, FVector& OutDelta)
{
	if (Actor == nullptr)
    	return false;

	if(!Actor.HasActorBegunPlay())
		return false;

	auto VelocityComp = UHazeRawVelocityTrackerComponent::Get(Actor);
	if(VelocityComp != nullptr)
	{
  		OutDelta = VelocityComp.GetLastFrameDeltaTranslation();
		return true;
	}
	
	return false;
}

// this is the current velocity, in the actors local space
UFUNCTION(NotBlueprintCallable, meta = (NotInLevelBlueprint))
mixin FVector GetActorLocalVelocity(AHazeActor Actor)
{
	if (Actor == nullptr)
		return FVector::ZeroVector;

	if(!Actor.HasActorBegunPlay())
		return FVector::ZeroVector;

	return Actor.GetActorQuat().UnrotateVector(Actor.GetActorVelocity());
}

UFUNCTION(NotBlueprintCallable, meta = (NotInLevelBlueprint))
mixin FVector GetGravityDirection(AHazeActor Actor)
{
	if (Actor == nullptr)
		return -FVector::UpVector;

	if(!Actor.HasActorBegunPlay())
		return FVector::ZeroVector;
	
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return -FVector::UpVector;

	return MoveComp.GetGravityDirection();
}

/**
 * Add an impulse to the movement component.
 * This is usually applied as delta from velocity.
 * OBS! This is applied when the movement is performed
 */
UFUNCTION()
mixin void AddMovementImpulse(AHazeActor Actor, FVector Impulse, FName NameOfImpulse = NAME_None)
{
	if (Actor == nullptr)
		return;

	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
	{
		devError(f"The actor {Actor} needs a movement component to handle 'AddMovementImpulse' function calls");
		return;
	}
	
	devCheck(!Impulse.ContainsNaN(), f"AddMovementImpulse was called on {Actor} with an invalid Impulse");	
	MoveComp.AddPendingImpulse(Impulse, NameOfImpulse);
}

/**
 * Add an impulse to the movement component, but disallow impulses with the same instigator more often than the specified cooldown.
 * This is usually applied as delta from velocity.
 * OBS! This is applied when the movement is performed
 */
UFUNCTION()
mixin void AddMovementImpulseWithCooldown(AHazeActor Actor, FVector Impulse, FInstigator Instigator, float Cooldown)
{
	if (Actor == nullptr)
		return;

	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
	{
		devError(f"The actor {Actor} needs a movement component to handle 'AddMovementImpulse' function calls");
		return;
	}
	
	devCheck(!Impulse.ContainsNaN(), f"AddMovementImpulse was called on {Actor} with an invalid Impulse");	
	MoveComp.AddPendingImpulseWithCooldown(Impulse, Instigator, Cooldown);
}

/** Adds an impulse to the actors movement component in the actors world up direction. 
 * The impulse is just high enough to reach the specified height (relative to the actor's current height) based on the movement component's gravity
 * 
 * @param bApplyImpulseToCounterVerticalSpeed Will apply an additional impulse equal to -VerticalSpeed * WorldUp,
 * ensures that the actor doesn't overshoot or undershoot height based on current vertical velocity.
 */
UFUNCTION()
mixin void AddMovementImpulseToReachHeight(AHazeActor Actor, float HeightToReach, bool bApplyImpulseToCounterVerticalSpeed = true, FName NameOfImpulse = NAME_None)
{
	if (Actor == nullptr)
		return;

	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
	{
		devError(f"The actor {Actor} needs a movement component to handle 'AddMovementImpulse' function calls");
		return;
	}

	devCheck(HeightToReach > 0.0, f"AddMovementImpulseToReachHeight was called on {Actor} with HeightToReach being 0 or negative");

	// Based on calculate maximum height formula: h=v²/(2g), rearranged to solve for upwards speed based on max height and gravity: v=sqrt(h*2g)
	float Impulse = Math::Sqrt(2.0 * MoveComp.GravityForce * HeightToReach);
	if(bApplyImpulseToCounterVerticalSpeed)
		Impulse -= MoveComp.VerticalSpeed;

	MoveComp.AddPendingImpulse(MoveComp.WorldUp * Impulse, NameOfImpulse);
}

/**
 * Set the direction that the gravity will be applied in. This will make the 'WorldUp' point in the opposite direction.
 */
UFUNCTION(NotBlueprintCallable, meta = (NotInLevelBlueprint))
mixin void OverrideGravityDirection(AHazeActor Actor, FVector Direction, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	if (Actor == nullptr)
		return;

	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
	{
		devError(f"The actor {Actor} needs a movement component to handle 'OverrideGravityDirection' function calls");
		return;
	}

	const FMovementGravityDirection GravityDirect = FMovementGravityDirection::TowardsDirection(Direction);
	MoveComp.OverrideGravityDirection(GravityDirect, Instigator, Priority);
}

/**
 * Set a component that the gravity should point towards. This will make the 'WorldUp' point in the opposite direction.
 */
UFUNCTION(NotBlueprintCallable, meta = (NotInLevelBlueprint))
mixin void OverrideGravityDirectionTarget(AHazeActor Actor, USceneComponent GravityOrigin, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	if (Actor == nullptr)
		return;

	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
	{
		devError(f"The actor {Actor} needs a movement component to handle 'OverrideGravityDirectionTarget' function calls");
		return;
	}
	
	const FMovementGravityDirection GravityDirect = FMovementGravityDirection::TowardsComponent(GravityOrigin);
	MoveComp.OverrideGravityDirection(GravityDirect, Instigator, Priority);
}

/**
 * Align the gravity direction with the last valid ground normal.
 */
UFUNCTION(NotBlueprintCallable, meta = (NotInLevelBlueprint))
mixin void OverrideGravityAlignWithGround(AHazeActor Actor, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	if (Actor == nullptr)
		return;

	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
	{
		devError(f"The actor {Actor} needs a movement component to handle 'OverrideGravityAlignWithGround' function calls");
		return;
	}
	
	const FMovementGravityDirection GravityDirect = FMovementGravityDirection::AlignWithGround();
	MoveComp.OverrideGravityDirection(GravityDirect, Instigator, Priority);
}

/* This will clear the gravity target */
UFUNCTION(NotBlueprintCallable, meta = (NotInLevelBlueprint))
mixin void ClearGravityDirectionOverride(AHazeActor Actor, FInstigator Instigator)
{
	if (Actor == nullptr)
		return;

	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
	{
		devError(f"The actor {Actor} needs a movement component to handle 'ClearGravityDirectionOverride' function calls");
		return;
	}

	MoveComp.ClearGravityDirectionOverride(Instigator);
}

UFUNCTION(BlueprintPure, Category = "Movement")
mixin FMovementFallingData GetFallingData(AHazeActor Actor)
{
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
	{
		devError(f"The actor {Actor} needs a movement component be able to return FallingData");
		return FMovementFallingData();
	}

	return MoveComp.GetFallingData();
}

UFUNCTION(BlueprintPure, Category = "Movement")
mixin bool IsInAir(AHazeActor Actor)
{
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return false;

	return MoveComp.IsInAir();
}

UFUNCTION(BlueprintPure, Category = "Movement")
mixin bool IsOnWalkableGround(AHazeActor Actor)
{
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return false;

	return MoveComp.IsOnWalkableGround();
}

/**
* Apply a resolver extension to an Actor.
* Multiple instigators can apply the same extension. As long as at least one instigator has applied an extension, it will be active.
* Keep in mind that extensions don't always support all kinds of resolvers.
* @see UMovementResolverExtension::SupportedResolverClasses
*/
UFUNCTION(BlueprintCallable, Category = "Movement")
mixin void ApplyResolverExtension(AHazeActor Actor, TSubclassOf<UMovementResolverExtension> ExtensionClass, FInstigator Instigator)
{
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return;

	MoveComp.ApplyResolverExtension(ExtensionClass, Instigator);
}

/**
* Clear Instigator from only the resolver extension of a specific class.
* If there are no instigators left after the removal, the resolver extension will be removed.
*/
UFUNCTION(BlueprintCallable, Category = "Movement")
mixin void ClearResolverExtension(AHazeActor Actor, TSubclassOf<UMovementResolverExtension> ExtensionClass, FInstigator Instigator)
{
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return;

	MoveComp.ClearResolverExtension(ExtensionClass, Instigator);
}

/**
* Clear Instigator from all the applied resolver extensions.
* If there are no instigators left after the removal, the resolver extension will be removed.
*/
UFUNCTION(BlueprintCallable, Category = "Movement")
mixin void ClearResolverExtensions(AHazeActor Actor, FInstigator Instigator)
{
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return;

	MoveComp.ClearResolverExtensions(Instigator);
}

/**
 * Place the actor on the ground, using the movement shape.
 * @param bValidateGround Do we want to sweep for the ground?
 * @param OverrideTraceDistance If > 0, we sweep that distance instead of the default distance (1)
 * @param bLerpVerticalOffset Lerp back to the ground over time based on player movement
 */
UFUNCTION(BlueprintCallable, Category = "Movement")
mixin void SnapToGround(AHazeActor Actor, bool bValidateGround = true, float OverrideTraceDistance = -1, bool bLerpVerticalOffset = false)
{
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return;

	MoveComp.SnapToGround(bValidateGround, OverrideTraceDistance, bLerpVerticalOffset);
}