class UVillageRespawnAutoRunComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FPlayerAutoRunSettings AutoRunSettings;
	default AutoRunSettings.bSprint = true;
	default AutoRunSettings.CancelAfterDuration = 2.0;
	default AutoRunSettings.bSlowDownAtEnd = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ARespawnPoint RespawnPoint = Cast<ARespawnPoint>(Owner);
		if (RespawnPoint == nullptr)
			return;

		RespawnPoint.OnRespawnAtRespawnPoint.AddUFunction(this, n"PlayerRespawned");	
	}

	UFUNCTION()
	private void PlayerRespawned(AHazePlayerCharacter RespawningPlayer)
	{
		RespawningPlayer.ApplyAutoRunForwardFacing(this, AutoRunSettings);
	}
}