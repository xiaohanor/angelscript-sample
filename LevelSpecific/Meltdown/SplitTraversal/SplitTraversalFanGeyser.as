struct FSplitTraversalFanGeyserLaunchEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
};

UCLASS(Abstract)
class USplitTraversalFanGeyserEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGeyserActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGeyserDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStartLaunching(FSplitTraversalFanGeyserLaunchEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStopLaunching(FSplitTraversalFanGeyserLaunchEventData EventData) {}
};

struct FSplitTraversalFanGeyserPlayerData
{
	bool bIsInside = false;
	bool bIsLaunching = false;
	float OverlappedAtGameTime = -1;
};

class ASplitTraversalFanGeyser : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UHazeCapsuleCollisionComponent CapsuleCompScifi;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UNiagaraComponent ActiveVFXScifi;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent FanRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UHazeCapsuleCollisionComponent CapsuleCompFantasy;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UNiagaraComponent ActiveVFXFantasy;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UNiagaraComponent ActiveVFXFantasy2;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(EditAnywhere)
	float TargetHeight = 300.0;

	UPROPERTY(EditAnywhere)
	FVector ExitVelocity = FVector(0.0, 0.0, 300.0);

	UPROPERTY(EditAnywhere)
	float TeleportDuration = 2.0;

	UPROPERTY(EditAnywhere)
	float Cooldown = 2.5;

	UPROPERTY(EditAnywhere)
	float ActivatedDuration = 2.0;

	UPROPERTY(EditAnywhere)
	float DeactivatedDuration = 4.0;

	UPROPERTY(EditAnywhere)
	bool bStartActive = false;

	TPerPlayer<FSplitTraversalFanGeyserPlayerData> PlayerDatas;

	FHazeAcceleratedFloat AcceleratedFanSpeed;
	float TargetFanSpeed = 0.0;
	float AccelerateFanSpeedDuration = 1.0;

	bool bActive = false;
	float CrumbTimeOffset;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(CapsuleCompScifi.WorldLocation + ActorUpVector * TargetHeight, 200, LineColor = FLinearColor::Green);
		Debug::DrawDebugSphere(CapsuleCompFantasy.WorldLocation + ActorUpVector * TargetHeight, 200, LineColor = FLinearColor::Green);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		CapsuleCompScifi.OnComponentBeginOverlap.AddUFunction(this, n"HandleCapsuleBeginOverlap");
		CapsuleCompScifi.OnComponentEndOverlap.AddUFunction(this, n"HandleCapsuleEndOverlap");

		CapsuleCompFantasy.OnComponentBeginOverlap.AddUFunction(this, n"HandleCapsuleBeginOverlap");
		CapsuleCompFantasy.OnComponentEndOverlap.AddUFunction(this, n"HandleCapsuleEndOverlap");

		if (bStartActive)
			Activate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedFanSpeed.AccelerateTo(TargetFanSpeed, AccelerateFanSpeedDuration, DeltaTime = DeltaSeconds);
		FanRoot.AddRelativeRotation(FRotator(0.0, AcceleratedFanSpeed.Value * DeltaSeconds, 0.0));
		ActionQueue.ScrubTo(Time::PredictedGlobalCrumbTrailTime - CrumbTimeOffset);
	}

	UFUNCTION()
	void Activate()
	{
		if (HasControl())
			NetActivate(Time::PredictedGlobalCrumbTrailTime);
	}

	UFUNCTION(NetFunction)
	void NetActivate(float TimeOffset)
	{
		CrumbTimeOffset = TimeOffset;
		ActionQueue.SetLooping(true);
		ActionQueue.Event(this, n"StartLaunch");
		ActionQueue.Idle(ActivatedDuration);
		ActionQueue.Event(this, n"StopLaunch");
		ActionQueue.Idle(DeactivatedDuration);
		ActionQueue.ScrubTo(Time::PredictedGlobalCrumbTrailTime - CrumbTimeOffset);
	}

	UFUNCTION()
	void StartLaunch()
	{
		bActive = true;

		LaunchOverlappingPlayers();

		ActiveVFXScifi.Activate(true);
		ActiveVFXFantasy.Activate(true);
		ActiveVFXFantasy2.Activate(true);

		TargetFanSpeed = 1500.0;
		AccelerateFanSpeedDuration = 0.5;

		USplitTraversalFanGeyserEventHandler::Trigger_OnGeyserActivated(this);
	}

	private void LaunchOverlappingPlayers()
	{
		if(PlayerDatas[Game::Mio].bIsInside)
			LaunchPlayer(Game::Mio, CapsuleCompScifi);

		if(PlayerDatas[Game::Zoe].bIsInside)
			LaunchPlayer(Game::Zoe, CapsuleCompFantasy);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_StartLaunch(AHazePlayerCharacter Player){}

	UFUNCTION()
	void StopLaunch()
	{
		bActive = false;

		ActiveVFXScifi.Deactivate();
		ActiveVFXFantasy.Deactivate();
		ActiveVFXFantasy2.Deactivate();

		TargetFanSpeed = 50.0;
		AccelerateFanSpeedDuration = 3.0;

		for(auto Player : Game::Players)
		{
			if(PlayerDatas[Player].bIsLaunching)
				StopLaunchingPlayer(Player);
		}

		USplitTraversalFanGeyserEventHandler::Trigger_OnGeyserDeactivated(this);
	}

	UFUNCTION()
	private void HandleCapsuleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                       UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                       bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		OnPlayerEnter(Player, OverlappedComponent);
	}

	UFUNCTION()
    private void HandleCapsuleEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
                           UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		OnPlayerExit(Player);
	}

	private void OnPlayerEnter(AHazePlayerCharacter Player, UPrimitiveComponent OverlappedComponent)
	{
		if(PlayerDatas[Player].bIsInside)
			return;

		PlayerDatas[Player].bIsInside = true;

		// Launch player if we are active
		if(bActive)
			LaunchPlayer(Player, OverlappedComponent);
	}

	private void OnPlayerExit(AHazePlayerCharacter Player)
	{
		if(!PlayerDatas[Player].bIsInside)
			return;

		// Stop launching the player
		if(PlayerDatas[Player].bIsLaunching)
			StopLaunchingPlayer(Player);

		PlayerDatas[Player].bIsInside = false;
	}

	private void LaunchPlayer(AHazePlayerCharacter Player, UPrimitiveComponent OverlappedComponent)
	{
		check(PlayerDatas[Player].bIsInside);

		if (Time::GameTimeSeconds < PlayerDatas[Player].OverlappedAtGameTime + Cooldown)
			return;

		FVector BaseTargetLocation = OverlappedComponent.GetAttachParent().WorldLocation;
		FVector TargetLocation = BaseTargetLocation + ActorUpVector * TargetHeight;

		PlayerDatas[Player].OverlappedAtGameTime = Time::GameTimeSeconds;

		FPlayerLaunchToParameters Params;
		Params.LaunchToLocation = TargetLocation;
		Params.Duration = TeleportDuration;
		Params.Type = EPlayerLaunchToType::LerpToPointWithCurve;
		Params.LaunchCurve = SplitTraversalFanGeyserCurve;
		Params.ExitVelocity = FVector::UpVector * 2500.0;
		Params.NetworkMode = EPlayerLaunchToNetworkMode::SimulateLocal;

		Player.LaunchPlayerTo(this, Params);
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		if(!PlayerDatas[Player].bIsLaunching)
		{
			PlayerDatas[Player].bIsLaunching = true;

			FSplitTraversalFanGeyserLaunchEventData EventData;
			EventData.Player = Player;
			USplitTraversalFanGeyserEventHandler::Trigger_OnPlayerStartLaunching(this, EventData);
		}

		BP_StartLaunch(Player);
	}

	private void StopLaunchingPlayer(AHazePlayerCharacter Player)
	{
		check(PlayerDatas[Player].bIsInside);

		if(!ensure(PlayerDatas[Player].bIsLaunching))
			return;

		FSplitTraversalFanGeyserLaunchEventData EventData;
		EventData.Player = Player;
		USplitTraversalFanGeyserEventHandler::Trigger_OnPlayerStopLaunching(this, EventData);

		PlayerDatas[Player].bIsLaunching = false;
	}
};

asset SplitTraversalFanGeyserCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |                                                             .''|
	    |                                                          .·'   |
	    |                                                       .·'      |
	    |                                                    .·'         |
	    |                                                 .·'            |
	    |                                              .·'               |
	    |                                           .·'                  |
	    |                                        .·'                     |
	    |                                     .·'                        |
	    |                                  .·'                           |
	    |                               .·'                              |
	    |                            .·'                                 |
	    |                        ..·'                                    |
	    |                    ..·'                                        |
	    |               ..··'                                            |
	-0.0|.........···'''                                                 |
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddCurveKeyTangent(0.0, 0.0, -0.013862);
	AddCurveKeyWeightedBothTangent(1.0, 1.0, false, 1.313381, 1.313381, 0.84434, 0.84434);
}