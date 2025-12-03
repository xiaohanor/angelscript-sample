UCLASS(Abstract)
class UMagnetDroneSwitchBridgeEventHandler : UHazeEffectEventHandler
{
	AMagnetDroneSwitchBridge Bridge;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bridge = Cast<AMagnetDroneSwitchBridge>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MoveIn()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MoveOut()
	{
	}
};