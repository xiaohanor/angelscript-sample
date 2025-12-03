class ASanctuaryCompanionAviationLandingPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent bILLBOARDCOMP;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
	
	UPROPERTY(EditAnywhere)
	EHazeSelectPlayer Player;

	UPROPERTY(EditAnywhere)
	ESanctuaryArenaSide Side;
};