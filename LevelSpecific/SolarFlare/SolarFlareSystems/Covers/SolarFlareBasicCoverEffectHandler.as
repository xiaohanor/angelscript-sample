struct FSolarFlareBasicCoverParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	bool bMovingUp = false;
}

UCLASS(Abstract)
class USolarFlareBasicCoverSplineMoverEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaveImpact(FSolarFlareBasicCoverParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving(FSolarFlareBasicCoverParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving(FSolarFlareBasicCoverParams Params)
	{
	}
};