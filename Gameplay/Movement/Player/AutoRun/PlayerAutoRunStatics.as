struct FPlayerAutoRunSettings
{
	// Whether to automatically start sprinting during this auto-run
	UPROPERTY()
	bool bSprint = false;

	// The magnitude of the automatic input. Can be used to slow down the movement. Values over 1.0 have no effect.
	UPROPERTY()
	float InputMagnitude = 1.0;

	// Whether to cancel the auto-run when the player gives input
	UPROPERTY()
	bool bCancelOnPlayerInput = true;

	// Whether to gradually slow down as we reach the end of the spline or the duration
	UPROPERTY()
	bool bSlowDownAtEnd = true;

	// If non-zero, automatically cancel the auto-run after the specified duration
	UPROPERTY()
	float CancelAfterDuration = 0.0;

	// Maximum angle in degrees that the player can deviate from the auto-run direction
	UPROPERTY(Meta = (EditCondition = "!bCancelOnPlayerInput", EditConditionHides))
	float MaxMovementDeviationAngle = 0.0;

	// Minimum velocity that the player has straight away when the auto-run starts
	UPROPERTY()
	float MinimumInitialVelocity = 0.0;
}

/**
 * Start an auto-run on the player along the specified spline.
 */
UFUNCTION(Category = "Player", DisplayName = "Apply Player Auto-Run Along Spline")
mixin void ApplyAutoRunAlongSpline(AHazePlayerCharacter Player, FInstigator Instigator, UHazeSplineComponent Spline, FPlayerAutoRunSettings AutoRunSettings)
{
	auto AutoRunComp = UPlayerAutoRunComponent::GetOrCreate(Player);

	FActiveAutoRun ActiveRun;
	ActiveRun.Spline = Spline;
	ActiveRun.Settings = AutoRunSettings;
	AutoRunComp.ActiveAutoRun.Apply(ActiveRun, Instigator);
}	

/**
 * Start an auto-run on the player in a static direction
 */
UFUNCTION(Category = "Player", DisplayName = "Apply Player Auto-Run In Direction")
mixin void ApplyAutoRunInDirection(AHazePlayerCharacter Player, FInstigator Instigator, FVector RunDirection, FPlayerAutoRunSettings AutoRunSettings)
{
	auto AutoRunComp = UPlayerAutoRunComponent::GetOrCreate(Player);

	FActiveAutoRun ActiveRun;
	ActiveRun.StaticDirection = RunDirection;
	ActiveRun.Settings = AutoRunSettings;
	AutoRunComp.ActiveAutoRun.Apply(ActiveRun, Instigator);
}

/**
 * Start an auto-run on the player walking forward in the direction they are currently facing.
 */
UFUNCTION(Category = "Player", DisplayName = "Apply Player Auto-Run Forward Facing")
mixin void ApplyAutoRunForwardFacing(AHazePlayerCharacter Player, FInstigator Instigator, FPlayerAutoRunSettings AutoRunSettings)
{
	auto AutoRunComp = UPlayerAutoRunComponent::GetOrCreate(Player);

	FActiveAutoRun ActiveRun;
	ActiveRun.StaticDirection = Player.ActorForwardVector;
	ActiveRun.Settings = AutoRunSettings;
	AutoRunComp.ActiveAutoRun.Apply(ActiveRun, Instigator);
}

/**
 * Stop any auto-run we've previously applied to the player.
 */
UFUNCTION(Category = "Player", DisplayName = "Clear Player Auto-Run")
mixin void ClearAutoRun(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto AutoRunComp = UPlayerAutoRunComponent::GetOrCreate(Player);
	AutoRunComp.ActiveAutoRun.Clear(Instigator);
}