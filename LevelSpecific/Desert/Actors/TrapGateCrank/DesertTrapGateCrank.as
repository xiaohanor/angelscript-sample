event void FDesertTrapGateCrankStartedSignature();
event void FDesertTrapGateCrankCompletedSignature();

class ADesertTrapGateCrank : AHazeActor
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
	UStaticMeshComponent LeftHandleMesh;

	UPROPERTY(DefaultComponent, Attach = OffsetComp)
	UStaticMeshComponent RightHandleMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDesertCrankInteractionComponent MioInteractionComp;
	default MioInteractionComp.UsableByPlayers = EHazeSelectPlayer::Mio;
	default MioInteractionComp.InteractionCapability = n"DesertTrapGateCrankInteractionCapability";
	default MioInteractionComp.bShowForOtherPlayer = true;
	default MioInteractionComp.bIsRightSideCrank = false;
	default MioInteractionComp.RelativeLocation = FVector(-58, -118, 0);

	UPROPERTY(DefaultComponent, Attach = Root)
	UDesertCrankInteractionComponent ZoeInteractionComp;
	default ZoeInteractionComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default ZoeInteractionComp.InteractionCapability = n"DesertTrapGateCrankInteractionCapability";
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

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor Camera;

	UPROPERTY()
	FDesertTrapGateCrankStartedSignature OnStarted;

	UPROPERTY()
	FDesertTrapGateCrankCompletedSignature OnCompleted;

	private TArray<FDesertTrapGateRopeData> Ropes;
	private float StartTime;
	private bool Completed;

	TPerPlayer<bool> InteractingPlayers;
	TPerPlayer<bool> WaitingPlayers;

	const float DurationPerTurn = 1.3;

	TArray<float> StartCableLengths;

	FHazeAcceleratedFloat AccMioProgress;
	FHazeAcceleratedFloat AccZoeProgress;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!SetupOnStart)
			Setup();
	}

	UFUNCTION()
	void Start()
	{
		StartTime = Time::GameTimeSeconds;
		if (SetupOnStart)
			Setup();
		OnStarted.Broadcast();

		FButtonMashSettings ButtonMashSettings;
		ButtonMashSettings.bAllowPlayerCancel = false;
		ButtonMashSettings.Difficulty = EButtonMashDifficulty::Medium;
		ButtonMashSettings.Duration = TensionDuration;
		
		ButtonMash::StartDoubleButtonMash(ButtonMashSettings, ButtonMashSettings, n"DesertTrapGateCrank", FOnButtonMashCompleted(this, n"OnButtonMashCompleted"));

		for(AHazePlayerCharacter Player : Game::Players)
			Player.ActivateCamera(Camera, 2, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStart()
	{
		StartTime = Time::GameTimeSeconds;
		if (SetupOnStart)
			Setup();
		OnStarted.Broadcast();


	}

	UFUNCTION()
	private void OnButtonMashCompleted()
	{
		Completed = true;
		OnCompleted.Broadcast();
		// MioInteractionComp.Disable(this);
		// ZoeInteractionComp.Disable(this);
		// SetActorTickEnabled(false);

		for(AHazePlayerCharacter Player : Game::Players)
			Player.DeactivateCamera(Camera);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (StartTime == 0)
			return;

		// if (StartTime > 0 && Time::GetGameTimeSince(StartTime) > TensionDuration)
		// {
		// 	if (!Completed)
		// 	{

		// 	}
		// 	return;
		// }

		auto MioCrankComp = UDesertPlayerCrankComponent::Get(Game::Mio);
		auto ZoeCrankComp = UDesertPlayerCrankComponent::Get(Game::Zoe);
		float MioProgress = Game::Mio.GetButtonMashProgress(n"DesertTrapGateCrank");
		float ZoeProgress = Game::Zoe.GetButtonMashProgress(n"DesertTrapGateCrank");
		AccMioProgress.AccelerateTo(MioProgress, 0.2, DeltaSeconds);
		AccZoeProgress.AccelerateTo(ZoeProgress, 0.2, DeltaSeconds);
		float AvgProgress = (AccMioProgress.Value + AccZoeProgress.Value) * 0.5;

		MioCrankComp.CrankData.CrankProgress = AccMioProgress.Value;
		ZoeCrankComp.CrankData.CrankProgress = AccZoeProgress.Value;

		for (int i = 0; i < Ropes.Num(); i++)
		{
			Ropes[i].CableComp.CableLength = Math::Lerp(StartCableLengths[i], Ropes[i].TensionCableLength, AvgProgress);
		}

		FQuat RopeMeshRotation = FQuat(ActorRightVector, TWO_PI * AvgProgress);

		/** Note: Handles are now moved by attaching to the player during animation. */
		RopeMesh.SetWorldRotation(RopeMeshRotation * ActorQuat);
	}

	private void Setup()
	{
		for (AActor Rope : RopeActors)
		{
			FDesertTrapGateRopeData Data;
			Data.CableComp = UCableComponent::GetOrCreate(Rope);
			Data.TensionCableLength = Data.CableComp.CableLength + AddTensionCableLength;
			Data.CableComp.CableLength = Data.CableComp.CableLength + AddLooseCableLength;
			Data.AccCableLength.SnapTo(Data.CableComp.CableLength);
			Ropes.Add(Data);
			StartCableLengths.Add(Data.CableComp.CableLength);
		}
	}
};

struct FDesertTrapGateRopeData
{
	UCableComponent CableComp;
	FHazeAcceleratedFloat AccCableLength;
	float TensionCableLength;
}