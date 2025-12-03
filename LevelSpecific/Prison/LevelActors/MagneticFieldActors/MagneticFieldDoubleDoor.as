class AMagneticFieldDoubleDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent LeftDoorRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent RightDoorRoot;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldComp;
}