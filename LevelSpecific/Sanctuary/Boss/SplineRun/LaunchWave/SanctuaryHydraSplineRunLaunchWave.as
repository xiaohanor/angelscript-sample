event void FHydraLaunchWaveLaunchPlayerSignature(AHazePlayerCharacter Player);

class ASanctuaryHydraSplineRunLaunchWave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent WaveMeshComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY()
	FHydraLaunchWaveLaunchPlayerSignature OnPlayerLaunched;

	float IncreaseRadiusSpeed = 4.0;
	float XYScale;
	float ZScale;

	bool bWaveActive = false;

	TPerPlayer<bool> bPlayerLaunched;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		DevToggleHydraPrototype::SplineRunLaunchWave.MakeVisible();

		if (DevToggleHydraPrototype::SplineRunLaunchWave.IsEnabled())
			Timer::SetTimer(this, n"ActivateWave", 4.0);

		DevToggleHydraPrototype::SplineRunLaunchWave.BindOnChanged(this, n"HandleDevToggled");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bWaveActive)
			return;

		XYScale += IncreaseRadiusSpeed * DeltaSeconds;

		for (auto Player : Game::Players)
		{
			if (bPlayerLaunched[Player])
				continue;

			float PlayerDistanceToCenter = Player.GetHorizontalDistanceTo(this);

			if (Math::IsNearlyEqual(PlayerDistanceToCenter, XYScale * 440.0, 100.0))
				WaveLaunchPlayer(Player);
		}

		WaveMeshComp.SetWorldScale3D(FVector(XYScale, XYScale, ZScale));
	}

	UFUNCTION()
	private void ActivateWave()
	{
		bWaveActive = true;
		XYScale = 0.0;
		RemoveActorDisable(this);

		QueueComp.Duration(1.0, this, n"WaveHeightUpdate");
		QueueComp.Idle(5.0);
		QueueComp.ReverseDuration(1.0, this, n"WaveHeightUpdate");
		QueueComp.Event(this, n"ActivateWave");

		for (auto Player : Game::Players)
			bPlayerLaunched[Player] = false;
	} 

	UFUNCTION()
	private void DeactivateWave()
	{
		QueueComp.Empty();

		bWaveActive = false;
		AddActorDisable(this);
	}

	UFUNCTION()
	private void WaveHeightUpdate(float Alpha)
	{
		ZScale = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha) * 10.0;
	}

	private void WaveLaunchPlayer(AHazePlayerCharacter Player)
	{
		if (bPlayerLaunched[Player])
			return;

		bPlayerLaunched[Player] = true;
		Player.BlockCapabilities(PlayerMovementTags::Perch, this);
		Player.AddPlayerLaunchMovementImpulse(FVector::UpVector * 4000.0);

		OnPlayerLaunched.Broadcast(Player);
	}

	UFUNCTION()
	private void HandleDevToggled(bool bNewState)
	{
		if (bNewState)
			ActivateWave();
		else
			DeactivateWave();
	}
};