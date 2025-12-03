class ARedSpaceCrushingSphere : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default ActorHiddenInGame = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SphereRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CollisionRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SpawnTimeLike;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShake;

	bool bCrushing = false;

	float StartScale;
	float TargetScale = 3000.0;

	float CurrentSize = 3000.0;
	bool bFullySpawned = false;

	bool bDespawning = false;

	bool bGameOverActive = false;

	FHazeAcceleratedFloat AccCrushSpeed;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter FurthestPlayer;

	UPROPERTY(BlueprintReadOnly)
	float FurthestPlayerDistanceFromSphere = 0.0;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve RadiusDecreaseSpeedCurve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnTimeLike.BindUpdate(this, n"UpdateSpawn");
		SpawnTimeLike.BindFinished(this, n"FinishSpawn");
	}

	UFUNCTION(DevFunction)
	void Spawn()
	{
		bCrushing = true;
		StartScale = SphereRoot.RelativeScale3D.X;
		TargetScale = 3000.0;
		SpawnTimeLike.PlayFromStart();
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayCameraShake(CamShake, this, 2.0);
	}

	UFUNCTION()
	private void UpdateSpawn(float CurValue)
	{
		float Scale = Math::Lerp(StartScale, 3000.0, CurValue);
		SphereRoot.SetRelativeScale3D(FVector(Scale));
	}

	UFUNCTION()
	private void FinishSpawn()
	{
		CurrentSize = TargetScale;
		bFullySpawned = true;
	}

	UFUNCTION()
	void StopCrushing()
	{
		bCrushing = false;
	}

	UFUNCTION()
	void Despawn()
	{
		bDespawning = true;
		TargetScale = CurrentSize;

		SpawnTimeLike.ReverseFromEnd();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.StopCameraShakeByInstigator(this, false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float PitchOffset = Math::Sin(Time::GameTimeSeconds * 25.0) * 0.5;
		float RollOffset = Math::Sin(Time::GameTimeSeconds * 40.0) * 0.25;
		SphereRoot.SetRelativeRotation(FRotator(PitchOffset, SphereRoot.RelativeRotation.Yaw, RollOffset));

		float RotRate = Math::GetMappedRangeValueClamped(FVector2D(3000.0, 0.0), FVector2D(60.0, 200.0), CurrentSize);
		SphereRoot.AddLocalRotation(FRotator(0.0, RotRate * DeltaTime, 0.0));

		FurthestPlayer = GetDistanceTo(Game::Mio) < GetDistanceTo(Game::Zoe) ? Game::Zoe : Game::Mio;
		float FurthestDist = GetDistanceTo(FurthestPlayer);

		float Radius = Math::GetMappedRangeValueClamped(FVector2D(StartScale, 0.0), FVector2D(StartScale, 0.0), CurrentSize * 2.2);
		FurthestPlayerDistanceFromSphere = Math::Clamp(Radius - FurthestDist, 0.0, BIG_NUMBER);

		if (bCrushing)
		{
			if (HasControl())
			{
				if (!bGameOverActive && FurthestDist >= Radius - 100.0)
				{
					NetTriggerGameOver();
				}
			}

			if (bFullySpawned && !bDespawning)
			{
				AccCrushSpeed.AccelerateTo(180.0, 3.0, DeltaTime);
				float SizeAlpha = 1.0 - (CurrentSize/TargetScale);
				float CrushSpeedMultiplier = Math::Lerp(1.0, 5.0, RadiusDecreaseSpeedCurve.GetFloatValue(SizeAlpha));
				float CrushSpeed = AccCrushSpeed.Value * CrushSpeedMultiplier;
				CurrentSize -= CrushSpeed * DeltaTime;
				CurrentSize = Math::Max(CurrentSize, 50.0);
				SphereRoot.SetRelativeScale3D(FVector(CurrentSize));
				CollisionRoot.SetRelativeScale3D(FVector(CurrentSize));
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetTriggerGameOver()
	{
		bCrushing = false;
		bGameOverActive = true;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.BlockCapabilities(n"Respawn", this);
			Player.KillPlayer();
		}

		PlayerHealth::TriggerGameOver();
	}
}