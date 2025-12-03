event void FGrappleFishTensionerCompletedSignature();

class AGrappleFishRopeTensioner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent OffsetComp;
	
	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	UStaticMeshComponent MainMesh;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	UStaticMeshComponent RopeMesh;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	UStaticMeshComponent LeftHandle;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	UStaticMeshComponent RightHandle;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDesertCrankInteractionComponent MioInteractionComp;
	default MioInteractionComp.UsableByPlayers = EHazeSelectPlayer::Mio;
	default MioInteractionComp.InteractionCapability = n"GrappleFishRopeTensionerInteractionCapability";
	default MioInteractionComp.bShowForOtherPlayer = true;
	default MioInteractionComp.bIsRightSideCrank = false;
	default MioInteractionComp.RelativeLocation = FVector(-58, -118, 0);

	UPROPERTY(DefaultComponent, Attach = Root)
	UDesertCrankInteractionComponent ZoeInteractionComp;
	default ZoeInteractionComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default ZoeInteractionComp.InteractionCapability = n"GrappleFishRopeTensionerInteractionCapability";
	default ZoeInteractionComp.bShowForOtherPlayer = true;
	default ZoeInteractionComp.bIsRightSideCrank = true;
	default ZoeInteractionComp.RelativeLocation = FVector(-58, 118, 0);

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	UNetworkLockComponent CompletionLock;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> RopeActors;

	UPROPERTY(EditInstanceOnly)
	float AddLooseCableLength;

	UPROPERTY(EditInstanceOnly)
	float AddTensionCableLength;

	UPROPERTY(EditInstanceOnly)
	float TensionDuration;

	UPROPERTY(EditInstanceOnly)
	bool SetupOnStart;

	UPROPERTY()
	FGrappleFishTensionerCompletedSignature OnStarted;

	UPROPERTY()
	FGrappleFishTensionerCompletedSignature OnCompleted;

	private TArray<FDesertRopeTensionerRopeData> Ropes;
	private float StartTime;
	private bool Completed;

	TPerPlayer<bool> InteractingPlayers;
	TPerPlayer<bool> WaitingPlayers;

	TArray<float> StartCableLengths;

	const float DurationPerTurn = 1.3;
	int NumTurns = 3;

	float SuccessfulMashDuration = 0;
	float TotalDuration = DurationPerTurn * NumTurns;

	float DurationThresholdForSuccess = 0.5;
	float DurationThresholdForFail = 0.5;


	float CrankProgress = 0;

	FHazeAcceleratedFloat AccDecaySpeed;
	FHazeAcceleratedFloat AccWindupSpeed;

	float TimeWhenLastSuccess;
	float TimeWhenLastFail;

	float GetProgressionAlpha()
	{
		return SuccessfulMashDuration / TotalDuration;
	}

	UFUNCTION()
	void Start()
	{
		StartTime = Time::GameTimeSeconds;
		OnStarted.Broadcast();

		FButtonMashSettings ButtonMashSettings;
		ButtonMashSettings.bAllowPlayerCancel = false;
		ButtonMashSettings.Difficulty = EButtonMashDifficulty::Hard;
		ButtonMashSettings.ProgressionMode = EButtonMashProgressionMode::MashRateOnly;
		Game::Mio.StartButtonMash(ButtonMashSettings, n"GrappleFishRopeTensioner", FOnButtonMashCompleted());
		Game::Zoe.StartButtonMash(ButtonMashSettings, n"GrappleFishRopeTensioner", FOnButtonMashCompleted());
	}

	UFUNCTION()
	void Instant()
	{
		if(HasControl())
			CrumbInstant();
	}

	UFUNCTION(CrumbFunction)
	void CrumbInstant()
	{
		OnStarted.Broadcast();
		Complete();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (StartTime == 0)
			return;

		auto MioCrankComp = UDesertPlayerCrankComponent::Get(Game::Mio);
		auto ZoeCrankComp = UDesertPlayerCrankComponent::Get(Game::Zoe);
		float MioMashRate, ZoeMashRate;
		bool bMioMashRateSufficient, bZoeMashRateSufficient;
		Game::Mio.GetButtonMashCurrentRate(n"GrappleFishRopeTensioner", MioMashRate, bMioMashRateSufficient);
		Game::Zoe.GetButtonMashCurrentRate(n"GrappleFishRopeTensioner", ZoeMashRate, bZoeMashRateSufficient);

		if (bMioMashRateSufficient && bZoeMashRateSufficient)
		{
			TimeWhenLastSuccess = Time::GameTimeSeconds;
			if (Time::GetGameTimeSince(TimeWhenLastFail) >= DurationThresholdForSuccess)
			{
				AccWindupSpeed.AccelerateTo(1.0, 0.5, DeltaSeconds);
			}
			else
			{
				AccWindupSpeed.AccelerateTo(0.2, 1.5, DeltaSeconds);
			}

			AccDecaySpeed.AccelerateTo(0, 1.0, DeltaSeconds);
			SuccessfulMashDuration += AccWindupSpeed.Value * DeltaSeconds;
		}
		else
		{
			TimeWhenLastFail = Time::GameTimeSeconds;
			if (Time::GetGameTimeSince(TimeWhenLastSuccess) >= DurationThresholdForFail)
			{
				if (AccDecaySpeed.Value < 0.5)
					AccDecaySpeed.AccelerateTo(1.0, 2, DeltaSeconds);
				else
					AccDecaySpeed.AccelerateTo(2, 1, DeltaSeconds);
			}
			else
			{
				AccDecaySpeed.AccelerateTo(0.2, 2, DeltaSeconds);
			}

			AccWindupSpeed.AccelerateTo(0, 1, DeltaSeconds);
			SuccessfulMashDuration -= AccDecaySpeed.Value * DeltaSeconds;
		}

		SuccessfulMashDuration = Math::Clamp(SuccessfulMashDuration, 0, TotalDuration);

		CrankProgress = (SuccessfulMashDuration % DurationPerTurn) / DurationPerTurn;

		MioCrankComp.CrankData.CrankProgress = CrankProgress;
		ZoeCrankComp.CrankData.CrankProgress = CrankProgress;

		FQuat NewRotation = FQuat(ActorRightVector, TWO_PI * CrankProgress);

		RopeMesh.SetWorldRotation(NewRotation * ActorQuat);

		if (SuccessfulMashDuration >= TotalDuration && HasControl())
		{
			CrumbComplete();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbComplete()
	{
		Complete();
	}

	private void Complete()
	{
		Completed = true;
		OnCompleted.Broadcast();
		MioInteractionComp.Disable(this);
		ZoeInteractionComp.Disable(this);
		SetActorTickEnabled(false);
		Game::Mio.StopButtonMash(n"GrappleFishRopeTensioner");
		Game::Zoe.StopButtonMash(n"GrappleFishRopeTensioner");
	}
}