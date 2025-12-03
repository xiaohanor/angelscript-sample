event void FOnStatueKnockedOver();

class AGiantChainedStatue : AHazeActor
{
	UPROPERTY()
	FOnStatueKnockedOver StatueKnockedOver;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StatueRoot;

	UPROPERTY(DefaultComponent, Attach = StatueRoot)
	UStaticMeshComponent StatueMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StatueFallRoot;

	UPROPERTY(DefaultComponent, Attach = StatueFallRoot)
	UStaticMeshComponent StatueFallMesh;
	default StatueFallMesh.SetHiddenInGame(true);


	UPROPERTY(EditAnywhere)
	TArray<ANightQueenMetal> QueenMetal;

	UPROPERTY(EditAnywhere)
	ASummitNightQueenGem QueenGem;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CamShake;

	int MetalCount;
	bool bCanBreak;

	bool bHaveCompletedFall;
	bool bHaveHitStatue;

	float FallSpeed;

	UPROPERTY(EditAnywhere)
	float FallspeedTarget = HALF_PI * 1.2;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		SetActorTickEnabled(false);
		QueenGem.OnSummitGemDestroyed.AddUFunction(this,n"OnGemDestroyed");

		if (QueenMetal.Num() > 0)	
		{
			for (ANightQueenMetal Metal : QueenMetal)
			{
				Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnMetalMelted");
				MetalCount++;
			}
		}

	}

	UFUNCTION()
	private void OnGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
			if(MetalCount > 0)
				return;
			bHaveHitStatue = true;
			KnockOver();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		FallSpeed = Math::FInterpConstantTo(FallSpeed,FallspeedTarget,DeltaSeconds, InterpSpeed = FallspeedTarget / 2);
		StatueRoot.RelativeRotation = Math::QInterpConstantTo(StatueRoot.RelativeRotation.Quaternion(), StatueFallRoot.RelativeRotation.Quaternion(), DeltaSeconds, FallSpeed).Rotator();

		float Dot = StatueRoot.RelativeRotation.Vector().DotProduct(StatueFallRoot.RelativeRotation.Vector());


		if(!bHaveCompletedFall && Dot > 0.99999)
		{
			bHaveCompletedFall = true;
			Game::Mio.PlayCameraShake(CamShake, this, 1.0);
			Game::Zoe.PlayCameraShake(CamShake, this, 1.0);
		}
	}

	UFUNCTION()
	void KnockOver()
	{	
		SetActorTickEnabled(true);
		FallSpeed = 0.0;
		StatueKnockedOver.Broadcast();
		Game::Mio.PlayCameraShake(CamShake, this, 1.0);
		Game::Zoe.PlayCameraShake(CamShake, this, 1.0);
	}

	UFUNCTION()
	private void OnComponentOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{	
		APulleyObjectSpline Battering = Cast <APulleyObjectSpline>(OtherActor);

			if(Battering != nullptr && !bHaveHitStatue)
			{	
					if(MetalCount > 0)
						return;
					bHaveHitStatue = true;
					KnockOver();
			}
	}

	UFUNCTION()
	private void OnMetalMelted()
	{
		MetalCount--;
	}
}