/**
 * Enables aiming by plane where the origin is the player's center and the normal is supplied.
 * Constraint is added by priority, where the highest priority determines the active aiming plane.
 */
UFUNCTION(Category = "Aiming 2D", Meta = (AdvancedDisplay = "Priority"))
mixin void ApplyAiming2DPlaneConstraint(AHazePlayerCharacter Player,
	FVector Normal,
	FInstigator Instigator,
	EInstigatePriority Priority = EInstigatePriority::Normal)
{
	auto AimComp = UPlayerAimingComponent::Get(Player);
	AimComp.ApplyAiming2DPlaneConstraint(Normal, Instigator, Priority);
}

/**
 * Enables aiming by plane where the origin is the player's center and the normal is the camera direction.
 * Constraint is added by priority, where the highest priority determines the active aiming plane.
 */
UFUNCTION(Category = "Aiming 2D", Meta = (AdvancedDisplay = "Priority"))
mixin void ApplyAiming2DCameraPlaneConstraint(AHazePlayerCharacter Player,
	FInstigator Instigator,
	EInstigatePriority Priority = EInstigatePriority::Normal)
{
	auto AimComp = UPlayerAimingComponent::Get(Player);
	AimComp.ApplyAiming2DCameraPlaneConstraint(Instigator, Priority);
}

/**
 * Enables aiming by spline, plane is defined by player's origin and closest spline right vector.
 * Results in sidescroller-like aiming when movement is also locked to spline.
 * Constraint is added by priority, where the highest priority determines the active aiming plane.
 */
UFUNCTION(Category = "Aiming 2D", Meta = (AdvancedDisplay = "Priority"))
mixin void ApplyAiming2DSplineConstraint(AHazePlayerCharacter Player,
	AHazeActor SplineActor,
	FInstigator Instigator,
	EInstigatePriority Priority = EInstigatePriority::Normal)
{
	auto AimComp = UPlayerAimingComponent::Get(Player);
	if (!devEnsure(SplineActor != nullptr, "SplineActor is not a valid actor."))
		return;

	auto SplineComponent = Spline::GetGameplaySpline(SplineActor, AimComp);
	if(!devEnsure(SplineComponent != nullptr, f"Actor '{SplineActor.Name}' doesn't have a spline component."))
		return;

	AimComp.ApplyAiming2DSplineConstraint(SplineComponent, Instigator, Priority);
}

/**
 * Removes constraint by instigator, disabling 2D aiming entirely if no constraints are left.
 */
UFUNCTION(Category = "Aiming 2D")
mixin void ClearAiming2DConstraint(AHazePlayerCharacter Player,
	FInstigator Instigator)
{
	auto AimComp = UPlayerAimingComponent::Get(Player);
	if (AimComp == nullptr)
		return;

	AimComp.ClearAiming2DConstraint(Instigator);
}