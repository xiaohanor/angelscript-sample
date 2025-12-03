UCLASS(Abstract)
class USanctuaryLavaMomEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMeleeTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMeleeAttack(FSanctuaryLavaMomOnMeleeAttackEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMeleeAttackHitPlayer(FSanctuaryLavaMomOnMeleeAttackHitPlayerEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMortarTelegraph(FSanctuaryLavaMomOnMortarTelegraphEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMortarAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoulderTelegraph(FSanctuaryLavaMomOnBoulderTelegraphEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoulderAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeath() {}
}

struct FSanctuaryLavaMomOnMeleeAttackEventData
{
	UPROPERTY()
	FVector AttackLocation;

	FSanctuaryLavaMomOnMeleeAttackEventData(FVector InAttackLocation)
	{
		AttackLocation = InAttackLocation;
	}
}

struct FSanctuaryLavaMomOnMeleeAttackHitPlayerEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	FSanctuaryLavaMomOnMeleeAttackHitPlayerEventData(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}
}

struct FSanctuaryLavaMomOnMortarTelegraphEventData
{
	UPROPERTY()
	FVector SpawnLocation;

	FSanctuaryLavaMomOnMortarTelegraphEventData(FVector InSpawnLocation)
	{
		SpawnLocation = InSpawnLocation;
	}
}

struct FSanctuaryLavaMomOnBoulderTelegraphEventData
{
	UPROPERTY()
	FVector SpawnLocation;

	FSanctuaryLavaMomOnBoulderTelegraphEventData(FVector InSpawnLocation)
	{
		SpawnLocation = InSpawnLocation;
	}
}