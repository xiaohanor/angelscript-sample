UCLASS(Abstract)
class UKiteFlightPlayerEffectEventEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ActivateFlight() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DeactivateFlight() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Boost() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DespawnCompanion() {}
}