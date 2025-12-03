class ASplitTraversalWaterTop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent FloatingPlatformAttachmentRoot;

	UPROPERTY(EditAnywhere)
	float CurrentRadius = 1000.0;

	UPROPERTY(EditAnywhere)
	float CurrentStrength = 1000.0;

	bool bCurrentActivated = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bCurrentActivated)
		{
			FVector ForceDirection = (TranslateComp.WorldLocation - ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();
			float DistanceToCurrentOrigin = ((TranslateComp.WorldLocation - ActorLocation) * FVector(1.0, 1.0, 0.0)).Size();
			float ForceStrength =  Math::Max((CurrentRadius - DistanceToCurrentOrigin) / CurrentRadius * CurrentStrength, 0.0);
			FVector Force = ForceDirection * ForceStrength;

			TranslateComp.ApplyForce(ActorLocation, Force);
		}
	}

	void AttachedToTopWater()
	{
		bCurrentActivated = true;
	}
};