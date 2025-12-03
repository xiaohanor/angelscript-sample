struct FSummitCrystalObeliskDestructionParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FRotator Rotation;

	UPROPERTY()
	float Scale;
}

struct FSummitCrystalObeliskMetalMeltingParams
{
	UPROPERTY()
	FVector MetalLocation;

	UPROPERTY()
	UStaticMeshComponent MetalMesh;
}

UCLASS(Abstract)
class USummitCrystalObeliskEffectsHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	UNiagaraSystem DestructionSystem;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyCrystal(FSummitCrystalObeliskDestructionParams Params) 
	{
		// Print("DestroyCrystal");
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DestructionSystem, Params.Location, Params.Rotation);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MetalRegrowthStarted(FSummitCrystalObeliskMetalMeltingParams Params) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MetalRegrowthFinished(FSummitCrystalObeliskMetalMeltingParams Params) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MetalUnDissolveStarted(FSummitCrystalObeliskMetalMeltingParams Params) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MetalUnDissolveFinished(FSummitCrystalObeliskMetalMeltingParams Params) {};	
}