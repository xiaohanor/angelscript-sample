class ASanctuaryWeeperArtifactSocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Both;

	UPROPERTY()
	TSubclassOf<ASanctuaryWeeperArtifact> ArtifactClass;
};