const FStatID STAT_PinballPredictionManager_Predict(n"PinballPredictionManager_Predict");

/**
 * Handles ticking the prediction system.
 */
class UPinballPredictionManagerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	
	// Tick really late, so that we have correct data to respond to in the prediction from local hits and stuff
	// But it must tick before UPinballPredictionMoveCapability
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 90;

	APinballPredictionManager PredictionManager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PredictionManager = Cast<APinballPredictionManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HasControl())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PredictionManager.bIsPredicting = true;
		PredictionManager.Predict();
		PredictionManager.bIsPredicting = false;
	}
};