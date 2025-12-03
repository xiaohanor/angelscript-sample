class ARedSpaceCubePlayerTigger : APlayerTrigger
{
	UPROPERTY(EditInstanceOnly)
	TArray<ARedSpaceCube> Cubes;

	bool bTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		if (bTriggered)
			return;

		bTriggered = true;

		for (ARedSpaceCube Cube : Cubes)
		{
			if (Cube.bMove)
				Cube.StartMoving();

			if (Cube.bScale)
				Cube.StartScaling();

			if (Cube.bRotate)
				Cube.StartRotating();
		}
	}
}