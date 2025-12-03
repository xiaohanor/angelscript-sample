UCLASS(Abstract)
class USummitBabyDragonFruitEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFruitStartedGrowing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFruitStoppedGrowing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFruitPickedUp(FSummitBabyDragonFruitEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFruitEaten() {}
};

struct FSummitBabyDragonFruitEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	FSummitBabyDragonFruitEventData(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}
}