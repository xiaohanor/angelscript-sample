UCLASS(Abstract)
class AVillageSpringyPerchPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent BeamRoot;

	UPROPERTY(DefaultComponent, Attach = BeamRoot)
	UPerchPointComponent PerchPointComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent PerchLandingComp;

	UPROPERTY(EditAnywhere)
	float LaunchForce = 2000.0;

	UPROPERTY(EditAnywhere)
	bool bLaunchImmediately = false;

	TArray<AHazePlayerCharacter> PerchingPlayers;

	TPerPlayer<float> UnblockTimer;
	TPerPlayer<bool> bPlayerBlocked;
	float JumpBlockTimer = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"StartPerching");
	}

	UFUNCTION()
	private void StartPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		if (bLaunchImmediately)
		{
			LaunchPlayer(Player);
		}
		else
		{
			PerchingPlayers.Add(Player);
		}

		BeamRoot.ApplyImpulse(PerchPointComp.WorldLocation, -FVector::UpVector * 1000.0);

		if (!bPlayerBlocked[Player])
			Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		
		UnblockTimer[Player] = JumpBlockTimer;
		bPlayerBlocked[Player] = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PerchingPlayers.Num() != 0)
		{
			if (BeamRoot.RelativeRotation.Pitch >= 2.0)
			{
				for (AHazePlayerCharacter Player : PerchingPlayers)
				{
					LaunchPlayer(Player);
				}

				PerchingPlayers.Empty();
			}
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!bPlayerBlocked[Player])
				continue;

			if (UnblockTimer[Player] > 0.0)
			{
				UnblockTimer[Player] -= DeltaTime;
			}
			else if (bPlayerBlocked[Player])
			{
				bPlayerBlocked[Player] = false;
				Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
			}
		}
	}

	void LaunchPlayer(AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(n"Perch", this);
		Player.ResetMovement();
		Player.AddMovementImpulse(FVector(0.0, 0.0, LaunchForce));
		Player.UnblockCapabilities(n"Perch", this);
	}
}