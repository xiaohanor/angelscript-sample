class ASanctuaryWellTowerSpawnOnSplineVolume : APlayerTrigger
{
	UPROPERTY(EditInstanceOnly)
	ASplineActor Spline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"HandlePlayerLeave");
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		FOnRespawnOverride RespawnOverride;
		RespawnOverride.BindUFunction(this, n"RespawnOnOtherPlayer");
		Player.ApplyRespawnPointOverrideDelegate(this, RespawnOverride);

	
	}

	UFUNCTION()
	private void HandlePlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearRespawnPointOverride(this);
	
	}

	UFUNCTION()
	private bool RespawnOnOtherPlayer(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		if(Spline == nullptr)
		{
			OutLocation.RespawnRelativeTo = Player.OtherPlayer.RootComponent;
			return true;
		}else{
			float Dist = Spline.Spline.GetClosestSplineDistanceToWorldLocation(Player.OtherPlayer.ActorLocation);
			OutLocation.RespawnTransform = Spline.Spline.GetWorldTransformAtSplineDistance(Dist);
			return true;
		}
	
	}
};