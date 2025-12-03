class AMagneticFieldTranslateActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(2.0);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.ConstrainBounce = 0.1;
	default TranslateComp.SpringStrength = 5.0;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldComp;
}