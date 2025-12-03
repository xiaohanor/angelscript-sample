
/**
 * Start a stick spin with the specified settings and instigator.
 * The OnStopped delegate will be called when the stick spin stops for any reason,
 * either because the player canceled or because StopStickSpin() was called.
 */
UFUNCTION(Category = "Stick Spin", Meta = (UseExecPins))
mixin void StartStickSpin(
	AHazePlayerCharacter Player, FStickSpinSettings Settings, FInstigator Instigator,
	FOnStickSpinStopped OnStopped = FOnStickSpinStopped())
{
	UStickSpinComponent Component = UStickSpinComponent::GetOrCreate(Player);
	Component.StartStickSpin(Settings, Instigator, OnStopped);
}

/**
 * Get the current state of the stick spinning the player is doing.
 * 
 * OBS! This is synced over network, but not reliably enough to trigger gameplay only on this value!
 * Only use this for visuals, or sync any gameplay triggered from this yourself.
 */
UFUNCTION(Category = "Stick Spin")
mixin FStickSpinState GetStickSpinState(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UStickSpinComponent Component = UStickSpinComponent::GetOrCreate(Player);
	return Component.GetStickSpinState(Instigator);
}

/**
 * Snap the current stick spin state to specific values.
 * 
 * Note that this will _not_ do anything on the remote side, the state is always synced from the control side.
 */
UFUNCTION(Category = "Stick Spin")
mixin void SnapStickSpinState(AHazePlayerCharacter Player, FInstigator StickSpinInstigator, FStickSpinState State)
{
	UStickSpinComponent Component = UStickSpinComponent::GetOrCreate(Player);
	Component.SnapStickSpinState(StickSpinInstigator, State);
}

/**
 * Stop the stick spin started with this instigator.
 */
UFUNCTION(Category = "Stick Spin")
mixin void StopStickSpin(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UStickSpinComponent Component = UStickSpinComponent::GetOrCreate(Player);
	Component.StopStickSpin(Instigator);
}