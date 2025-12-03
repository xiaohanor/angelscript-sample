class ASummitStoneBlockMeltable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HitPoint;

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

	UPROPERTY(EditInstanceOnly)
	ANightQueenMetal Metal;

	UPROPERTY(EditInstanceOnly)
	bool bApplyImpulse = true;

	float ScaleTarget = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		StartBlockFall();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		WeightComp.MassScale = Math::FInterpConstantTo(WeightComp.MassScale, ScaleTarget, DeltaSeconds, 0.75);
	}

	void StartBlockFall()
	{
		WeightComp.MassScale = 0.5;

		if (bApplyImpulse)
		{
			TranslateComp.ApplyImpulse(HitPoint.WorldLocation, -ActorForwardVector * 1000.0);
			AxisRotateComp.ApplyImpulse(HitPoint.WorldLocation, -HitPoint.ForwardVector * 250.0);
		}

		SetActorTickEnabled(true);

		CounterWeight.StartForce();
	}
};