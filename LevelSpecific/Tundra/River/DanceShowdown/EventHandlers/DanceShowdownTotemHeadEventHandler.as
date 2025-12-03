struct FDanceShowdownTotemHeadEventData
{
	UPROPERTY()
	UStaticMeshComponent Mesh;
};

UCLASS(Abstract)
class UDanceShowdownTotemHeadEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTotemHeadStartRotating(FDanceShowdownTotemHeadEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTotemHeadStopRotating(FDanceShowdownTotemHeadEventData EventData)
	{
	}
};