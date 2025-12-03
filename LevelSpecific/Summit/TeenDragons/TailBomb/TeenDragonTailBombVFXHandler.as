
struct FTeenDragonTailBombExplodeVFXData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;
}

UCLASS(Abstract)
class UTeenDragonTailBombVFXHandler : UHazeEffectEventHandler
{

	// Responde to 'TailBomb.OnExplode'
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode(FTeenDragonTailBombExplodeVFXData Data) 
	{

	}
}