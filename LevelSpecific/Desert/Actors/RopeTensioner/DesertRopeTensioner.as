event void FDesertRopeTensionerCompletedSignature();

class ADesertRopeTensioner : AHazeActor
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
	default MioInteractionComp.InteractionCapability = n"DesertRopeTensionerInteractionCapability";
	default MioInteractionComp.bShowForOtherPlayer = true;
	default MioInteractionComp.bIsRightSideCrank = false;
	default MioInteractionComp.RelativeLocation = FVector(-58, -118, 0);

	UPROPERTY(DefaultComponent, Attach = Root)
	UDesertCrankInteractionComponent ZoeInteractionComp;
	default ZoeInteractionComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default ZoeInteractionComp.InteractionCapability = n"DesertRopeTensionerInteractionCapability";
	default ZoeInteractionComp.bShowForOtherPlayer = true;
	default ZoeInteractionComp.bIsRightSideCrank = true;
	default ZoeInteractionComp.RelativeLocation = FVector(-58, 118, 0);

	default TickGroup = ETickingGroup::TG_PrePhysics;

	UPROPERTY(DefaultComponent)
	UNetworkLockComponent CompletionLock;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> RopeActors;

	UPROPERTY(EditInstanceOnly)
	float AddLooseCableLength;

	UPROPERTY(EditInstanceOnly)
	float AddTensionCableLength;

	UPROPERTY(EditInstanceOnly)
	float TensionDuration = 3;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence WaitingAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ActiveAnim;

	UPROPERTY()
	FDesertRopeTensionerCompletedSignature OnStarted;

	UPROPERTY()
	FDesertRopeTensionerCompletedSignature OnCompleted;

	private TArray<FDesertRopeTensionerRopeData> Ropes;
	private float StartTime;
	private bool Completed;

	TPerPlayer<bool> InteractingPlayers;
	TPerPlayer<bool> WaitingPlayers;

	TArray<float> StartCableLengths;

	int NumTurns = 3;
	float TotalDuration = TensionDuration;
	float DurationPerTurn = TotalDuration / float(NumTurns);

	float SuccessfulMashDuration = 0;
	float CrankProgress = 0;

	FHazeAcceleratedFloat AccDecaySpeed;
	FHazeAcceleratedFloat AccWindupSpeed;

	float DurationThresholdForSuccess = 0.5;
	float DurationThresholdForFail = 0.5;

	float TimeWhenLastFail;
	float TimeWhenLastSuccess;

	bool bHasStarted = false;

	bool bIsWindingUp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Setup();
	}

	UFUNCTION()
	void Start()
	{
		if (bHasStarted)
			return;

		bHasStarted = true;
		StartTime = Time::GameTimeSeconds;
		OnStarted.Broadcast();

		FButtonMashSettings ButtonMashSettings;
		ButtonMashSettings.bAllowPlayerCancel = false;
		ButtonMashSettings.Difficulty = EButtonMashDifficulty::Hard;
		ButtonMashSettings.ProgressionMode = EButtonMashProgressionMode::MashRateOnly;
		Game::Mio.StartButtonMash(ButtonMashSettings, n"DesertRopeTensioner", FOnButtonMashCompleted());
		Game::Zoe.StartButtonMash(ButtonMashSettings, n"DesertRopeTensioner", FOnButtonMashCompleted());
	}

	UFUNCTION(CrumbFunction)
	void CrumbStart()
	{
		StartTime = Time::GameTimeSeconds;
		OnStarted.Broadcast();
	}

	UFUNCTION()
	void Instant()
	{
		if (HasControl())
			CrumbInstant();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbInstant()
	{
		for (int i = 0; i < Ropes.Num(); i++)
			Ropes[i].CableComp.CableLength = Ropes[i].TensionCableLength;

		Completed = true;
		MioInteractionComp.Disable(this);
		ZoeInteractionComp.Disable(this);
		SetActorTickEnabled(false);
	}

	UFUNCTION(CrumbFunction)
	void CrumbComplete()
	{
		Complete();
	}

	private void Complete()
	{
		UDesertRopeTensionerEventHandler::Trigger_OnFullyWound(this);
		UDesertRopeTensionerPlayerEventHandler::Trigger_OnFullyWound(Game::Mio);
		UDesertRopeTensionerPlayerEventHandler::Trigger_OnFullyWound(Game::Zoe);
		Completed = true;
		OnCompleted.Broadcast();
		MioInteractionComp.Disable(this);
		ZoeInteractionComp.Disable(this);
		SetActorTickEnabled(false);
		Game::Mio.StopButtonMash(n"DesertRopeTensioner");
		Game::Zoe.StopButtonMash(n"DesertRopeTensioner");
	}

	float GetProgressionAlpha()
	{
		return SuccessfulMashDuration / TotalDuration;
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
		Game::Mio.GetButtonMashCurrentRate(n"DesertRopeTensioner", MioMashRate, bMioMashRateSufficient);
		Game::Zoe.GetButtonMashCurrentRate(n"DesertRopeTensioner", ZoeMashRate, bZoeMashRateSufficient);

		float PreviousSuccessfulMashDuration = SuccessfulMashDuration;
		if (bMioMashRateSufficient && bZoeMashRateSufficient)
		{
			TimeWhenLastSuccess = Time::GameTimeSeconds;
			if (!bIsWindingUp)
			{
				bIsWindingUp = true;
				UDesertRopeTensionerEventHandler::Trigger_OnStartWinding(this);
				UDesertRopeTensionerPlayerEventHandler::Trigger_OnStartWinding(Game::Mio);
				UDesertRopeTensionerPlayerEventHandler::Trigger_OnStartWinding(Game::Zoe);
			}

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

			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * 10.0) * 0.5;
				FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * 10.0) * 0.5;
				Player.SetFrameForceFeedback(FF);
			}
		}
		else
		{
			if (bIsWindingUp)
			{
				bIsWindingUp = false;
				UDesertRopeTensionerEventHandler::Trigger_OnStartUnwinding(this);
				UDesertRopeTensionerPlayerEventHandler::Trigger_OnStartUnwinding(Game::Mio);
				UDesertRopeTensionerPlayerEventHandler::Trigger_OnStartUnwinding(Game::Zoe);
			}
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
		if (Math::IsNearlyZero(SuccessfulMashDuration) && !Math::IsNearlyZero(PreviousSuccessfulMashDuration))
		{
			UDesertRopeTensionerEventHandler::Trigger_OnFullyUnwound(this);
			UDesertRopeTensionerPlayerEventHandler::Trigger_OnFullyUnwound(Game::Mio);
			UDesertRopeTensionerPlayerEventHandler::Trigger_OnFullyUnwound(Game::Zoe);
		}

		CrankProgress = (SuccessfulMashDuration % DurationPerTurn) / DurationPerTurn;

		MioCrankComp.CrankData.CrankProgress = CrankProgress;
		ZoeCrankComp.CrankData.CrankProgress = CrankProgress;

		FQuat NewRotation = FQuat(ActorRightVector, TWO_PI * CrankProgress);

		// LeftHandle.SetWorldRotation(NewRotation * ActorQuat);
		// RightHandle.SetWorldRotation(NewRotation * ActorQuat);
		RopeMesh.SetWorldRotation(NewRotation * ActorQuat);
		
		if (SuccessfulMashDuration >= TotalDuration && HasControl())
		{
			CrumbComplete();
		}

		for (int i = 0; i < Ropes.Num(); i++)
		{
			Ropes[i].CableComp.CableLength = Math::Lerp(StartCableLengths[i], Ropes[i].TensionCableLength, GetProgressionAlpha());
		}

		FQuat RopeMeshRotation = FQuat(ActorRightVector, TWO_PI * GetProgressionAlpha());

		/** Note: Handles are now moved by attaching to the player during animation. */
		RopeMesh.SetWorldRotation(RopeMeshRotation * ActorQuat);
	}

	private void Setup()
	{
		for (AActor Rope : RopeActors)
		{
			FDesertRopeTensionerRopeData Data;
			Data.CableComp = UCableComponent::GetOrCreate(Rope);
			Data.TensionCableLength = Data.CableComp.CableLength + AddTensionCableLength;
			Data.CableComp.CableLength = Data.CableComp.CableLength + AddLooseCableLength;
			Data.AccCableLength.SnapTo(Data.CableComp.CableLength);
			Ropes.Add(Data);
			StartCableLengths.Add(Data.CableComp.CableLength);
		}
	}
}

struct FDesertRopeTensionerRopeData
{
	UCableComponent CableComp;
	FHazeAcceleratedFloat AccCableLength;
	float TensionCableLength;
}