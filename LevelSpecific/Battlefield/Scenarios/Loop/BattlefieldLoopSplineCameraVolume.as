class ABattlefieldLoopSplineCameraVolume : APlayerTrigger
{
	default BrushComponent.LineThickness = 5.0;

	UPROPERTY(EditAnywhere)
	ASplineFollowCameraActor MioSplineCam;

	UPROPERTY(EditAnywhere)
	ASplineFollowCameraActor ZoeSplineCam;

	UPROPERTY(EditAnywhere)
	float BlendTime = 3.0;

	float CamRotationDuration;
	TPerPlayer<bool> bWasPlayerSpawnedIn;
	TPerPlayer<float> RotationDurationMultiplier;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"PlayerLeave");
		// CamRotationDuration = ZoeSplineCam.
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// for (AHazePlayerCharacter Player : Game::Players)
		// {
		// 	if (bWasPlayerSpawnedIn[Player])
		// 	{
		// 		RotationDurationMultiplier[Player] = Math::FInterpConstantTo()
		// 	}
		// }
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		auto TeleportComp = UTeleportResponseComponent::Get(Player);
		float CurrentBlend = BlendTime;

		if (TeleportComp.HasTeleportedWithinFrameWindow(10)) 
			CurrentBlend = 0.0;
		
		if(Player.IsMio())
			Player.ActivateCamera(MioSplineCam, CurrentBlend, this, EHazeCameraPriority::High);
		else
			Player.ActivateCamera(ZoeSplineCam, CurrentBlend, this, EHazeCameraPriority::High);
	}

	UFUNCTION()
	private void PlayerLeave(AHazePlayerCharacter Player)
	{
		Player.DeactivateCameraByInstigator(this);
	}
};