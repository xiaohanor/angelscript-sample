struct FIceCavernRespawnPairs
{
	//Left
	UPROPERTY()
	ARespawnPoint Respawn1;
	//Right
	UPROPERTY()
	ARespawnPoint Respawn2;
}

class AIceCavernRespawnManager : APlayerTrigger
{
	default BrushComponent.LineThickness = 5.0;

	UPROPERTY(EditAnywhere)
	TArray<FIceCavernRespawnPairs> RespawnPairs;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
	
	int LargestIndexReached = -1;

	bool bIsEnabled;

	TPerPlayer<bool> bHasPlayerExitedVolume;
	TPerPlayer<bool> bIsPlayerLeftSide;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterRespawnPair");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeaveRespawnPair");
	}

	UFUNCTION()
	private void OnPlayerEnterRespawnPair(AHazePlayerCharacter Player)
	{
		if (bIsEnabled)
			return;

		bIsEnabled = true;
	}

	UFUNCTION()
	private void OnPlayerLeaveRespawnPair(AHazePlayerCharacter Player)
	{
		bHasPlayerExitedVolume[Player] = true;

		if (bHasPlayerExitedVolume[Player.OtherPlayer])
		{
			bIsEnabled = false;

			for (int i = 0; i < RespawnPairs.Num(); i++)
			{
				RespawnPairs[i].Respawn1.DisableForPlayer(Game::Mio, this);
				RespawnPairs[i].Respawn1.DisableForPlayer(Game::Zoe, this);
				RespawnPairs[i].Respawn2.DisableForPlayer(Game::Mio, this);
				RespawnPairs[i].Respawn2.DisableForPlayer(Game::Zoe, this);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsEnabled)
			return;

		float FurtherstDistance = FurtherstPlayerAlongSpline();
		
		int ChosenIndex = RespawnPairs.Num() - 1;

		for (int i = 0; i < RespawnPairs.Num(); i++)
		{
			float FurtherestRespawn = Math::Max(SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(RespawnPairs[i].Respawn1.ActorLocation), 
			SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(RespawnPairs[i].Respawn1.ActorLocation));

			if (FurtherestRespawn > FurtherstDistance)
			{
				ChosenIndex = i - 1;
			}
		}

		if (ChosenIndex > LargestIndexReached)
			LargestIndexReached = ChosenIndex;
		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FTransform SplineTransform = SplineActor.Spline.GetClosestSplineWorldTransformToWorldLocation(Player.ActorLocation);

			FVector DeltaLoc = Player.ActorLocation - SplineTransform.Location;
			float Dot = DeltaLoc.DotProduct(SplineTransform.Rotation.RightVector);

			if (UPlayerMovementComponent::Get(Player).IsOnAnyGround())
			{
				bIsPlayerLeftSide[Player] = Dot < 0.0;
			}

			for (int i = 0; i < RespawnPairs.Num(); i++)
			{
				if (i != LargestIndexReached)
				{
					RespawnPairs[i].Respawn1.DisableForPlayer(Player, this);
					RespawnPairs[i].Respawn2.DisableForPlayer(Player, this);
				}
				else
				{
					if (bIsPlayerLeftSide[Player])
					{
						RespawnPairs[i].Respawn1.EnableForPlayer(Player, this);
						RespawnPairs[i].Respawn2.DisableForPlayer(Player, this);
					}
					else
					{
						RespawnPairs[i].Respawn2.EnableForPlayer(Player, this);
						RespawnPairs[i].Respawn1.DisableForPlayer(Player, this);
					}
				}
			}
		}
	}

	float FurtherstPlayerAlongSpline()
	{
		return Math::Max(SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation), 
		SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation));
	}
};