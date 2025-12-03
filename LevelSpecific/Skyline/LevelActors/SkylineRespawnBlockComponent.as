class USkylineRespawnBlockComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	bool bBlockOtherPlayerRespawnOnLeave = true;

	UPROPERTY(EditAnywhere)
	bool bZeroRespawnParameters = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto RespawnPointVolume = Cast<ARespawnPointVolume>(Owner);
		if (RespawnPointVolume == nullptr)
			return;

		RespawnPointVolume.OnActorBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		RespawnPointVolume.OnActorEndOverlap.AddUFunction(this, n"HandleEndOverlap");
	}

	UFUNCTION()
	private void HandleBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;


		if (Player.OtherPlayer.IsCapabilityTagBlocked(n"Respawn"))
			Player.OtherPlayer.UnblockCapabilities(n"Respawn", Player);

		if (bZeroRespawnParameters)
		{
			UPlayerHealthSettings::SetRespawnFadeInDuration(Player.OtherPlayer, 0.0, this);
			UPlayerHealthSettings::SetRespawnBlackScreenDuration(Player.OtherPlayer, 0.0, this);
			UPlayerHealthSettings::SetRespawnFadeOutDuration(Player.OtherPlayer, 0.0, this);
			UPlayerHealthSettings::SetRespawnTimer(Player.OtherPlayer, 0.0, this);
			UPlayerHealthSettings::SetEnableRespawnTimer(Player.OtherPlayer, false, this);
		}
	}

	UFUNCTION()
	private void HandleEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (bBlockOtherPlayerRespawnOnLeave)
		{
			Player.OtherPlayer.BlockCapabilities(n"Respawn", Player);
		}

		UPlayerHealthSettings::ClearRespawnFadeInDuration(Player.OtherPlayer, this);
		UPlayerHealthSettings::ClearRespawnBlackScreenDuration(Player.OtherPlayer, this);
		UPlayerHealthSettings::ClearRespawnFadeOutDuration(Player.OtherPlayer, this);
		UPlayerHealthSettings::ClearRespawnTimer(Player.OtherPlayer, this);
		UPlayerHealthSettings::ClearEnableRespawnTimer(Player.OtherPlayer, this);
	}
};