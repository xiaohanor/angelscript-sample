class ASanctuaryBossSplineRunHydraProjectileTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	bool bWasLastTarget = false;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
};