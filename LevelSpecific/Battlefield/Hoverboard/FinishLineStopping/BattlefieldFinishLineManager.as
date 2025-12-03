event void UBattlefieldFinishLineManagerEvent();

class ABattlefieldFinishLineManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY()
	UBattlefieldFinishLineManagerEvent OnMioFinished;

	UPROPERTY()
	UBattlefieldFinishLineManagerEvent OnZoeFinished;

	UPROPERTY()
	UBattlefieldFinishLineManagerEvent OnBothFinished;
};