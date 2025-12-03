class ASummitPathCrystal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Root;
	default Root.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent PlayerCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	int HitCount;
	FVector ScaleTarget;
	float Dot;
	float MinDot = 0.3;

	UPROPERTY(EditAnywhere)
	bool bStartWithPhysics = false;
	UPROPERTY(EditAnywhere)
	bool bNeverHavePhysics = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Root.SetSimulatePhysics(bStartWithPhysics);

		if (!bStartWithPhysics)
			Root.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		
		ScaleTarget = ActorScale3D;

		Root.OnComponentHit.AddUFunction(this, n"OnComponentHit");
	}


	UFUNCTION()
	private void OnComponentHit(UPrimitiveComponent HitComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, FVector NormalImpulse, const FHitResult&in Hit)
	{
		Dot = FVector::UpVector.DotProduct(Hit.ImpactNormal);

		if(Dot > MinDot)
			return;

		MeshComp.SetHiddenInGame(true);
		Root.SetSimulatePhysics(false);
		Root.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		PlayerCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void Activate() {
		Root.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		Root.SetSimulatePhysics(true);
	}

	UFUNCTION()
	void Deactivate() {
		Root.SetSimulatePhysics(false);
		Root.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

}
