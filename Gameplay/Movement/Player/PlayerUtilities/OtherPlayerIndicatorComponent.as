enum EOtherPlayerIndicatorMode
{
	// Default mode: only visible when player is off-screen or far away
	Default,
	// The indicator is only visible when player is off-screen or far away, but is also visible in fullscreen
	DefaultEvenFullscreen,
	// The indicator is always visible regardless
	AlwaysVisible,
	// The indicator is always visible regardless, both indicators are visible in fullscreen
	AlwaysVisibleEvenFullscreen,
	// The indicator is never visible
	Hidden,
	// The indicator is visible on both players' screen, even if the indicator is of our own player
	AlwaysVisibleBothPlayers,
};

class UOtherPlayerIndicatorComponent : UActorComponent
{
	TInstigated<EOtherPlayerIndicatorMode> IndicatorMode(EOtherPlayerIndicatorMode::Default);
	TInstigated<FVector> OverrideIndicatorLocation;
	TInstigated<float> IndicatorOpacityMultiplier(1.0);
	TInstigated<FVector> IndicatorWorldOffset;

	UPROPERTY()
	TSubclassOf<UOtherPlayerIndicatorWidget> WidgetClass;
};

/**
 * Change the display mode for the other player indicator widget.
 * Affects the widget on the target player's _screen_, ie the widget that tracks the _other_ player.
 * 
 * OBS! Instigators must be cleared with ClearOtherPlayerIndicatorMode later.
 */
UFUNCTION(Category = "HUD")
mixin void ApplyOtherPlayerIndicatorMode(AHazePlayerCharacter Player, EOtherPlayerIndicatorMode Mode, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	auto IndicatorComp = UOtherPlayerIndicatorComponent::GetOrCreate(Player);
	IndicatorComp.IndicatorMode.Apply(Mode, Instigator, Priority);
}

/**
 * Clear a previously applied other player indicator mode.
 */
UFUNCTION(Category = "HUD")
mixin void ClearOtherPlayerIndicatorMode(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto IndicatorComp = UOtherPlayerIndicatorComponent::GetOrCreate(Player);
	IndicatorComp.IndicatorMode.Clear(Instigator);
}