USTRUCT()
struct FCentipedeWaterOutletEventParams
{
	UPROPERTY()
	AHazePlayerCharacter BitingPlayer;
	UPROPERTY()
	AHazePlayerCharacter SprayingPlayer;
}

USTRUCT()
struct FCentipedeWaterOutletUnplugEventParams
{
	UPROPERTY()
	AHazePlayerCharacter BitingPlayer;
}

UCLASS(Abstract)
class UCentipedeWaterOutletEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnplugWaterOutlet(FCentipedeWaterOutletUnplugEventParams Params) 
	{
		DevPrintStringEvent("Centipede", "OnUnplugWaterOutlet " + Params.BitingPlayer.GetName() );
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttachWaterOutlet(FCentipedeWaterOutletEventParams Params) 
	{
		DevPrintStringEvent("Centipede", "OnAttachWaterOutlet");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDetachWaterOutlet(FCentipedeWaterOutletEventParams Params) 
	{
		DevPrintStringEvent("Centipede", "OnDetachWaterOutlet");
	}
};