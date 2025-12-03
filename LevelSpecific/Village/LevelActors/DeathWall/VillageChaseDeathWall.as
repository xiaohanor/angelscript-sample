class AVillageChaseDeathWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AVillageChaseDeathWallBoulder> BoulderClass;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	bool bDebug = false;

	bool bActive = false;

	FSplinePosition SplinePosition;

	float MoveSpeed = 500.0;

	bool bBoulderLaunchedAtMio = false;
	bool bBoulderLaunchedAtZoe = false;

	UPROPERTY(EditAnywhere)
	float MinMoveSpeed = 300.0;

	UPROPERTY(EditAnywhere)
	bool bThrowBasedOnCameraLocation = false;

	UPROPERTY(EditAnywhere)
	float Margin = 300.0;

	TArray<AHazePlayerCharacter> ValidPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplinePosition = FSplinePosition(SplineActor.Spline, 0.0, true);

		ValidPlayers.Add(Game::Mio);
		ValidPlayers.Add(Game::Zoe);
	}

	UFUNCTION()
	void Activate(bool bTeleportToPlayers)
	{
		if (bTeleportToPlayers)
		{
			float PlayerSplineDist = SplinePosition.CurrentSpline.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation);
			SplinePosition = FSplinePosition(SplinePosition.CurrentSpline, PlayerSplineDist - 800.0, true);
			SetActorLocation(SplinePosition.WorldLocation);
		}

		bActive = true;
	}

	UFUNCTION()
	void Deactivate()
	{
		bActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		for (auto Player : Game::Players)
		{
			float PlayerSplineDist = SplinePosition.CurrentSpline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);

			if (SplinePosition.CurrentSplineDistance - Margin >= PlayerSplineDist)
			{
				if (Player.HasControl() && !Player.IsPlayerDead())
					LaunchBoulder(Player);
			}
		}

		float DistToClosestPlayer = GetHorizontalDistanceTo(Game::Mio);
		if (DistToClosestPlayer > GetHorizontalDistanceTo(Game::Zoe))
			DistToClosestPlayer = GetHorizontalDistanceTo(Game::Zoe);

		float SpeedAlpha = Math::GetMappedRangeValueClamped(FVector2D(300.0, 1400.0), FVector2D(0.0, 1.0), DistToClosestPlayer);

		MoveSpeed = Math::Lerp(MinMoveSpeed, 1000.0, SpeedAlpha);

		SplinePosition.Move(MoveSpeed * DeltaTime);

		FVector Loc = Math::VInterpTo(ActorLocation, SplinePosition.WorldLocation, DeltaTime, 2.0);
		FRotator Rot = Math::RInterpTo(ActorRotation, SplinePosition.WorldRotation.Rotator(), DeltaTime, 2.0);

		SetActorLocationAndRotation(Loc, Rot);

		if (bDebug)
			Debug::DrawDebugSphere(ActorLocation, 100.0, 12, FLinearColor::Red);
	}

	UFUNCTION()
	void InvalidatePlayer(AHazePlayerCharacter Player)
	{
		if (!ValidPlayers.Contains(Player))
			return;

		ValidPlayers.Remove(Player);
	}

	UFUNCTION()
	void LaunchBoulder(AHazePlayerCharacter Player)
	{
		if (!ValidPlayers.Contains(Player))
			return;

		if ((Player.IsMio() && bBoulderLaunchedAtMio) || (Player.IsZoe() && bBoulderLaunchedAtZoe))
			return;

		if (Player.IsMio())
			bBoulderLaunchedAtMio = true;
		else
			bBoulderLaunchedAtZoe = true;

		FVector SpawnLoc;
		if (bThrowBasedOnCameraLocation)
		{
			SpawnLoc = Game::Mio.ViewLocation - (Game::Mio.ViewRotation.ForwardVector * 500.0);
		}
		else
		{
			SpawnLoc = SplinePosition.CurrentSpline.GetWorldLocationAtSplineDistance(SplinePosition.CurrentSplineDistance - 1000.0);
			SpawnLoc.Z = Player.ActorLocation.Z;
		}

		AVillageChaseDeathWallBoulder Boulder = SpawnActor(BoulderClass, SpawnLoc);
		Boulder.ThrowBoulder(Player);

		Boulder.OnImpact.AddUFunction(this, n"BoulderImpact");
	}

	UFUNCTION()
	private void BoulderImpact(AVillageChaseDeathWallBoulder Boulder)
	{
		if (Boulder.TargetPlayer.IsMio())
			bBoulderLaunchedAtMio = false;
		else
			bBoulderLaunchedAtZoe = false;
	}
}