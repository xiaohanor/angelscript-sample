class ASanctuaryAviationTutorialSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditInstanceOnly)
	EHazeSelectPlayer SelectedPlayer = EHazeSelectPlayer::None;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};