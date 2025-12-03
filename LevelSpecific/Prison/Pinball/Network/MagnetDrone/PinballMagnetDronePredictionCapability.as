/**
 * Base class for Prediction capabilities.
 * Will only run on the Paddle side.
 * The point of the prediction capabilities is to have some state between frames, since the predictabilities will be reset every frame to the control state.
 */
UCLASS(Abstract)
class UPinballMagnetDronePredictionCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	UPinballMagnetDronePredictionComponent PredictionComp;
	APinballMagnetDroneProxy Proxy;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		check(!HasControl(), "Return before calling super if not networked!");
		check(Pinball::GetPaddlePlayer().HasControl(), "Always run on the paddle side.");

		PredictionComp = UPinballMagnetDronePredictionComponent::Get(Player);
		Proxy = PredictionComp.Proxy;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HasControl())
			return false;

		return true;
	}
};