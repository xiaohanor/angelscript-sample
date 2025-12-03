class ATundraTeleportTrigger : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	ARespawnPoint RespawnPoint;

	UPROPERTY(EditAnywhere)
	ATundraTeleportManager TeleportManager;

	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);
		TeleportManager.SetNewTeleportPoint(RespawnPoint);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();


	}


};