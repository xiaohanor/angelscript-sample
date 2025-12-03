class AShapeshiftingLeapingEffectActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetWorldScale3D(FVector(0.01, 0.01, 0.125));
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	float LifeTime = 1.5;

	FVector TargetScale = FVector(1.5, 1.5, 0.125);

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LifeTime -= DeltaSeconds;

		FVector NewScale = Math::VInterpTo(MeshComp.GetWorldScale(), TargetScale, DeltaSeconds, 13);
		MeshComp.SetWorldScale3D(NewScale);

		if (LifeTime <= 0.0)
			DestroyActor();
	}
}