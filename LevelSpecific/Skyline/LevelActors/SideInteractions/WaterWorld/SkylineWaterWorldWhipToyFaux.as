class ASkylineWaterWorldWhipToyFaux : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsSplineTranslateComponent FauxTranslation;
	default FauxTranslation.Shape = EFauxPhysicsSplineTranslateShape::Point;
	default FauxTranslation.bConstrainWithSpline = false;
	default FauxTranslation.bConstrainZ = false;
	default FauxTranslation.ConstrainedVerticalVelocity = 300.0;
	default FauxTranslation.ConstrainedHorizontalVelocity = 1000.0;

	UPROPERTY(DefaultComponent, Attach = FauxTranslation)
	UFauxPhysicsAxisRotateComponent FauxRotateComp;
	default FauxRotateComp.LocalRotationAxis = FVector::UpVector;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	FHazeAcceleratedQuat AccRemoveOffset;
}