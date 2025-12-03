class ABattlefieldBreakableObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBattlefieldProjectileComponent ProjectileComponent;
	default ProjectileComponent.bAutoBehaviour = false;

	UPROPERTY(DefaultComponent)
	UBattlefieldBreakableObjectComponent BreakableObjectComp;

	UPROPERTY(EditAnywhere)
	bool bShouldShoot;

	float rMin = 1.0;
	float rMax = 2.0;

	UFUNCTION(CallInEditor)
	void RandomizeSize()
	{
		SetActorScale3D(FVector(Math::RandRange(rMin, rMax)));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		float RDelay = Math::RandRange(0.5, 3.0);
		// SetActorTickEnabled(false);
		if (bShouldShoot)
			ProjectileComponent.ActivateAutoFire(RDelay);
	}

	UFUNCTION()
	void BreakBattlefieldObject(FVector ImpactDirection, float ImpulseAmount)
	{
		BreakableObjectComp.BreakBattlefieldObject(ImpactDirection, ImpulseAmount);
	}
}