UCLASS(Abstract)
class USummitMageEffectEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TeleportTelegraphStart(FSummitMageEventTeleportParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TeleportStart(FSummitMageEventTeleportParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TeleportCompleted(FSummitMageEventTeleportParams Params)
	{
	}
}

struct FSummitMageEventTeleportParams
{
	UPROPERTY()
	AHazeActor TeleportIndicator;

	FSummitMageEventTeleportParams(AHazeActor InTeleportIndicator)
	{
		TeleportIndicator = InTeleportIndicator;
	}
}