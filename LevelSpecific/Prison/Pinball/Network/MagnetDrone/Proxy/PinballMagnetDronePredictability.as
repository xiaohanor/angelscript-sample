class UPinballMagnetDronePredictability : UPinballPredictability
{
	// Proxy
	APinballMagnetDroneProxy Proxy;

	// Magnet Drone
	AHazePlayerCharacter MagnetDrone;

	void Setup(APinballProxy InProxy) override
	{
		Super::Setup(InProxy);
		
		Proxy = Cast<APinballMagnetDroneProxy>(InProxy);
		MagnetDrone = Cast<AHazePlayerCharacter>(Proxy.RepresentedActor);
	}
};