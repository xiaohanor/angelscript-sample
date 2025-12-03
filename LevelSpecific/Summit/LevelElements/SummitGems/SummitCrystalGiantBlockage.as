class ASummitCrystalGiantBlockage : ASummitNightQueenGem
{
	default CapsuleComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UGoldGiantBreakResponseComponent BreakComp;

	TArray<UStaticMeshComponent> MeshComps;

	int Count;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		// for (ANightQueenMetal Target : MetalProtectors)
		// {
		// 	Target.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		// 	Target.OnNightQueenMetalRecovered.AddUFunction(this, n"OnNightQueenMetalRecovered");
		// }

		GetComponentsByClass(MeshComps);
		BreakComp.OnBreakGiantObject.AddUFunction(this, n"OnGoldGiantBreak");

		// if (MetalProtectors.Num() > 0)
		// 	BreakComp.AddDisabler(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds) override
	{
		Super::Tick(DeltaSeconds);
		// PrintToScreen("Count: " + Count);
		// PrintToScreen("MetalProtectors: " + MetalProtectors.Num());
	}

	UFUNCTION()
	private void OnNightQueenMetalRecovered()
	{
		Count--;
		// Count = Math::Clamp(Count, 0, MetalProtectors.Num());
		SetCanHit();
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		Count++;
		// Count = Math::Clamp(Count, 0, MetalProtectors.Num());
		SetCanHit();
	}

	void SetCanHit()
	{
		// if (Count >= MetalProtectors.Num())
		// 	BreakComp.RemoveDisabler(this);
		// else 
		// 	BreakComp.AddDisabler(this);
	}

	UFUNCTION()
	private void OnGoldGiantBreak(FVector ImpactDirection, float ImpulseAmount)
	{
		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Mesh.SetSimulatePhysics(true);
			FVector Impulse = ImpactDirection * ImpulseAmount;
			Mesh.AddImpulse(Impulse);
			DestroyCrystal();
		}
	}
}