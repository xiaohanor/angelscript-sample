/**
 * This will lock the players movement on the provided spline
 * @param RubberBandSettings Apply 'RubberBandSettings' to force the player to stay close to each other
 * @param EnterSettings If no custom enter settings are used, the player walks smoothly into the spline
 */
UFUNCTION(Meta = (AdvancedDisplay = "Priority, LockProperties, RubberBandSettings, EnterSettings"))
mixin void LockPlayerMovementToSpline(AHazePlayerCharacter Player, AHazeActor SplineActor, FInstigator Instigator,
	EInstigatePriority Priority = EInstigatePriority::Normal, 
	FPlayerMovementSplineLockProperties LockProperties = FPlayerMovementSplineLockProperties(),
	UPlayerSplineLockRubberBandSettings RubberBandSettings = nullptr, 
	UPlayerSplineLockEnterSettings EnterSettings = nullptr
)
{
	Player.LockMovementToSpline(SplineActor, Instigator, Priority, LockProperties, RubberBandSettings, EnterSettings);
}

/**
 * This will lock the players movement on the provided spline
 * @param RubberBandSettings Apply 'RubberBandSettings' to force the player to stay close to each other
 * @param EnterSettings If no custom enter settings are used, the player walks smoothly into the spline
 */
UFUNCTION(Meta = (AdvancedDisplay = "Priority, LockProperties, RubberBandSettings, EnterSettings"))
mixin void LockPlayerMovementToSplineComponent(AHazePlayerCharacter Player, UHazeSplineComponent Spline, FInstigator Instigator,
	EInstigatePriority Priority = EInstigatePriority::Normal, 
	FPlayerMovementSplineLockProperties LockProperties = FPlayerMovementSplineLockProperties(),
	UPlayerSplineLockRubberBandSettings RubberBandSettings = nullptr, 
	UPlayerSplineLockEnterSettings EnterSettings = nullptr
)
{
	Player.LockMovementToSplineComponent(Spline, Instigator, Priority, LockProperties, RubberBandSettings, EnterSettings);
}

UFUNCTION()
mixin void UnlockPlayerMovementFromSpline(AHazePlayerCharacter Player, FInstigator Instigator)
{
	Player.UnlockMovementFromSpline(Instigator);
}

UFUNCTION()
mixin bool IsPlayerMovementLockedToSpline(AHazePlayerCharacter Player)
{
	return Player.IsMovementLockedToSpline();
}