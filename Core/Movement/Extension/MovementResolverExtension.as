/**
 * Movement Resolver Extensions are generic interfaces for extending resolvers externally.
 * To use, call ApplyResolverExtension() and ClearResolverExtension() on a UHazeMovementComponent.
 * Assign ResolverClassToExtend to limit the resolvers this class will be added to.
 * 
 * # RERUNS
 * - Implement the CopyFrom() function and copy all members that are set in PrepareExtension().
 * - PrepareExtension() is not called during reruns, because we use that function to fetch data from the game world.
 * - Note that it is illegal to apply anything to an actor/component from inside the Resolver Extension!
 * - The only exception being PreApplyResolvedData(), which will not be called during reruns.
 */
UCLASS(Abstract, NotBlueprintable)
class UMovementResolverExtension
{
	access MovementEditDefaults = private, *(editdefaults), UHazeMovementComponent;

	access:MovementEditDefaults
	TArray<TSubclassOf<UBaseMovementResolver>> SupportedResolverClasses;

#if EDITOR
	bool bIsEditorRerunExtension = false;
	int EditorTemporalFrame = 0;
#endif

	/**
	 * Called when we were initially applied to the MovementComponent.
	 * 
	 * @see UHazeMovementComponent::ApplyResolverExtension()
	 */
	void OnAdded(UHazeMovementComponent MovementComponent)
	{
#if !RELEASE
		devCheck(!SupportedResolverClasses.IsEmpty(), f"{Class.Name} supports no resolvers! Resolver extensions need to define what resolvers it supports!");
#endif
	}

	/**
	 * Called when we were removed from the MovementComponent because all instigators have been removed.
	 * @see UHazeMovementComponent::ClearResolverExtension()
	 */
	void OnRemoved(UHazeMovementComponent MovementComponent)
	{

	}

	bool SupportsResolver(const UBaseMovementResolver InResolver) const
	{
		for(auto SupportedResolverClass : SupportedResolverClasses)
		{
			if(InResolver.IsA(SupportedResolverClass))
				return true;
		}

		return false;
	}

	/**
	 * Called from UBaseMovementResolver::PostPrepareResolver(). Which is after the entry point of each resolver.
	 * Since Extensions can be reused between resolvers on the same movement component,
	 * make sure to always prepare for this specific resolver in this function.
	 */
	void PrepareExtension(UBaseMovementResolver InResolver, const UBaseMovementData InMoveData)
	{
#if !RELEASE
		devCheck(SupportsResolver(InResolver), f"Resolver extension {Class.Name} does not support {InResolver.Class.Name}!");
#endif
	}

	/**
	 * Extends UBaseMovementResolver::PrepareNextIteration().
	 * @return False to cancel the current iteration.
	 */
	bool OnPrepareNextIteration(bool bFirstIteration)
	{
		return true;
	}

	/**
	 * Called after UBaseMovementResolver::PrepareNextIteration().
	 */
	void PostPrepareNextIteration(bool bFirstIteration)
	{
	}

	/**
	 * Called before UBaseMovementResolver::ResolveStartPenetrating handles the penetrating hit.
	 * @param OutResolvedLocation The resolved location, ideally no longer penetrating.
	 * @return True if we handled the hit, and don't want the resolver to handle it.
	 */
	bool PreResolveStartPenetrating(FMovementHitResult IterationHit, FVector&out OutResolvedLocation)
	{
		return false;
	}

	/**
	 * Called before UBaseMovementResolver dispatched HandleMovementImpact to child resolvers.
	 */
	EMovementResolverHandleMovementImpactResult PreHandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType)
	{
		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	/**
	 * Called from GetUnhinderedPendingLocation(), giving a chance to modify it before it is used.
	 */
	void OnUnhinderedPendingLocation(FVector& UnhinderedPendingLocation) const
	{
	}

	/**
	 * Called before UBaseMovementResolver::ApplyResolvedData
	 */
	void PreApplyResolvedData(UHazeMovementComponent MovementComponent)
	{
	}

	/**
	 * Called after UBaseMovementResolver::ApplyResolvedData
	 */
	void PostApplyResolvedData(UHazeMovementComponent MovementComponent)
	{
	}

#if !RELEASE
	/**
	 * Override to set a custom temporal logging page.
	 * @param MovementPageLog Page at path Owner/Movement
	 */
	FTemporalLog GetTemporalLogPage(FTemporalLog MovementPageLog, int SortOrder) const
	{
		return MovementPageLog.Page("Extensions").Page(Class.Name.ToString(), SortOrder);
	}

	/**
	 * Called from ResolveAndApplyMovementRequest() after resolving a move
	 */
	void LogPostIteration(FTemporalLog IterationSectionLog) const
	{
	}

	/**
	 * Called from ResolveAndApplyMovementRequest() after resolving a move
	 */
	void LogFinal(FTemporalLog ExtensionPage, FTemporalLog FinalSectionLog) const
	{
	}
#endif

#if EDITOR
	/**
	 * Implement in all base classes and copy every transient value set before and during PrepareExtension()
	 */
	void CopyFrom(const UMovementResolverExtension OtherBase)
	{
		check(!bIsEditorRerunExtension);
		check(!OtherBase.bIsEditorRerunExtension);
	}

	UMovementResolverExtension GetRerunCopy(UBaseMovementResolver RerunOuter, int Frame) const final
	{
		UMovementResolverExtension RerunExtension = Cast<UMovementResolverExtension>(NewObject(RerunOuter, Class));
		RerunExtension.CopyFrom(this);
		RerunExtension.bIsEditorRerunExtension = true;
		RerunExtension.EditorTemporalFrame = Frame;
		return RerunExtension;
	}
#endif
};