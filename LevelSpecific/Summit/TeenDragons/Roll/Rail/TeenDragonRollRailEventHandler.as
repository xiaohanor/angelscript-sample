struct FTeenDragonRollRailEventParams
{
	UPROPERTY(BlueprintReadOnly)
	USummitTeenDragonRollRailSplineComponent RollRailComp;

	FTeenDragonRollRailEventParams(USummitTeenDragonRollRailSplineComponent InRollRailComp)
	{
		RollRailComp = InRollRailComp;
	}
}

class UTeenDragonRollRailEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnEnterRail(FTeenDragonRollRailEventParams Params) {};

	UFUNCTION(BlueprintEvent)
	void OnExitRail(FTeenDragonRollRailEventParams Params) {};
}