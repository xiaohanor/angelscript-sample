/**
 * Apply a movement constraint that keeps us inside a radius of an actor.
 * Vertical location along the CircleConstraint actor up is unconstrained.
 */
UFUNCTION(BlueprintCallable, DisplayName = "Apply Circle Constraint")
void BP_ApplyCircleConstraint(AHazeActor Actor, const ACircleConstraintResolverExtensionActor CircleConstraint, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	if(Actor == nullptr)
		return;

	if(!ensure(Instigator.IsValid(), "Invalid instigator supplied!"))
		return;

	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return;

	auto CircleConstraintComp = UCircleConstraintResolverExtensionComponent::GetOrCreate(Actor);
	CircleConstraintComp.CircleConstraintActor.Apply(CircleConstraint, Instigator, Priority);

	MoveComp.ApplyResolverExtension(UCircleConstraintResolverExtension, Instigator);
};

UFUNCTION(BlueprintCallable, DisplayName = "Clear Circle Constraint")
void BP_ClearCircleConstraint(AHazeActor Actor, FInstigator Instigator)
{
	if(Actor == nullptr)
		return;

	if(!ensure(Instigator.IsValid(), "Invalid instigator supplied!"))
		return;

	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if(MoveComp == nullptr)
		return;

	auto CircleConstraintComp = UCircleConstraintResolverExtensionComponent::GetOrCreate(Actor);
	CircleConstraintComp.CircleConstraintActor.Clear(Instigator);

	MoveComp.ClearResolverExtension(UCircleConstraintResolverExtension, Instigator);
};

/**
 * Apply a movement constraint that keeps us inside a radius of an actor.
 * Vertical location along the CircleConstraint actor up is unconstrained.
 */
mixin void ApplyCircleConstraint(UHazeMovementComponent MovementComponent, const ACircleConstraintResolverExtensionActor CircleConstraint, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	if(MovementComponent == nullptr)
		return;

	if(!ensure(Instigator.IsValid(), "Invalid instigator supplied!"))
		return;

	auto CircleConstraintComp = UCircleConstraintResolverExtensionComponent::GetOrCreate(MovementComponent.Owner);
	CircleConstraintComp.CircleConstraintActor.Apply(CircleConstraint, Instigator, Priority);

	MovementComponent.ApplyResolverExtension(UCircleConstraintResolverExtension, Instigator);
};

mixin void ClearCircleConstraint(UHazeMovementComponent MovementComponent, FInstigator Instigator)
{
	if(MovementComponent == nullptr)
		return;

	if(!ensure(Instigator.IsValid(), "Invalid instigator supplied!"))
		return;

	auto CircleConstraintComp = UCircleConstraintResolverExtensionComponent::GetOrCreate(MovementComponent.Owner);
	CircleConstraintComp.CircleConstraintActor.Clear(Instigator);

	MovementComponent.ClearResolverExtension(UCircleConstraintResolverExtension, Instigator);
};