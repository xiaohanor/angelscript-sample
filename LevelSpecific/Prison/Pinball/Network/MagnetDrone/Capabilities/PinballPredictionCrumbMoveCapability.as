/**
 * Move Zoe using the crumb trail
 * Smooth, but with long delay. Used in the intro.
 */
class UPinballPredictionCrumbMoveCapability : UPinballMagnetDronePredictionCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::Movement;	// Tick before UPinballPredictionMoveCapability
	default TickGroupOrder = 100;

	APinballPredictionManager PredictionManager;
	UPinballBallComponent BallComp;
	UPlayerMovementComponent MoveComp;
	UPinballMagnetDroneMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		if(HasControl())
			return;

		Super::Setup();

		PredictionManager = Pinball::Prediction::GetManager();

		BallComp = UPinballBallComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UPinballMagnetDroneMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(!PredictionManager.bUseCrumbSyncedMovement.Get())
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!PredictionManager.bUseCrumbSyncedMovement.Get())
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		check(!HasControl());

		if(!MoveComp.PrepareMove(MoveData))
			return;

		MoveData.ApplyCrumbSyncedAirMovement();

		MoveComp.ApplyMove(MoveData);
	}
};