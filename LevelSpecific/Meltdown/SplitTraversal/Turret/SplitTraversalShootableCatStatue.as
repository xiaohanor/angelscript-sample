class ASplitTraversalShootableCatStatue : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent JawTranslateComp;

	UPROPERTY(DefaultComponent, Attach = JawTranslateComp)
	UFauxPhysicsForceComponent ForceCompJaw;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceCompArm;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		JawTranslateComp.OnConstraintHit.AddUFunction(this, n"HandleJawClosed");
	}

	UFUNCTION()
	void Activate()
	{
		ForceCompJaw.Force = FVector::UpVector * 3000.0;
	}

	UFUNCTION()
	private void HandleJawClosed(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		ForceCompArm.Force = FVector::RightVector * 300.0;
	}
};