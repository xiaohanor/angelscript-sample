class ASanctuaryDragableGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent GateRootComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ReturnForceComponent;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UDarkPortalTargetComponent DarkPortalTargetComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		GateRootComp.SetRelativeLocation(FVector(0.0, 0.0, TranslateComp.RelativeLocation.Z * -1));
	}
};