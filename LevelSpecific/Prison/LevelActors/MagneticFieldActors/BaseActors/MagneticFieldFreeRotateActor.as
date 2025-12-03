class AMagneticFieldFreeRotateActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsFreeRotateComponent FreeRotateComp;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;
}