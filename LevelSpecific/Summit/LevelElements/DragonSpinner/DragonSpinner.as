class ADragonSpinner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	private float SpinForce;
	private float SpinDecceleration = 300.0;  
	private float MaxSpinForce = 650.0;

	UPROPERTY(EditAnywhere)
	TArray<AActor> TargetActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AActor Actor : TargetActors)
		{
			UDragonSpinnerResponseComponent Comp = UDragonSpinnerResponseComponent::Get(Actor);
			Comp.InitiateComponent(this);
		}

		TailResponseComp.OnHitByTailAttack.AddUFunction(this, n"OnTailHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MeshRoot.AddLocalRotation(FRotator(0.0, 0.0, SpinForce * DeltaTime));
		
		if (SpinForce > 0.0)
			SpinForce -= SpinDecceleration * DeltaTime;
		else if (SpinForce < 0.0)
			SpinForce += SpinDecceleration * DeltaTime;

		SpinForce = Math::Clamp(SpinForce, -MaxSpinForce, MaxSpinForce);
	}

	UFUNCTION()
	private void OnTailHit(FTailAttackParams Params)
	{
		float Dot = ActorRightVector.DotProduct(Params.AttackDirection);

		if (Dot > 0.0)
			Dot = Math::Clamp(Dot, 0.5, 1.0);
		else if (Dot < 0.0)
			Dot = Math::Clamp(Dot, -1.0, -0.5);
		
		SpinForce += MaxSpinForce * Dot;
		SpinForce = Math::Clamp(SpinForce, -MaxSpinForce, MaxSpinForce);
	}

	float GetSpinForce()
	{
		return SpinForce;
	}
}