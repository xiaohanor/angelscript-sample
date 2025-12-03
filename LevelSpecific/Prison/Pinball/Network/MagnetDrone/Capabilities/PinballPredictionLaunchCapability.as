/**
 * Active while we are locally predicting a launch.
 * Mainly serves to consume launches and reset when we are done predicting the launch and return to predicting actual data.
 */
class UPinballPredictionLaunchCapability : UPinballMagnetDronePredictionCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Pinball::Tags::PredictionLaunch);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 10; // Before PredictionSystem

	UPlayerMovementComponent MoveComp;
	UPinballBallComponent BallComp;
	UPinballMagnetDroneLaunchedComponent LaunchedComp;
	UPinballMagnetDroneMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		if(HasControl())
			return;

		Super::Setup();

		MoveComp = UPlayerMovementComponent::Get(Player);
		BallComp = UPinballBallComponent::Get(Player);
		LaunchedComp = UPinballMagnetDroneLaunchedComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UPinballMagnetDroneMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(!LaunchedComp.WasLaunchedThisFrame())
			return false;

		if(Player.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!LaunchedComp.WasLaunched())
			return true;

		FHazeSyncedActorPosition ActorPosition;
		float CrumbTime = 0;
		if(!PredictionComp.TryGetLatestAvailableActorPosition(ActorPosition, CrumbTime))
			return true;

		float HalfPing = Network::PingOneWaySeconds * Time::WorldTimeDilation;
		float ThresholdTime = CrumbTime - Pinball::Prediction::LaunchPredictionSlowdownTime - LaunchedComp.PredictedLaunchAheadTime;
		ThresholdTime -= HalfPing;

		if (LaunchedComp.LaunchedPredictedOtherSideTime < ThresholdTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LaunchedComp.bIsLaunched = true;
		LaunchedComp.LaunchedTime = Time::GameTimeSeconds;

		LaunchedComp.ConsumeLaunch();

#if !RELEASE
		TEMPORAL_LOG(PredictionComp).Page("Launch").Status("Launched!", FLinearColor::Yellow);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LaunchedComp.ResetLaunch();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(LaunchedComp.HasLaunchToConsume())
		{
			LaunchedComp.ConsumeLaunch();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
#if !RELEASE
		TEMPORAL_LOG(PredictionComp).Page("Launch").Value(f"Is Simulating Launch:", IsActive());
#endif
	}
};