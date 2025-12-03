UCLASS(Abstract)
class USchmellTowerManagerEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, Transient, BlueprintReadOnly)
	ASchmellTowerManager Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<ASchmellTowerManager>(Owner);
	}

	// Triggers when the schmell tower starts rotating.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRotating() {}

	// Triggers when the schmell tower stops rotating.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopRotating() {}

	// Triggers when all platforms start extending/retracting.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformsStartMoving() {}

	// Triggers when all platforms stop extending/retracting.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformsStopMoving() {}

	// Triggers for every platform that is fully extended.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformSectionFullyExtended(FSchmellTowerManagerPlatformSectionEffectParams Params) {}

	// Triggers for every platform that is fully retracted.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformSectionFullyRetracted(FSchmellTowerManagerPlatformSectionEffectParams Params) {}

	UFUNCTION(BlueprintPure)
	TArray<ASchmellTowerBasePiece> GetBasePieces() const
	{
		return Manager.BasePieces;
	}

	UFUNCTION(BlueprintPure)
	TArray<ASchmelltowerPiece> GetPieces() const
	{
		return Manager.TowerPieces;
	}
}

struct FSchmellTowerManagerPlatformSectionEffectParams
{
	UPROPERTY()
	ASchmelltowerPiece Platform;
}