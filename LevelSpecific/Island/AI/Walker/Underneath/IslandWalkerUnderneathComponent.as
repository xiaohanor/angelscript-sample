class UIslandWalkerUnderneathComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	UHazeCameraSettingsDataAsset UnderneathCameraSettings;

	TArray<AHazePlayerCharacter> UnderneathPlayers;
}