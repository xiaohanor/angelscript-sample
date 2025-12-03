event void FSanctuaryBossSplineRunWaveSplash(FVector WaveLocation);

class ASanctuaryBossSplineRunWave : AHazeActor
{
	FSanctuaryBossSplineRunWaveSplash OnWaveSplash;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent WaveMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent WavePlayerCollider;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(Category = RadiusSettings, EditAnywhere)
	float MaxScale = 60.0;

	UPROPERTY(Category = RadiusSettings, EditAnywhere)
	float MinScale = 1.0;

	float Scale;

	UPROPERTY(Category = RadiusSettings, EditAnywhere)
	float MovementSpeed = 3.0;

	UPROPERTY(Category = RadiusSettings, EditAnywhere)
	float MinDangerScale = 40.0;

	UPROPERTY(Category = RadiusSettings, EditAnywhere)
	float MaxDangerScale = 42.0;

	UPROPERTY(Category = HeightSettings, EditAnywhere)
	float MaxHeightScale = 42.0;
	float HeightScale = 1.0;

	UPROPERTY(EditAnywhere)
	float AnticipationDuration = 3.0;

	bool bIsWaveActive = false;
	bool bSentWaveEvent = false;

	FHazeTimeLike WaveHeightTimeLike;
	default WaveHeightTimeLike.UseSmoothCurveZeroToOne();
	default WaveHeightTimeLike.Duration = 5.0;

	float OGRadius;
	TPerPlayer<float> TimeSinceOverlapWave;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaveHeightTimeLike.BindUpdate(this, n"WaveHeightTimeLikeUpdate");
		WaveHeightTimeLike.BindFinished(this, n"WaveHeightTimeLikeFinished");
		OGRadius = WavePlayerCollider.SphereRadius;
		WavePlayerCollider.OnComponentBeginOverlap.AddUFunction(this, n"StartOverlapPlayer");
		for (auto Player : Game::GetPlayers())
			TimeSinceOverlapWave[Player] = 10.0;
	}

	UFUNCTION()
	private void StartOverlapPlayer(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (Player.ActorLocation.Z < WavePlayerCollider.WorldLocation.Z)
		{
			Player.KillPlayer();
			OnWaveSplash.Broadcast(Player.ActorLocation);
		}

		TimeSinceOverlapWave[Player] = 0.0;
	}

	UFUNCTION()
	private void WaveHeightTimeLikeUpdate(float CurrentValue)
	{
		HeightScale = Math::Lerp(1.0, MaxHeightScale, CurrentValue);
	}

	UFUNCTION()
	private void WaveHeightTimeLikeFinished()
	{
		if (WaveHeightTimeLike.IsReversed())
		{
			bIsWaveActive = false;
			WaveMeshComp.SetHiddenInGame(true);
			SetActorTickEnabled(false);
			Scale = MinScale;
			WaveMeshComp.SetWorldScale3D(FVector(Scale, Scale, HeightScale));
		}
	}

	UFUNCTION()
	void StartWave()
	{
		Timer::SetTimer(this, n"ActivateWave", AnticipationDuration);
		bSentWaveEvent = false;
	}

	UFUNCTION()
	private void ActivateWave()
	{
		WaveHeightTimeLike.Play();
		Scale = MinScale;
		bIsWaveActive = true;
		WaveMeshComp.SetHiddenInGame(false);
		SetActorTickEnabled(true);
	} 

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsWaveActive)
		{
			Scale += MovementSpeed * DeltaSeconds;

			//Scale Visual Mesh
			WaveMeshComp.SetWorldScale3D(FVector(Scale, Scale, HeightScale));
			float ColliderRadius = OGRadius * Scale * 0.95;
			WavePlayerCollider.SetSphereRadius(ColliderRadius, true);

			// Debug::DrawDebugSphere(WavePlayerCollider.WorldLocation, WavePlayerCollider.SphereRadius, 12);
			// Debug::DrawDebugPlane(WavePlayerCollider.WorldLocation, FVector::UpVector, WavePlayerCollider.SphereRadius, WavePlayerCollider.SphereRadius);

			for (auto Player : Game::GetPlayers())
			{
				TimeSinceOverlapWave[Player] += DeltaSeconds;
				bool bShouldPlayRumble = TimeSinceOverlapWave[Player] < 1.0 && !Player.IsPlayerDead();
				if (bShouldPlayRumble)
				{
					float Closeness = 0.1;
					FHazeFrameForceFeedback ForceFeedback;
					ForceFeedback.LeftMotor = Closeness;
					ForceFeedback.RightMotor = Closeness;
					Player.SetFrameForceFeedback(ForceFeedback);
				}
			}

			//Disable wave when it reaches max radius
			if (Scale >= MaxScale)
			{
				WaveHeightTimeLike.Reverse();
			}
		}
	}
};