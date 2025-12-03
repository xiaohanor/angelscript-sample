class USummitExplodyFruitTreeAttachment : USceneComponent
{
	ASummitExplodyFruitTree Tree;
	TOptional<ASummitExplodyFruit> AttachedFruit;

	float TimeLastDetached = 0.0;
	float TimeLastSpawned = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Tree = Cast<ASummitExplodyFruitTree>(Owner);
	}

	void AttachFruit(ASummitExplodyFruit Fruit)
	{
		AttachedFruit.Set(Fruit);
		TimeLastSpawned = Time::GameTimeSeconds;

		Fruit.OnExploded.AddUFunction(this, n"FruitExploded");
	}

	UFUNCTION(NotBlueprintCallable)
	private void FruitExploded(ASummitExplodyFruit ExplodingFruit)
	{
		if(AttachedFruit.IsSet())
		{
			TimeLastDetached = Time::GameTimeSeconds;
			Tree.CurrentlyAttachedFruitAttachments.RemoveSingleSwap(this);
			AttachedFruit.Reset();
		}
	}
}

class ASummitExplodyFruitTree : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent ConeRotateComp;
	default ConeRotateComp.ConeAngle = 15.0;
	default ConeRotateComp.SpringStrength = 2.5;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UStaticMeshComponent TreeMesh;

	UPROPERTY(DefaultComponent, Attach = TreeMesh)
	UTeenDragonTailAttackResponseComponent ResponseComp;
	default ResponseComp.bIsPrimitiveParentExclusive = false;

	UPROPERTY(DefaultComponent, Attach = TreeMesh)
	USceneComponent FruitRootParent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitExplodyFruitTreeRespawnFruitCapability");

#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitExplodyFruitTreeDummyComponent DummyComp;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 40000.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<ASummitExplodyFruit> ExplodyFruitClass;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float FruitGrowDelay = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int FruitMaxCount = 4;

	TArray<USummitExplodyFruitTreeAttachment> FruitAttachments;
	TArray<USummitExplodyFruitTreeAttachment> CurrentlyAttachedFruitAttachments;

	TArray<ASummitExplodyFruit> DisabledFruits;
	TArray<ASummitExplodyFruit> EnabledFruits;

	USummitExplodyFruitTreeAttachment LastDetachedAttachment;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		ResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		FruitRootParent.GetChildrenComponentsByClass(USummitExplodyFruitTreeAttachment, false, FruitAttachments);

		for(int i = 0; i < FruitMaxCount; i++)
		{
			auto FruitActor = SpawnActor(ExplodyFruitClass, bDeferredSpawn = true);
			auto Fruit = Cast<ASummitExplodyFruit>(FruitActor);
			Fruit.MakeNetworked(this, i);
			Fruit.bIsEnabled = false;
			Fruit.bIsInitialFruit = true;
			FinishSpawningActor(Fruit);

			DisabledFruits.Add(Fruit);
			Fruit.OnExploded.AddUFunction(this, n"OnFruitExploded");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// To stop jitter after being at rest for some time
		if(ConeRotateComp.AngularVelocity.IsNearlyZero(0.02))
			ConeRotateComp.AngularVelocity = FVector::ZeroVector;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnFruitExploded(ASummitExplodyFruit ExplodingFruit)
	{
		EnabledFruits.RemoveSingleSwap(ExplodingFruit);
		DisabledFruits.Add(ExplodingFruit);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnHitByRoll(FRollParams Params)
	{
		FauxPhysics::ApplyFauxImpulseToActorAt(this, Params.HitLocation, Params.RollDirection * Params.SpeedTowardsImpact);

		if(HasControl())
			DetachRandomFruit();
	}

	private USummitExplodyFruitTreeAttachment GetRandomFruitRoot()
	{
		return CurrentlyAttachedFruitAttachments[Math::Rand() % CurrentlyAttachedFruitAttachments.Num()];
	}

	private void DetachRandomFruit()
	{
		if(CurrentlyAttachedFruitAttachments.Num() == 0)
			return;
		
		USummitExplodyFruitTreeAttachment RandomAttachment;
		
		RandomAttachment = GetRandomFruitRoot();

		DetachFruit(RandomAttachment);
	}
	
	private void DetachFruit(USummitExplodyFruitTreeAttachment Attachment)
	{
		auto Fruit = Attachment.AttachedFruit.Value;
		Attachment.AttachedFruit.Reset();
		Fruit.CurrentAttachment.Reset();

		Attachment.TimeLastDetached = Time::GameTimeSeconds;

		CurrentlyAttachedFruitAttachments.RemoveSingleSwap(Attachment);
	}
};

#if EDITOR
class USummitExplodyFruitTreeDummyComponent : UActorComponent {};
class USummitExplodyFruitTreeComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitExplodyFruitTreeDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitExplodyFruitTreeDummyComponent>(Component); 
		if(Comp == nullptr)
			return;
		
		auto Tree = Cast<ASummitExplodyFruitTree>(Comp.Owner);
		if(Tree == nullptr)
			return;
		
		TArray<USummitExplodyFruitTreeAttachment> FruitRoots;
		Tree.FruitRootParent.GetChildrenComponentsByClass(USummitExplodyFruitTreeAttachment, false, FruitRoots);

		for(auto FruitRoot : FruitRoots)
		{
			const float FruitRadius = 180;

			DrawWireSphere(FruitRoot.WorldLocation - FruitRoot.UpVector * FruitRadius, FruitRadius, FLinearColor::Purple, 20, 12);
		}
	}
}
#endif