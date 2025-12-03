/**
 * Start a button mash with the specified settings and instigator.
 * The OnCompleted delegate will be called when the player finishes the button mash.
 * The OnCanceled delegate will be called when the player cancels the button mash.
 */
UFUNCTION(Category = "Button Mash", Meta = (UseExecPins))
mixin void StartButtonMash(
	AHazePlayerCharacter Player, FButtonMashSettings Settings, FInstigator Instigator,
	FOnButtonMashCompleted OnCompleted = FOnButtonMashCompleted(),
	FOnButtonMashCompleted OnCanceled = FOnButtonMashCompleted())
{
	UButtonMashComponent Component = UButtonMashComponent::GetOrCreate(Player);
	Component.StartButtonMash(Settings, Instigator, OnCompleted, OnCanceled, EDoubleButtonMashType::None);
}

/**
 * Get the current progress of the button mash with the specified instigator.
 * 
 * OBS! This is synced over network, but not reliably enough to trigger gameplay only on this value!
 * Only use this for visuals, or sync any gameplay triggered from this yourself.
 */
UFUNCTION(Category = "Button Mash")
mixin float GetButtonMashProgress(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UButtonMashComponent Component = UButtonMashComponent::GetOrCreate(Player);
	return Component.GetButtonMashProgress(Instigator);
}

/**
 * Override the button mash progress of a currently active button mash.
 * The instigator must be the same one that the button mash was started with.
 * This will instantly snap the button mash's progress percentage.
 * 
 * Note that this will _not_ do anything on the remote side, the progress is always synced from the control side.
 */
UFUNCTION(Category = "Button Mash")
mixin void SnapButtonMashProgress(AHazePlayerCharacter Player, FInstigator ButtonMashInstigator, float NewProgress)
{
	UButtonMashComponent Component = UButtonMashComponent::GetOrCreate(Player);
	Component.SnapButtonMashProgress(ButtonMashInstigator, NewProgress);
}

/**
 * Override the multiplier to how fast progress in gained in the button mash.
 */
UFUNCTION(Category = "Button Mash")
mixin void SetButtonMashGainMultiplier(AHazePlayerCharacter Player, FInstigator ButtonMashInstigator, float GainMultiplier)
{
	UButtonMashComponent Component = UButtonMashComponent::GetOrCreate(Player);
	Component.SetButtonMashGainMultiplier(ButtonMashInstigator, GainMultiplier);
}

/**
 * Get the current mash rate of the button mash with the specified instigator.
 * 
 * OBS! This is synced over network, but not reliably enough to trigger gameplay only on this value!
 * Only use this for visuals, or sync any gameplay triggered from this yourself.
 */
UFUNCTION(Category = "Button Mash")
mixin void GetButtonMashCurrentRate(AHazePlayerCharacter Player, FInstigator Instigator, float&out MashRate, bool&out bIsMashRateSufficient)
{
	UButtonMashComponent Component = UButtonMashComponent::GetOrCreate(Player);
	Component.GetButtonMashCurrentRate(Instigator, MashRate, bIsMashRateSufficient);
}

/**
 * Specify whether a button mash is currently completable or not.
 * Uncompletable button mashes will fill up the entire bar but never finish.
 * The instigator must be the same one that the button mash was started with.
 * 
 * Note that this will _not_ do anything on the remote side. Only a player's control side
 * can determine whether a button mash is completable or not.
 * 
 * 
 * OBS! Not valid to call on double button mashes!
 */
UFUNCTION(Category = "Button Mash")
mixin void SetButtonMashAllowCompletion(AHazePlayerCharacter Player, FInstigator ButtonMashInstigator, bool bAllowCompletion)
{
	UButtonMashComponent Component = UButtonMashComponent::GetOrCreate(Player);
	Component.SetAllowButtonMashCompletion(ButtonMashInstigator, bAllowCompletion);
}

/**
 * Stop the button mash started with this instigator.
 * 
 * OBS! The completion/canceled delegates may or may not still be called later, depending on networking.
 */
UFUNCTION(Category = "Button Mash")
mixin void StopButtonMash(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UButtonMashComponent Component = UButtonMashComponent::GetOrCreate(Player);
	Component.StopButtonMash(Instigator);
}

namespace ButtonMash
{

/**
 * Start a double button mash that must be completed by both players.
 * The OnCompleted delegate will be called when the player finishes the button mash.
 * The OnCanceled delegate will be called when the player cancels the button mash.
 */
UFUNCTION(Category = "Button Mash", Meta = (UseExecPins))
void StartDoubleButtonMash(
	FButtonMashSettings MioSettings, FButtonMashSettings ZoeSettings, FInstigator Instigator,
	FOnButtonMashCompleted OnCompleted = FOnButtonMashCompleted(),
	FOnButtonMashCompleted OnCanceled = FOnButtonMashCompleted())
{
	UButtonMashComponent MioComponent = UButtonMashComponent::GetOrCreate(Game::Mio);
	MioComponent.StartButtonMash(MioSettings, Instigator, OnCompleted, OnCanceled,
		Game::FirstLocalPlayer.IsMio() ? EDoubleButtonMashType::Primary : EDoubleButtonMashType::Secondary);

	UButtonMashComponent ZoeComponent = UButtonMashComponent::GetOrCreate(Game::Zoe);
	ZoeComponent.StartButtonMash(ZoeSettings, Instigator, OnCompleted, OnCanceled,
		Game::FirstLocalPlayer.IsZoe() ? EDoubleButtonMashType::Primary : EDoubleButtonMashType::Secondary);
}

}