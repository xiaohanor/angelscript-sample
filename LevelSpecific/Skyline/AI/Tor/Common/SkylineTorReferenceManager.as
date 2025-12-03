class ASkylineTorReferenceManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(5.0);
#endif

	UPROPERTY(EditInstanceOnly)
	AHazeActor HammerIntroLocation;

	UPROPERTY(EditInstanceOnly)
	ASplineActor CircleMovementSplineActor;

	UPROPERTY(EditInstanceOnly)
	AActor ArenaInner;

	UPROPERTY(EditInstanceOnly)
	AActor ArenaCenter;

	UPROPERTY(EditInstanceOnly)
	ASplineActor ArenaBoundsSpline;
}