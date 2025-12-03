class ASummitStoneBlockKnockable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HitPoint;

	UPROPERTY(DefaultComponent)
	UBoxComponent KnockCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.Friction = 1.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsWeightComponent WeightComp;
	default WeightComp.MassScale = 0.0;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditInstanceOnly)
	ASummitCounterWeight CounterWeight;

	float ScaleTarget = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		KnockCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		WeightComp.MassScale = Math::FInterpConstantTo(WeightComp.MassScale, ScaleTarget, DeltaSeconds, 0.75);
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto FallingPillar = Cast<ASummitTailFallingPillar>(OtherActor);
		if (FallingPillar == nullptr)
			return;
		
		StartBlockFall();
	}

	void StartBlockFall()
	{
		WeightComp.MassScale = 0.5;
		TranslateComp.ApplyImpulse(HitPoint.WorldLocation, -ActorForwardVector * 1000.0);
		AxisRotateComp.ApplyImpulse(HitPoint.WorldLocation, -HitPoint.ForwardVector * 250.0);

		SetActorTickEnabled(true);

		CounterWeight.StartForce();
	}
};