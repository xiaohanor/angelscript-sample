UCLASS(Abstract)
class USanctuaryGrimbeastEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMeleeTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMeleeAttack(FSanctuaryGrimbeastOnMeleeAttackEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMeleeAttackHitPlayer(FSanctuaryGrimbeastOnMeleeAttackHitPlayerEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMortarTelegraph(FSanctuaryGrimbeastOnMortarTelegraphEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMortarAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoulderTelegraph(FSanctuaryGrimbeastOnBoulderTelegraphEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoulderAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeath() {}
}

struct FSanctuaryGrimbeastOnMeleeAttackEventData
{
	UPROPERTY()
	FVector AttackLocation;

	FSanctuaryGrimbeastOnMeleeAttackEventData(FVector InAttackLocation)
	{
		AttackLocation = InAttackLocation;
	}
}

struct FSanctuaryGrimbeastOnMeleeAttackHitPlayerEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	FSanctuaryGrimbeastOnMeleeAttackHitPlayerEventData(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}
}

struct FSanctuaryGrimbeastOnMortarTelegraphEventData
{
	UPROPERTY()
	FVector SpawnLocation;

	FSanctuaryGrimbeastOnMortarTelegraphEventData(FVector InSpawnLocation)
	{
		SpawnLocation = InSpawnLocation;
	}
}

struct FSanctuaryGrimbeastOnBoulderTelegraphEventData
{
	UPROPERTY()
	FVector SpawnLocation;

	FSanctuaryGrimbeastOnBoulderTelegraphEventData(FVector InSpawnLocation)
	{
		SpawnLocation = InSpawnLocation;
	}
}