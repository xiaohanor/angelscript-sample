// Applies swimming to be enabled. Can be overidden by a higher priority Inactive application.
UFUNCTION(DisplayName = "Enable Player Swimming")
mixin void EnableSwimming(AHazePlayerCharacter Player, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	UPlayerSwimmingComponent SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
	SwimmingComp.ApplySwimmingState(EPlayerSwimmingActiveState::Active, Instigator, Priority);
}

// Clears swimming from this instigator
UFUNCTION(DisplayName = "Disable Player Swimming")
mixin void DisableSwimming(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerSwimmingComponent SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
	SwimmingComp.ClearSwimmingState(Instigator);
}

// Applies swimming state. Can be overidden by higher priority states
UFUNCTION(DisplayName = "Apply Player Swimming State")
mixin void ApplySwimmingState(AHazePlayerCharacter Player, EPlayerSwimmingActiveState State, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	UPlayerSwimmingComponent SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
	SwimmingComp.ApplySwimmingState(State, Instigator, Priority);
}

// Clears the swimming state from this instigator
UFUNCTION(DisplayName = "Clear Player Swimming State")
mixin void ClearSwimmingState(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerSwimmingComponent SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
	SwimmingComp.ClearSwimmingState(Instigator);
}

UFUNCTION(DisplayName = "Is Player Swimming")
mixin bool IsSwimming(AHazePlayerCharacter Player)
{
	UPlayerSwimmingComponent SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
	return SwimmingComp.IsSwimming();
}

UFUNCTION()
mixin void SketchBookDisableSwimVFX(AHazePlayerCharacter Player)
{
	UPlayerSwimmingEffectHandler::Trigger_SketchBookDisableSwimVFX(Player);
}