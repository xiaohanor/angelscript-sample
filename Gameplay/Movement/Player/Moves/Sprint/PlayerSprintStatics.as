
UFUNCTION(DisplayName = "Force Player Sprint")
mixin void ForceSprint(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerSprintComponent SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
	SprintComp.ForceSprint(Instigator);
}

UFUNCTION(DisplayName = "Clear Force Player Sprint")
mixin void ClearForceSprint(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerSprintComponent SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
	SprintComp.ClearForceSprint(Instigator);
}

UFUNCTION(DisplayName = "Is Player currently sprinting")
mixin bool IsSprintActive(AHazePlayerCharacter Player)
{
	UPlayerSprintComponent SprintComp = UPlayerSprintComponent::Get(Player);

	if(SprintComp != nullptr)
		return SprintComp.IsSprintToggled();

	return false;
}

UFUNCTION(DisplayName = "Is Player sprint toggled")
mixin bool IsSprintToggled(AHazePlayerCharacter Player)
{
	UPlayerSprintComponent SprintComp = UPlayerSprintComponent::Get(Player);

	if(SprintComp != nullptr)
		return SprintComp.IsSprinting();

	return false;
}

// Temporarily used for setting forced walk bool on player to skip sprint enter animation transition.
UFUNCTION(DisplayName = "Set In Force Walk Area")
mixin void EnableForceWalk(AHazePlayerCharacter Player, bool bActive, FInstigator Instigator)
{
	UPlayerSprintComponent SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
	if(bActive)
	{
		SprintComp.BlockSprint(Instigator);
	}
	else
	{
		SprintComp.ClearBlockSprint(Instigator);
	}
}