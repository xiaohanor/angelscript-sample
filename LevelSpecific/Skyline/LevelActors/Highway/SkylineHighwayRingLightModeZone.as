class ASkylineHighwayRingLightModeZone : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxComp;
	default BoxComp.bGenerateOverlapEvents = false;
	default BoxComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere)
	ESkylineHighwayRingLightMode LightMode = ESkylineHighwayRingLightMode::NoShadows;

	UPROPERTY(EditAnywhere)
	EInstigatePriority Priority = EInstigatePriority::Normal;
};