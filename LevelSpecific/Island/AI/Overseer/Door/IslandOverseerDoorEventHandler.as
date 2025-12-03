UCLASS(Abstract)
class UIslandOverseerDoorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsStartMoving(FIslandOverseerEventHandlerDoorData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsStopMoving(FIslandOverseerEventHandlerDoorData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsClosed(FIslandOverseerEventHandlerDoorData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsStartMovingForced(FIslandOverseerEventHandlerDoorData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsStopMovingForced(FIslandOverseerEventHandlerDoorData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsStartMovingResisted(FIslandOverseerEventHandlerDoorData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsStopMovingResisted(FIslandOverseerEventHandlerDoorData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsStartMovingDamage(FIslandOverseerEventHandlerDoorData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsStopMovingDamage(FIslandOverseerEventHandlerDoorData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsStartMovingHeadCut(FIslandOverseerEventHandlerDoorData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsStopMovingHeadCut(FIslandOverseerEventHandlerDoorData Data) {}
}

struct FIslandOverseerEventHandlerDoorData
{
	UPROPERTY()
	TArray<AIslandSidescrollerBossDoor> Doors;

	FIslandOverseerEventHandlerDoorData(TArray<AIslandSidescrollerBossDoor> _Doors)
	{
		Doors = _Doors;
	}
}