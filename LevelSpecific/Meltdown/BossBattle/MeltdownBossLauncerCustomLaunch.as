class AMeltdownBossLauncherCustomLaunch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LaunchRotOffsetComp;

	UPROPERTY(DefaultComponent, Attach = LaunchRotOffsetComp)
	USceneComponent LauncherRoot;

	UPROPERTY(DefaultComponent, Attach = LauncherRoot)
	UHazeMovablePlayerTriggerComponent PlayerTrigger;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike LaunchTimeLike;

	UPROPERTY(EditAnywhere)
	float HorizontalForce = 1800.0;

	UPROPERTY(EditAnywhere)
	float VerticalForce = 6500.0;

	TArray<AHazePlayerCharacter> PlayersOnPlatform;

	bool bLaunchTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaunchTimeLike.BindUpdate(this, n"UpdateLaunch");
		LaunchTimeLike.BindFinished(this, n"FinishLaunch");

		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
		PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"PlayerLeave");
	}

	UFUNCTION()
	private void PlayerEnter(AHazePlayerCharacter Player)
	{
		PlayersOnPlatform.Add(Player);
		//LaunchTimeLike.PlayFromStart();
		LaunchPlayers();
	}

	UFUNCTION()
	void CustomLaunch()
	{
		
	}

	UFUNCTION()
	private void PlayerLeave(AHazePlayerCharacter Player)
	{
		PlayersOnPlatform.Remove(Player);
	}

	UFUNCTION()
	private void UpdateLaunch(float CurValue)
	{
		float Offset = Math::Lerp(0.0, 750.0, CurValue);
		LauncherRoot.SetRelativeLocation(FVector(0.0, 0.0, Offset));

		if (CurValue >= 0.6)
			LaunchPlayers();
	}

	UFUNCTION()
	private void FinishLaunch()
	{
		bLaunchTriggered = false;
		LaunchTimeLike.PlayFromStart();
	}

	void LaunchPlayers()
	{
		if (bLaunchTriggered)
			return;

		bLaunchTriggered = true;
		
		FVector LaunchForce = ActorForwardVector * HorizontalForce;
		LaunchForce.Z += VerticalForce;

		for (AHazePlayerCharacter Player : PlayersOnPlatform)
		{
			Player.ResetMovement();
			Player.AddMovementImpulse(LaunchForce);
			Player.SetMovementFacingDirection(ActorForwardVector);
		}
	}
}