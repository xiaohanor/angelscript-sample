event void FSkylineCarTowerRespawnElevatorSignature();
class ASkylineCarTowerRespawnElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxComp;

	bool bDoOnce = false;
	
	UPROPERTY(EditAnywhere)
	ASkylineCarTowerElevator Elevator;

	UPROPERTY()
	FSkylineCarTowerRespawnElevatorSignature OnRespawned;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Elevator.OnElevatorActivated.AddUFunction(this, n"HandlePlayerResetRespawn");
	}
	

	UFUNCTION()
	private void HandleEmergencyRespawn(AHazePlayerCharacter Player)
	{
		FOnRespawnOverride RespawnOverride;
		RespawnOverride.BindUFunction(this, n"RespawnOnOtherPlayer");
		Player.ApplyRespawnPointOverrideDelegate(this, RespawnOverride);
		OnRespawned.Broadcast();
	}

	UFUNCTION()
	private void HandlePlayerResetRespawn()
	{
		Game::Zoe.ClearRespawnPointOverride(this);
		Game::Mio.ClearRespawnPointOverride(this);
	}


	
	UFUNCTION()
	private bool RespawnOnOtherPlayer(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
			OutLocation.RespawnRelativeTo = Player.OtherPlayer.RootComponent;
			return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
		if(BoxComp.IsOverlappingActor(Game::Mio) && Game::Zoe.IsPlayerDead())
		{
			if(!bDoOnce)
				HandleEmergencyRespawn(Game::Zoe);	

				
		}

		if(BoxComp.IsOverlappingActor(Game::Zoe) && Game::Mio.IsPlayerDead())
		{
			if(!bDoOnce)
				HandleEmergencyRespawn(Game::Mio);	

			
		}
	}
};