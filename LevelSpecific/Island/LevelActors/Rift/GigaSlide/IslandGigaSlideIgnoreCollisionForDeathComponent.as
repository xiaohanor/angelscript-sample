class UIslandGigaSlideIgnoreCollisionForDeathComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			UIslandGigaSlidePlayerComponent::GetOrCreate(Player).IgnoreCollisionActors.AddUnique(Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			UIslandGigaSlidePlayerComponent::GetOrCreate(Player).IgnoreCollisionActors.RemoveSingleSwap(Owner);
		}
	}
}