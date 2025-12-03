delegate void FOnVoxPlayerPauseOnDeadRespawn(AHazePlayerCharacter Player);
delegate void FOnVoxPlayerPauseOnDeadDeath(AHazePlayerCharacter Player);

// Bind event to be called when the player is considered respawned in the VO systems. Event is only triggered once.
UFUNCTION(Category = "HazeVox")
void BindVoxOnPlayerRespawn(AHazePlayerCharacter Player, FOnVoxPlayerPauseOnDeadRespawn OnRespawnDelegate)
{
	auto PauseOnDeathCompoent = UPlayerPauseVoxOnDeathComponent::Get(Player);
	if (PauseOnDeathCompoent != nullptr)
	{
		PauseOnDeathCompoent.RespawnDelegates.AddUnique(OnRespawnDelegate);
	}
}

UFUNCTION(Category = "HazeVox")
void UnbindVoxOnPlayerRespawn(AHazePlayerCharacter Player, FOnVoxPlayerPauseOnDeadRespawn OnRespawnDelegate)
{
	auto PauseOnDeathCompoent = UPlayerPauseVoxOnDeathComponent::Get(Player);
	if (PauseOnDeathCompoent != nullptr)
	{
		PauseOnDeathCompoent.RespawnDelegates.Remove(OnRespawnDelegate);
	}
}

UFUNCTION(Category = "HazeVox")
void BindVoxOnPlayerDeath(AHazePlayerCharacter Player, FOnVoxPlayerPauseOnDeadDeath OnRespawnDelegate)
{
	auto PauseOnDeathCompoent = UPlayerPauseVoxOnDeathComponent::Get(Player);
	if (PauseOnDeathCompoent != nullptr)
	{
		PauseOnDeathCompoent.DeathDelegates.AddUnique(OnRespawnDelegate);
	}
}

UFUNCTION(Category = "HazeVox")
void UnbindVoxOnPlayerDeath(AHazePlayerCharacter Player, FOnVoxPlayerPauseOnDeadDeath OnRespawnDelegate)
{
	auto PauseOnDeathCompoent = UPlayerPauseVoxOnDeathComponent::Get(Player);
	if (PauseOnDeathCompoent != nullptr)
	{
		PauseOnDeathCompoent.DeathDelegates.Remove(OnRespawnDelegate);
	}
}

class UPlayerPauseVoxOnDeathComponent : UActorComponent
{
	UPROPERTY()
	TArray<FOnVoxPlayerPauseOnDeadRespawn> RespawnDelegates;

	UPROPERTY()
	TArray<FOnVoxPlayerPauseOnDeadDeath> DeathDelegates;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};
