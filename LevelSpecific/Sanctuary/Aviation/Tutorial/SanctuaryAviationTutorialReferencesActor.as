class ASanctuaryAviationTutorialReferencesActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor TutorialSplineCameraZoe = nullptr;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor TutorialSplineCameraMio = nullptr;

	UPROPERTY(EditInstanceOnly)
	float TutorialSplineCameraBlendInTime = 2.0;
	UPROPERTY(EditInstanceOnly)
	float TutorialSplineCameraBlendOutTime = 3.0;
	UPROPERTY(EditInstanceOnly)
	UHazeCameraSettingsDataAsset TutorialSplineCameraSettings;
};