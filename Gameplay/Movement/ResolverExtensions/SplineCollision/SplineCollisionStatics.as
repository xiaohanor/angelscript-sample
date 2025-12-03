/**
 * Apply a simple "collision" constraint between a movement component and some splines.
 * Imagine that all supplied splines become infinitely high walls.
 * Will use MoveComp.WorldUp for the vertical direction.
 * Currently only imitates sphere collision.
 * @param Splines The splines we want to collide with.
 * @param WorldUp How do we determine the WorldUp used in the collision? The spline walls will be infinitely high in this direction.
 */
UFUNCTION(BlueprintCallable)
mixin void ApplySplineCollision(
	UHazeMovementComponent MovementComponent,
	TArray<ASplineActor> Splines,
	FInstigator Instigator,
	ESplineCollisionWorldUp WorldUp = ESplineCollisionWorldUp::MovementWorldUp,
	EInstigatePriority Priority = EInstigatePriority::Normal
)
{
	if(MovementComponent == nullptr)
		return;

	if(!ensure(!Splines.IsEmpty(), "Spline Collision requires splines to collide with!"))
		return;

	if(!ensure(Instigator.IsValid(), "Invalid instigator supplied!"))
		return;

	auto SplineCollisionComp = USplineCollisionComponent::GetOrCreate(MovementComponent.Owner);
	if(!ensure(SplineCollisionComp != nullptr))
		return;

	SplineCollisionComp.AddSplines(Instigator, Splines);
	SplineCollisionComp.ApplyWorldUpOverride(WorldUp, Instigator, Priority);

	MovementComponent.ApplyResolverExtension(USplineCollisionResolverExtension, Instigator);
}

/**
 * Clear SplineCollision applied by Instigator.
 * NOTE: If any other instigator has applied spline collision, it may still be active after this, but the splines
 * that were applied together with the Instigator may be removed.
 */
UFUNCTION(BlueprintCallable)
mixin void ClearSplineCollision(UHazeMovementComponent MovementComponent, FInstigator Instigator)
{
	if(MovementComponent == nullptr)
		return;

	if(!ensure(Instigator.IsValid(), "Invalid instigator supplied!"))
		return;

	auto SplineCollisionComp = USplineCollisionComponent::Get(MovementComponent.Owner);
	if(SplineCollisionComp == nullptr)
		return;

	SplineCollisionComp.ClearSplines(Instigator);
	SplineCollisionComp.ClearWorldUpOverride(Instigator);

	MovementComponent.ClearResolverExtensions(Instigator);
}