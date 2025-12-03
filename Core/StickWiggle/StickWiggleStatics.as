
/**
 * Start a stick wiggle with the specified settings and instigator.
 * The OnCompleted delegate will be called when the player finishes the stick wiggle.
 * The OnCanceled delegate will be called when the player cancels the stick wiggle.
 */
UFUNCTION(Category = "Stick Wiggle", Meta = (UseExecPins))
mixin void StartStickWiggle(
	AHazePlayerCharacter Player,
	FStickWiggleSettings Settings,
	FInstigator Instigator,
	FOnStickWiggleCompleted OnCompleted = FOnStickWiggleCompleted(),
	FOnStickWiggleCanceled OnCanceled = FOnStickWiggleCanceled())
{
	if(!devEnsure(Settings.WiggleIntensityIncreaseTime > 0, "Tried to start a StickWiggle with 0 or negative IncreaseTime, this is invalid."))
		return;

	auto Component = UStickWiggleComponent::GetOrCreate(Player);
	Component.StartStickWiggle(Settings, Instigator, OnCompleted, OnCanceled);
}

/**
 * Get the current state of the stick wiggling the player is doing.
 * 
 * OBS! This is synced over network, but not reliably enough to trigger gameplay only on this value!
 * Only use this for visuals, or sync any gameplay triggered from this yourself.
 */
UFUNCTION(Category = "Stick Wiggle")
mixin FStickWiggleState GetStickWiggleState(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto Component = UStickWiggleComponent::GetOrCreate(Player);
	return Component.GetStickWiggleState(Instigator);
}

/**
 * Snap the current stick wiggle state to specific values.
 * 
 * Note that this will _not_ do anything on the remote side, the state is always synced from the control side.
 */
UFUNCTION(Category = "Stick Wiggle")
mixin void SnapStickWiggleState(AHazePlayerCharacter Player, FInstigator StickWiggleInstigator, FStickWiggleState State)
{
	auto Component = UStickWiggleComponent::GetOrCreate(Player);
	Component.SnapStickWiggleState(StickWiggleInstigator, State);
}

/**
 * Stop the stick wiggle started with this instigator.
 */
UFUNCTION(Category = "Stick Wiggle")
mixin void StopStickWiggle(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto Component = UStickWiggleComponent::GetOrCreate(Player);
	Component.StopStickWiggle(Instigator);
}