class ASkylineFlyingCarGroundMovementTrigger : APlayerTrigger
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		USkylineFlyingCarPilotComponent PilotComponent = USkylineFlyingCarPilotComponent::Get(Player);
		if (PilotComponent != nullptr)
		{
			PilotComponent.bInsideGroundMovementZone = true;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		USkylineFlyingCarPilotComponent PilotComponent = USkylineFlyingCarPilotComponent::Get(Player);
		if (PilotComponent != nullptr)
		{
			PilotComponent.bInsideGroundMovementZone = false;
		}
	}
}