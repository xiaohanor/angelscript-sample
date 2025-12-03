event void FOnSkylineJammedBikeTutorialActivateEnemy();

UCLASS(Abstract)
class USkylineJammedBikeComponent : UActorComponent
{
	UPROPERTY()
	FTimeDilationEffect TimeDilationEffect;

	UPROPERTY()
	FTutorialPrompt TutorialPrompt;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> TutorialPromptWidget;

	UPROPERTY(BlueprintReadWrite, NotEditable)
	AHazeCameraActor CameraActor;

	UPROPERTY(BlueprintReadWrite, NotEditable)
	AGravityBikeSplineActor SplineActor;

	UPROPERTY(BlueprintReadWrite, NotEditable)
	ASkylineGravityBikeTutorialPodium PodiumActor;
	
	UPROPERTY()
	FOnSkylineJammedBikeTutorialActivateEnemy OnSkylineJammedBikeTutorialActivateEnemy;

	bool bHasFinishedAccelerateTutorial = false;

	bool bHasFinishedDrivingTutorial = false;
};

UFUNCTION(BlueprintPure)
USkylineJammedBikeComponent GetSkylineJammedBikeComponent()
{
	return USkylineJammedBikeComponent::Get(Game::Mio);
}