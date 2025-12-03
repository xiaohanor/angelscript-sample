class AAdultDragonSmashTutorialVolume : ATutorialVolume
{
	default bTriggerForMio = false;
	default VolumeType = ETutorialVolumeType::UseTutorialCapability;

	UPROPERTY(EditAnywhere)
	AVineGemSpike Gem;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
}