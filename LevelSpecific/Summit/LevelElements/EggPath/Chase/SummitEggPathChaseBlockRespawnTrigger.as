class ASummitEggPathChaseBlockRespawnTrigger : APlayerTrigger
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	FName BlockInstigator = n"BlockRespawnInstigator";

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bBlockOnEnter = true;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bUnblockOnEnter = false;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bBlockOnExit = false;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bUnblockOnExit = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEntered");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEntered(AHazePlayerCharacter Player)
	{
		if(bBlockOnEnter)
			Player.OtherPlayer.BlockCapabilities(n"Respawn", BlockInstigator);
		if(bUnblockOnEnter)
			Player.OtherPlayer.UnblockCapabilities(n"Respawn", BlockInstigator);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if(bBlockOnExit)
			Player.OtherPlayer.BlockCapabilities(n"Respawn", BlockInstigator);
		if(bUnblockOnExit)
			Player.OtherPlayer.UnblockCapabilities(n"Respawn", BlockInstigator);
	}
};