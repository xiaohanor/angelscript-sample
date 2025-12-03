event void FOnMuralKnockedOver();
event void FonFallCompleted();

class AGiantFallingObject : AHazeActor
{
	UPROPERTY()
	FOnMuralKnockedOver OnMuralKnockedOver;

	UPROPERTY()
	FonFallCompleted OnFallCompleted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MuralRoot;

	UPROPERTY(DefaultComponent, Attach = MuralRoot)
	UStaticMeshComponent MuralMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FallenMuralRoot;
	
	UPROPERTY(DefaultComponent, Attach = FallenMuralRoot)
	UStaticMeshComponent FallenMuralMeshComp;
	default FallenMuralMeshComp.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = MuralRoot)
	UBoxComponent BoxComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	UPROPERTY(DefaultComponent)
	USummitChainedBlockBreakResponseComponent SummitChainBlockResponseComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	bool bCanBeKnocked;

	bool bHaveHitNextMural;
	bool bHaveCompletedFall;
	bool bHaveBeenKnocked;

	float FallSpeed;

	UPROPERTY(EditAnywhere)
	float FallSpeedTarget = HALF_PI * 1.2;

	AGiantFallingObject PriorPillar;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		SummitChainBlockResponseComp.OnSummitChainedBlockImpact.AddUFunction(this, n"OnSummitChainedBlockImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FallSpeed = Math::FInterpConstantTo(FallSpeed, FallSpeedTarget, DeltaSeconds, FallSpeedTarget / 2);
		MuralRoot.RelativeRotation = Math::QInterpConstantTo(MuralRoot.RelativeRotation.Quaternion(), FallenMuralRoot.RelativeRotation.Quaternion(), DeltaSeconds, FallSpeed).Rotator();

		float Dot = MuralRoot.RelativeRotation.Vector().DotProduct(FallenMuralRoot.RelativeRotation.Vector()); 

		if (!bHaveCompletedFall && Dot > 0.99999)
		{
			bHaveCompletedFall = true;
			Game::Mio.PlayCameraShake(CameraShake, this, 1.0);
			Game::Zoe.PlayCameraShake(CameraShake, this, 1.0);
			SetActorTickEnabled(false);
			OnFallCompleted.Broadcast();
		}
	}

	UFUNCTION()
	void KnockOver(AGiantFallingObject Pillar = nullptr)
	{
		if (bHaveCompletedFall)
			return;

		if (bHaveBeenKnocked)
			return;
		
		bHaveBeenKnocked = true;
		FallSpeed = 0.0;

		if (CameraShake != nullptr)
		{
			Game::Mio.PlayCameraShake(CameraShake, this, 1.0);
			Game::Zoe.PlayCameraShake(CameraShake, this, 1.0);
		}

		PriorPillar = Pillar;
		AGiantFallingObject CheckPillar = PriorPillar;

		while (CheckPillar != nullptr)
		{
			CheckPillar.Impact();
			CheckPillar = CheckPillar.PriorPillar;
		}

		SetActorTickEnabled(true);

		OnMuralKnockedOver.Broadcast();
	}
	
	UFUNCTION()
	void Impact()
	{
		FallSpeed = 0.0;
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!bCanBeKnocked)
			return;

		KnockOver(nullptr);
	}

	UFUNCTION()
	private void OnSummitChainedBlockImpact()
	{
		KnockOver(nullptr);
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		AGiantFallingObject Mural = Cast<AGiantFallingObject>(OtherActor);

		if (Mural != nullptr && !bHaveHitNextMural)
		{
			if (Mural != this && Mural != PriorPillar && !Mural.bHaveBeenKnocked)
			{
				bHaveHitNextMural = true;
				Mural.KnockOver(this);
			}
		}

		UGoldGiantBreakResponseComponent Breakable = UGoldGiantBreakResponseComponent::Get(OtherActor);

		if (Breakable != nullptr)
		{
			FVector Direction = (OtherActor.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			Breakable.OnBreakGiantObject.Broadcast(Direction, 50000.0);
		}
	}
}