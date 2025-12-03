class AVillageTowerClimbDeathWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UDeathTriggerComponent DeathTriggerComp;

	UPROPERTY(EditAnywhere)
	bool bDebug = false;

	bool bActive = false;

	float CurrentHeight = 0.0;
	float HeightOffset = 650.0;

	UFUNCTION()
	void Activate()
	{
		CurrentHeight = ActorLocation.Z;
		bActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		float LowestPlayerHeight = BIG_NUMBER;
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (!Player.IsPlayerDead() && Player.ActorLocation.Z <= LowestPlayerHeight)
				LowestPlayerHeight = Player.ActorLocation.Z;
		}

		CurrentHeight = Math::Clamp(LowestPlayerHeight - HeightOffset, CurrentHeight, BIG_NUMBER);

		FVector Loc = ActorLocation;
		Loc.Z = CurrentHeight;
		SetActorLocation(Loc);

		if (bDebug)
			Debug::DrawDebugBox(ActorLocation, DeathTriggerComp.Shape.BoxExtents, ActorRotation, FLinearColor::Red, 10.0);
	}

	UFUNCTION()
	void ResetPlayerMovement(AHazePlayerCharacter Player)
	{
		Player.ResetMovement();
	}
}