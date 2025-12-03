class AAdultDragonAcidTutorialVolume : ATutorialVolume
{
	default bTriggerForZoe = false;
	default VolumeType = ETutorialVolumeType::UseTutorialCapability;

	// UPROPERTY(EditAnywhere)
	// AStormChaseMetalShieldObstacle Metal;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
}