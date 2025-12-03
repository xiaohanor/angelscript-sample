event void FIslandWalkerSpawnerIntroStartSignature();
event void FIslandWalkerSpawnerIntroStopSignature();

class UIslandWalkerSpawnerComponent : UActorComponent
{
	bool bAllowSpawning = false;
	float SpawnCooldown = 0.0;
	TArray<UWalkerSpawnPointComponent> PendingSpawnPoints;

	UPROPERTY()
	FIslandWalkerSpawnerIntroStartSignature OnStart;
	UPROPERTY()
	FIslandWalkerSpawnerIntroStopSignature OnStop;
}

class UWalkerSpawnPointComponent : UArrowComponent
{
	default RelativeRotation = FRotator(90.0, 0.0, 0.0);
	int Index = -1;
}

class UWalkerSpawnAnimNotify : UAnimNotify
{
#if EDITOR
	default NotifyColor = FColor::Emerald;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Spawn minion";
	}	
}