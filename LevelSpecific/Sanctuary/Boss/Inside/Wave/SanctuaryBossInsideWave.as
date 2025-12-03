class ASanctuaryBossInsideWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent WaveMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DebrisRoot;

	UPROPERTY(DefaultComponent, Attach = DebrisRoot)
	UStaticMeshComponent DebrisMesh;

	UPROPERTY()
	UNiagaraSystem VFXSystem;

	UPROPERTY(Category = RadiusSettings, EditAnywhere)
	float MaxScale = 60.0;

	UPROPERTY(Category = RadiusSettings, EditAnywhere)
	float MinScale = 0.1;

	float Scale;

	UPROPERTY(Category = RadiusSettings, EditAnywhere)
	float MovementSpeed = 3.0;

	UPROPERTY(Category = HeightSettings, EditAnywhere)
	float MaxHeightScale = 90.0;
	float HeightScale = 0.1;

	UPROPERTY()
	FHazeTimeLike DropDebrisTimeLike;
	default DropDebrisTimeLike.UseLinearCurveZeroToOne();
	default DropDebrisTimeLike.Duration = 2.5;

	bool bIsWaveActive = false;

	bool bIsActive = false;

	FHazeTimeLike WaveHeightTimeLike;
	default WaveHeightTimeLike.UseSmoothCurveZeroToOne();
	default WaveHeightTimeLike.Duration = 4.0;

	FVector DebrisSpin;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaveHeightTimeLike.BindUpdate(this, n"WaveHeightTimeLikeUpdate");
		WaveHeightTimeLike.BindFinished(this, n"WaveHeightTimeLikeFinished");
		DropDebrisTimeLike.BindUpdate(this, n"DropDebrisTimeLikeUpdate");
		DropDebrisTimeLike.BindFinished(this, n"DropDebrisTimeLikeFinished");
		WaveMeshComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");
	}

	UFUNCTION()
	void Activate()
	{
		if (!bIsActive)
		{
			bIsActive = true;
			Timer::SetTimer(this, n"DropDebris", Math::RandRange(0.0, 10.0));
		}
	}

	UFUNCTION()
	void Deactivate()
	{
		if (bIsActive)
		{
			bIsActive = false;
			Timer::ClearTimer(this, n"DropDebris");
		}
	}

	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
			Player.KillPlayer();
	}

	UFUNCTION()
	private void DropDebrisTimeLikeUpdate(float CurrentValue)
	{
		DebrisRoot.SetRelativeLocation(FVector::UpVector * Math::Lerp(5000.0, -500.0, CurrentValue));

		FVector CurrentRotation = Math::Lerp(FVector::ZeroVector, DebrisSpin, CurrentValue);
		DebrisRoot.SetRelativeRotation(FRotator(CurrentRotation.X, CurrentRotation.Y, CurrentRotation.Z));
	}

	UFUNCTION()
	private void DropDebrisTimeLikeFinished()
	{
		StartWave();
	}

	UFUNCTION()
	private void WaveHeightTimeLikeUpdate(float CurrentValue)
	{
		HeightScale = Math::Lerp(0.1, MaxHeightScale, CurrentValue);
	}

	UFUNCTION()
	private void WaveHeightTimeLikeFinished()
	{
		if (WaveHeightTimeLike.IsReversed())
		{
			bIsWaveActive = false;
			WaveMeshComp.SetHiddenInGame(true);

			if (bIsActive)
				Timer::SetTimer(this, n"DropDebris", Math::RandRange(2.0, 6.0));
		}
	}

	UFUNCTION()
	private void DropDebris()
	{
		if (!bIsWaveActive)
		{
			bIsWaveActive = true;
			DropDebrisTimeLike.PlayFromStart();
			DebrisSpin = Math::GetRandomPointInSphere() * 300.0;
		}
	}

	UFUNCTION()
	private void StartWave()
	{
		Scale = MinScale;
		Niagara::SpawnOneShotNiagaraSystemAttached(VFXSystem, Root);
		WaveMeshComp.SetHiddenInGame(false);
		WaveHeightTimeLike.Play();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsWaveActive)
		{
			Scale += MovementSpeed * DeltaSeconds;

			//Scale Visual Mesh
			WaveMeshComp.SetWorldScale3D(FVector(Scale, Scale, HeightScale));

			//Disable wave when it reaches max radius
			if (Scale >= MaxScale && !WaveHeightTimeLike.IsReversed())
			{
				WaveHeightTimeLike.Reverse();
			}
		}
	}
};