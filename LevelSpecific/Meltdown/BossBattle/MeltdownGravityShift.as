class AMeltdownGravityShift : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	EInstigatePriority Priority = EInstigatePriority::Override;

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
		Player.OverrideGravityDirection(-ActorUpVector, this, Priority);
	}

	UFUNCTION()
	private void HandlePlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearGravityDirectionOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
			{
				if(IsOverlappingActor(Player))
					Player.OverrideGravityDirection(-ActorUpVector, this, Priority);
			}
	}
};