/**
 * Similar to ADeathVolume, but a component instead of an actor.
 */
UCLASS(NotBlueprintable)
class UDeathVolumeComponent : UHazeMovablePlayerTriggerComponent
{
	/* Death effect to play when this kills a player */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Death Volume")
	TSubclassOf<UDeathEffect> DeathEffect;

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter OtherActor)
	{
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		Player.KillPlayer(DeathEffect = DeathEffect);
	}
};