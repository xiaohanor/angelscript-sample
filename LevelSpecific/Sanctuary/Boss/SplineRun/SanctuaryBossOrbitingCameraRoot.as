event void FSanctuaryBossPlayerLaunchFinishedSignature();

class ASanctuaryBossOrbitingCameraRoot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike OrbitTimeLike;
	default OrbitTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FHazeTimeLike LaunchPlayersTimeLike;
	default LaunchPlayersTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint TargetRespawnPoint;

	UPROPERTY()
	FSanctuaryBossPlayerLaunchFinishedSignature OnPlayerLaunchFinished;

	TPerPlayer<FVector> StartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OrbitTimeLike.BindUpdate(this, n"OrbitTimeLikeUpdate");
		LaunchPlayersTimeLike.BindUpdate(this, n"LaunchPlayersTimeLikeUpdate");
		LaunchPlayersTimeLike.BindFinished(this, n"LaunchPlayersTimeLikeFinished");
		
	}

	UFUNCTION()
	void ActivateCameraOrbit()
	{
		OrbitTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void OrbitTimeLikeUpdate(float CurrentValue)
	{
		SetActorRotation(FRotator(0.0, Math::Lerp(0.0, -360.0, CurrentValue), 0.0));
	}

	UFUNCTION()
	void LaunchPlayers()
	{
		for (auto Player : Game::GetPlayers())
		{
			StartLocation[Player] = Player.GetActorLocation();
			Player.SetActorRotation(TargetRespawnPoint.GetActorRotation());
		}
			

		LaunchPlayersTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void LaunchPlayersTimeLikeUpdate(float CurrentValue)
	{
		for (auto Player : Game::GetPlayers())
		{
			FVector Location = Math::Lerp(StartLocation[Player], TargetRespawnPoint.GetPositionForPlayer(Player).Location, CurrentValue);
			Player.SetActorLocation(Location);
		}
	}

	UFUNCTION()
	private void LaunchPlayersTimeLikeFinished()
	{
		OnPlayerLaunchFinished.Broadcast();
	}
};