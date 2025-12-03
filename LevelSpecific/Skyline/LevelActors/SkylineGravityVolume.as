class ASkylineGravityVolume : APlayerTrigger
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
	void UpdateGravity()
	{
		UpdateAlreadyInsidePlayers();
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
};