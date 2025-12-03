class AMagneticFieldSplineActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp, ShowOnActor)
	UFauxPhysicsSplineFollowComponent SplineFollowComp;
	default SplineFollowComp.SplineBoundBounce = 0.1;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(2.0);

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldComp;

	UPROPERTY(EditAnywhere)
	float ReverseStrength = 1500.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector DirectionAtSplineDistance = -SplineFollowComp.SplinePosition.WorldForwardVector;
		SplineFollowComp.ApplyForce(SplineFollowComp.WorldLocation, DirectionAtSplineDistance * ReverseStrength);

		// SetActorRotation(DirectionAtSplineDistance.Rotation());
		FQuat Rot = SplineFollowComp.SplinePosition.CurrentSpline.GetWorldRotationAtSplineDistance(SplineFollowComp.SplinePosition.CurrentSplineDistance);
		SplineFollowComp.SetWorldRotation(Rot);
	}
}