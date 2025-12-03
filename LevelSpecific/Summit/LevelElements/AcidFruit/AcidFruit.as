class AAcidFruit : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Root;
	default Root.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent PlayerCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ExplosionSystem;
	default ExplosionSystem.SetAutoActivate(false);


	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TeenDragonTailAttackResponseComp;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent)
	UAcidFruitExplosionComponent AcidBombExplosionComp;

	UMaterialInstanceDynamic DynamicMaterial;


	UPROPERTY(EditAnywhere)
	float LaunchForce = 20000000.0;
	UPROPERTY(EditAnywhere)
	float RollForce = 25000000.0;

	UPROPERTY(EditAnywhere)
	float MinExplosionVelocity = 900.0;

	TArray<float> FloatArray;
	default FloatArray.SetNum(3);

	int HitCount;
	FVector ScaleTarget;
	float Dot;
	float MinDot = 0.3;

	bool bShouldHavePhysics = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Root.SetSimulatePhysics(bShouldHavePhysics);

		DynamicMaterial = MeshComp.CreateDynamicMaterialInstance(0);
		MeshComp.SetMaterial(0, DynamicMaterial);

		TeenDragonTailAttackResponseComp.OnHitByTailAttack.AddUFunction(this, n"OnHitByTailAttack");
		TeenDragonTailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		ScaleTarget = ActorScale3D;

		Root.OnComponentHit.AddUFunction(this, n"OnComponentHit");
	}
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		DynamicMaterial.SetScalarParameterValue(n"AcidAlpha", AcidBombExplosionComp.GetAcidPercentage() / 2);
	}


	UFUNCTION()
	private void OnComponentHit(UPrimitiveComponent HitComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, FVector NormalImpulse, const FHitResult&in Hit)
	{
		Dot = FVector::UpVector.DotProduct(Hit.ImpactNormal);

		if(Dot > MinDot)
			return;

		if(!AcidBombExplosionComp.CanExplode())
			return;

		if(Root.GetComponentVelocity().Size() < MinExplosionVelocity)
			return;

		MeshComp.SetHiddenInGame(true);
		Root.SetSimulatePhysics(false);
		Root.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		PlayerCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		ExplosionSystem.Activate();
		AcidBombExplosionComp.OnExplode();
	}

	UFUNCTION()
	private void OnHitByTailAttack(FTailAttackParams Params)
	{
		FVector Direction = (Params.AttackDirection + (FVector::UpVector * 0.25)).GetSafeNormal();
		FVector Impulse = Direction * LaunchForce;

		Root.AddImpulse(Impulse);
	}


	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		FVector Direction = Params.RollDirection.GetSafeNormal();
		FVector Impulse = Direction * RollForce;

		Root.AddImpulse(Impulse);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Param)
	{

		AcidBombExplosionComp.AddHitCount();

	}



}