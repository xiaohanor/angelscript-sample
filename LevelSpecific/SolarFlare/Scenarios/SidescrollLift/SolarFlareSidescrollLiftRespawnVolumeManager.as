class ASolarFlareSidescrollLiftRespawnVolumeManager : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	TArray<ARespawnPointVolume> BottomRespawnVolumes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"SetPlayerRespawns");
	}

	UFUNCTION()
	private void SetPlayerRespawns(AHazePlayerCharacter Player)
	{
		float Distance = BIG_NUMBER;
		ARespawnPointVolume ChosenRespawnVolume;

		for (ARespawnPointVolume RespawnVolume : BottomRespawnVolumes)
		{
			RespawnVolume.DisableForPlayer(Player, this);
			RespawnVolume.EnableForPlayer(Player.OtherPlayer, this);

			float NewDistance = Player.OtherPlayer.GetDistanceTo(RespawnVolume);
			if (NewDistance < Distance)
			{
				Distance = NewDistance;
				ChosenRespawnVolume = RespawnVolume;
			}
		}
	}
};