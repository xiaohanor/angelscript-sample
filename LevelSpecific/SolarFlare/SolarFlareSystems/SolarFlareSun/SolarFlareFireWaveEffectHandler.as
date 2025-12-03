struct FSolarFlareActivateWaveParams
{
	UPROPERTY()
	FVector SpawnLoc;

	UPROPERTY()
	USceneComponent AttachComp;
}

// struct FSolarFlareDeactivateWaveParams
// {

// }

UCLASS(Abstract)
class USolarFlareFireWaveEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ActivateWave(FSolarFlareActivateWaveParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DeactivateWave() {}
}