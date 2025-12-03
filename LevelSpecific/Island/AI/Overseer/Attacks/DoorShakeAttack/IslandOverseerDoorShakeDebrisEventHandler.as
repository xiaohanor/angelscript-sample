UCLASS(Abstract)
class UIslandOverseerDoorShakeDebrisEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnSpawn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnHit(FIslandOverseerDoorShakeDebrisEventHandlerOnHit Data) {}
}

struct FIslandOverseerDoorShakeDebrisEventHandlerOnHit
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	FIslandOverseerDoorShakeDebrisEventHandlerOnHit(AHazePlayerCharacter _Player)
	{
		Player = _Player;
	}
}