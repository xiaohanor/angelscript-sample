class ASanctuaryLavamoleWhackSplitBody : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FauxRoot;

	UPROPERTY(DefaultComponent, Attach = FauxRoot)
	UFauxPhysicsSplineTranslateComponent SplineTranslateComp;
	default SplineTranslateComp.bStartDisabled = true;
	default SplineTranslateComp.bConstrainWithSpline = false;
	default SplineTranslateComp.ConstrainedVerticalVelocity = 900;
	default SplineTranslateComp.bConstrainZ = true;
	default SplineTranslateComp.MinZ = 0;
	default SplineTranslateComp.MaxZ = 1000;

	UPROPERTY(DefaultComponent, Attach = SplineTranslateComp)
	UFauxPhysicsFreeRotateComponent FauxFreeRotateComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 15000;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams Anim;

	bool bTaken = false;
	bool bFauxing = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
	}

	void EnableHead(FVector Location, FRotator Rotation, FVector Impulse)
	{
		bFauxing = true;
		SetActorLocationAndRotation(Location, Rotation, true);
		SetActorHiddenInGame(false);
		SkeletalMesh.SetVisibility(true);

		SplineTranslateComp.bConstrainWithSpline = true;
		SplineTranslateComp.bClockwise = false;
		SplineTranslateComp.RemoveDisabler(SplineTranslateComp);
		SkeletalMesh.PlaySlotAnimation(Anim);

		SplineTranslateComp.ApplyImpulse(Location - FVector::UpVector, Impulse);
		FauxFreeRotateComp.ApplyImpulse(Location - FVector::UpVector, Impulse);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bFauxing)
		{
			SplineTranslateComp.ApplyForce(ActorLocation + FVector::UpVector, -FVector::UpVector * 980.0);
		}
	}
};