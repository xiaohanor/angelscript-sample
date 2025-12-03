class ASanctuarySeesaw : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent CenterOfMassForceComp;

	UPROPERTY(DefaultComponent)
	USanctuaryPlayerWeightComponent PlayerWeightComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};