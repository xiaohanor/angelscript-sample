UCLASS(Abstract)
class APrisonDrones_BowlingPin : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent FauxTranslateComp;

	UPROPERTY(DefaultComponent, Attach = FauxTranslateComp)
	UFauxPhysicsFreeRotateComponent FauxRotateComp;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UFauxPhysicsWeightComponent FauxWeightComp;

	default FauxWeightComp.MassScale = 0.5;
	default FauxWeightComp.bApplyGravity = false;
	default FauxWeightComp.bApplyInertia = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp;

	bool bHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CapsuleComp.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
	}


	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		if(!bHit)
		{
			FVector Impulse = OtherComp.WorldLocation - GetActorLocation();
			Impulse.Normalize();
			Impulse *= Math::RandRange(-1500,-1000);
			Impulse.Z = 1000;

			FauxRotateComp.ApplyImpulse(OtherComp.WorldLocation, Impulse/2);
			FauxTranslateComp.ApplyImpulse(OtherComp.WorldLocation, Impulse);
			bHit = true;
			FauxWeightComp.bApplyGravity = true;
		}
	}
};
