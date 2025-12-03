class AWaveRaftSettingsVolume : AActorTrigger
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	UWaveRaftSettings SettingsToApply;

	default ActorClasses.Add(AWaveRaft);

	UPROPERTY(EditAnywhere)
	bool bClearSettingsOnExit = true;

	UPROPERTY(EditAnywhere)
	ASplineActor OverrideSpline;

	UPROPERTY(EditAnywhere)
	FName SettingsInstigator;

	UPROPERTY(EditAnywhere)
	EHazeSettingsPriority InstigatePriority = EHazeSettingsPriority::Gameplay;

	UPROPERTY(EditAnywhere)
	bool bIsSmallJump;

	UPROPERTY(EditAnywhere)
	bool bIsBigJump;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"OnActorEntered");
		if (bClearSettingsOnExit)
			OnActorLeave.AddUFunction(this, n"OnActorLeave");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActorEntered(AHazeActor Actor)
	{
		auto WaveRaft = Cast<AWaveRaft>(Actor);
		if (WaveRaft == nullptr)
			return;

		if (bIsBigJump)
			WaveRaft.CrumbQueueLandingFFAndCamShake(true);
		else if (bIsSmallJump)
			WaveRaft.CrumbQueueLandingFFAndCamShake(false);

		FInstigator Instigator = SettingsInstigator;
		if (Instigator == NAME_None)
			Instigator = this;

		if (SettingsToApply != nullptr)
			WaveRaft.ApplyWaveRaftSettings(SettingsToApply, Instigator, InstigatePriority);

		if (OverrideSpline != nullptr)
			WaveRaft.InstigatedWaterSplineActor.Apply(OverrideSpline, Instigator, EInstigatePriority::High);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActorLeave(AHazeActor Actor)
	{
		auto WaveRaft = Cast<AWaveRaft>(Actor);
		if (WaveRaft == nullptr)
			return;

		FInstigator Instigator = SettingsInstigator;
		if (Instigator == NAME_None)
			Instigator = this;

		WaveRaft.ClearWaveRaftSettingsByInstigator(Instigator);
		WaveRaft.InstigatedWaterSplineActor.Clear(Instigator);
	}
}