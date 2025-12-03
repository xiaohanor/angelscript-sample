UCLASS(Abstract)
class AJetskiTutorialActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent LeftTutorialLoc;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent RightTutorialLoc;

	UPROPERTY(EditAnywhere, Category = "Jetski Tutorial")
	EHazePlayer Player;

	UPROPERTY(EditDefaultsOnly, Category = "Jetski Tutorial")
	FText TutorialTextAccelerate;

	UPROPERTY(EditDefaultsOnly, Category = "Jetski Tutorial")
	FText TutorialTextDive;

	UFUNCTION()
	void ShowJetskiTutorial(bool bDiveTutorial)
	{
		//Activates the capability
		auto Comp = UJetskiDriverTutorialComponent::GetOrCreate(Game::GetPlayer(Player));
		if(Comp.TutorialActor == nullptr)
			Comp.TutorialActor = this;

		if(bDiveTutorial)
			Comp.bShouldShowDiveTutorial = true;
		else
			Comp.bShouldShowAccelerationTutorial = true;
	}
};