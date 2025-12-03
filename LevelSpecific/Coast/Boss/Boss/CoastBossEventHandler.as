struct FCoastBossEventHandlerPhaseData
{
	UPROPERTY(BlueprintReadOnly)
	ECoastBossPhase NewPhase;
}

struct FCoastBossEventHandlerFormationData
{
	UPROPERTY(BlueprintReadOnly)
	ECoastBossFormation NewFormation;
}

struct FCoastBossEventHandlerSpawnedBulletsData
{
	UPROPERTY(BlueprintReadOnly)
	USceneComponent GunComponent;

	UPROPERTY(BlueprintReadOnly)
	FName GunSocket;

	UPROPERTY(BlueprintReadOnly)
	bool bTopMuzzleFlash = false;
	UPROPERTY(BlueprintReadOnly)
	FVector TopMuzzleLocation;

	UPROPERTY(BlueprintReadOnly)
	bool bBotMuzzleFlash = false;
	UPROPERTY(BlueprintReadOnly)
	FVector BotMuzzleLocation;

	UPROPERTY(BlueprintReadOnly)
	TArray<FVector> Locations;
}

struct FCoastBossEventHandlerMovementData
{
	UPROPERTY(BlueprintReadOnly)
	ECoastBossMovementMode MovementMode;
}

UCLASS(Abstract)
class UCoastBossEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChangedPhase(FCoastBossEventHandlerPhaseData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChangedFormation(FCoastBossEventHandlerFormationData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChangedMovementMode(FCoastBossEventHandlerMovementData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExtendMineLauncher() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRetractMineLauncher() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTakeDamage() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Died() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnedBullets(FCoastBossEventHandlerSpawnedBulletsData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnedMill() {}


};