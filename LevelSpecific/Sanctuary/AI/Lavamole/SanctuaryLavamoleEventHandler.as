struct FSanctuaryLavaMoleOnDyingParams
{
	UPROPERTY()
	ASanctuaryLavamoleWhackSplitBody Head;
}

UCLASS(Abstract)
class USanctuaryLavamoleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAnticipateUp(FSanctuaryLavamoleOnOnAnticipateUpEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDigUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDigDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDying(FSanctuaryLavaMoleOnDyingParams Paramsy) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeath() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoulderTelegraph(FSanctuaryLavamoleOnBoulderTelegraphEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoulderAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMortarTelegraph(FSanctuaryLavamoleOnMortarTelegraphEventData Data) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnWhacked() {}

	// Lavamole is torn apart by centipede
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTornApart() {}
}

struct FSanctuaryLavamoleOnOnAnticipateUpEventData
{
	UPROPERTY()
	USceneComponent HoleMesh;

	FSanctuaryLavamoleOnOnAnticipateUpEventData(USceneComponent InHoleMesh)
	{
		HoleMesh = InHoleMesh;
	}
}

struct FSanctuaryLavamoleOnMortarTelegraphEventData
{
	UPROPERTY()
	FVector SpawnLocation;

	FSanctuaryLavamoleOnMortarTelegraphEventData(FVector InSpawnLocation)
	{
		SpawnLocation = InSpawnLocation;
	}
}

struct FSanctuaryLavamoleOnBoulderTelegraphEventData
{
	UPROPERTY()
	FVector SpawnLocation;

	FSanctuaryLavamoleOnBoulderTelegraphEventData(FVector InSpawnLocation)
	{
		SpawnLocation = InSpawnLocation;
	}
}

