event void FSanctuaryBossArenaWaveSplash(FVector WaveLocation);

class ASanctuaryBossArenaWave : AHazeActor
{
	FSanctuaryBossArenaWaveSplash OnWaveSplash;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent WaveMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DecalRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	USanctuaryCompanionAviationPlayerComponent ZoeAviationComp;
	USanctuaryCompanionAviationPlayerComponent MioAviationComp;

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

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaveHeightTimeLike.BindUpdate(this, n"WaveHeightTimeLikeUpdate");
		WaveHeightTimeLike.BindFinished(this, n"WaveHeightTimeLikeFinished");
		DecalRoot.SetHiddenInGame(true, true);
	}

	UFUNCTION()
	private void WaveHeightTimeLikeUpdate(float CurrentValue)
	{
		HeightScale = Math::Lerp(1.0, MaxHeightScale, CurrentValue);

		float Height = Math::Lerp(-MaxHeightScale * 50.0, 0.0, CurrentValue);
		DecalRoot.SetRelativeLocation(FVector::UpVector * Height);
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
			WaveHeightTimeLike.SetPlayRate(1.0);
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
		DecalRoot.SetHiddenInGame(false, true);
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

			if (Scale >= MinDangerScale && Scale <= MaxDangerScale)
			{
				if (!bSentWaveEvent)
				{
					// Debug::DrawDebugSphere(Game::Mio.ActorLocation, 3000.0, 12, ColorDebug::White, 3.0, 5.0);
					bSentWaveEvent = true;
					OnWaveSplash.Broadcast(ActorLocation);
					DecalRoot.SetHiddenInGame(true, true);
				}
					
				for (auto Player : Game::GetPlayers())
				{
					if (ShouldPlayRumble(Player))
					{
						float Closeness = Math::EaseIn(1.0, 0.0, Math::Clamp((Player.ActorLocation.Z - ActorLocation.Z) / 1000.0, 0.0, 1.0), 2.0);
						FHazeFrameForceFeedback ForceFeedback;
						ForceFeedback.LeftMotor = Closeness;
						ForceFeedback.RightMotor = Closeness;
						Player.SetFrameForceFeedback(ForceFeedback);
					}

					//Kill player if in danger zone (with some leeway)
					if (Player.ActorLocation.Z < ActorLocation.Z - 50.0)
						Player.KillPlayer();
				}
			}

			//Disable wave when it reaches max radius
			if (Scale >= MaxScale)
			{
				WaveHeightTimeLike.SetPlayRate(2.0);
				WaveHeightTimeLike.Reverse();
				
			}
		}
	//float Scaly = (Game::Mio.ActorLocation - ActorLocation).X;
	//Debug::DrawDebugPlane(ActorLocation, FVector::UpVector, Scaly, Scaly, ColorDebug::Magenta, 0, 1, 50, true);

	}

	bool ShouldPlayRumble(AHazePlayerCharacter Player)
	{
		if (Player.IsPlayerDead())
			return false;
		if (Player.IsZoe())
		{
			if (ZoeAviationComp == nullptr)
				ZoeAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
			if (ZoeAviationComp != nullptr && ZoeAviationComp.GetIsAviationActive())
				return false;
		}
		if (Player.IsMio())
		{
			if (MioAviationComp == nullptr)
				MioAviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
			if (MioAviationComp != nullptr && MioAviationComp.GetIsAviationActive())
				return false;
		}
		return true;
	}
};