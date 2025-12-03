struct FSummitDrawBridgeOnBridgeStartMovingParams
{
	UPROPERTY()
	FVector BridgeLocation;
};

struct FSummitDrawBridgeOnBridgeFinishMovingParams
{
	UPROPERTY()
	FVector BridgeLocation;

	UPROPERTY()
	FVector BridgeTipLocation;
};

UCLASS(Abstract)
class USummitDrawBridgeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBridgeStartMoving(FSummitDrawBridgeOnBridgeStartMovingParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBridgeFinishMoving(FSummitDrawBridgeOnBridgeFinishMovingParams Params)
	{
	}
};