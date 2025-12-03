event void FOnGiantBreakableObjectBroken();

class AGiantBreakableObject : AHazeActor
{
	UPROPERTY()
	FOnGiantBreakableObjectBroken OnGiantBreakableObjectBroken;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.bGenerateOverlapEvents = false;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent BreakVFXLocation;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(DefaultComponent)
	UGoldGiantBreakResponseComponent BreakComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailBombImpactResponseComponent BombResponseComp;

	UPROPERTY(EditAnywhere)
	bool bIsDestructible;

	UPROPERTY(EditAnywhere)
	bool bIgnorePlayerCollision = true;

	UPROPERTY(EditAnywhere)
	TArray<ANightQueenMetal> NightQueenMetals;

	UPROPERTY(EditAnywhere)
	float CameraShakeMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	bool bShouldShrink;

	//When destroyed, scale meshes by this amount
	UPROPERTY(EditAnywhere)
	float DestructionScaleMultiplier = 1.0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bShouldShrink", EditConditionHides))
	float ShrinkTime = -1.0;
	float FutureShrinkTime;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bShouldShrink", EditConditionHides))
	float ShrinkSpeed = 0.98;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	TArray<AActor> AttachedActors;

	int Count;

	TArray<UStaticMeshComponent> MeshComps;

	bool bCanBreak;
	UPROPERTY()
	bool bCanShrink;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(MeshComps);
		BreakComp.OnBreakGiantObject.AddUFunction(this, n"OnBreakGiantObject");
		BombResponseComp.OnExplodedEvent.AddUFunction(this, n"OnExplodedEvent");

		if (NightQueenMetals.Num() > 0)
		{
			for (ANightQueenMetal Metal : NightQueenMetals)
			{
				Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
				Count++;
			}
		}
		else
		{
			bCanBreak = true;
		}

		GetAttachedActors(AttachedActors, true);

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds < FutureShrinkTime)
			return;
		
		if (!bCanShrink)
			return;

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			FVector NewScale = Mesh.GetWorldScale() - (Mesh.GetWorldScale() * ShrinkSpeed * DeltaSeconds);
			Mesh.SetWorldScale3D(NewScale);
		}			
	}

	UFUNCTION()
	private void OnExplodedEvent(FTeenDragonTailBombImpactResonseData Data)
	{
		FVector Direction = (ActorLocation - Data.Bomb.ActorLocation).GetSafeNormal();
		OnBreakGiantObject(Direction, 18000.0);
	}

	UFUNCTION()
	void OnBreakGiantObject(FVector ImpactDirection, float ImpulseAmount)
	{
		if (Count > 0)
			return;

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			// Mesh.SetRelativeScale3D(Mesh.RelativeScale3D * DestructionScaleMultiplier);
			if (bIgnorePlayerCollision)
				Mesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);

			Mesh.SetSimulatePhysics(true);
			FVector Impulse;

			if (ImpactDirection.Size() == 0)
				Impulse = ImpactDirection * ImpulseAmount;
			else
				Impulse = (Mesh.WorldLocation - ActorLocation).GetSafeNormal() * ImpulseAmount;

			Mesh.AddImpulse(Impulse);
		}

		for (AActor Actor : AttachedActors)
		{
			TArray<UStaticMeshComponent> AttachedActorMeshComps;
			Actor.GetComponentsByClass(AttachedActorMeshComps);

			for (UStaticMeshComponent Mesh : AttachedActorMeshComps)
			{
				// Mesh.SetRelativeScale3D(Mesh.RelativeScale3D * DestructionScaleMultiplier);
				if (bIgnorePlayerCollision)
					Mesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);

				Mesh.SetSimulatePhysics(true);
				FVector Impulse;

				if (ImpactDirection.Size() == 0)
					Impulse = (Mesh.WorldLocation - ActorLocation).GetSafeNormal() * ImpulseAmount;
				else
					Impulse = (Mesh.WorldLocation - Actor.ActorLocation).GetSafeNormal() * ImpulseAmount;
				
				Mesh.AddImpulse(Impulse);			
			}
		}

		// for (UStaticMeshComponent Mesh : MeshComps)
		// 	Mesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
		
		Game::Mio.PlayCameraShake(CameraShake, this, CameraShakeMultiplier);
		Game::Zoe.PlayCameraShake(CameraShake, this, CameraShakeMultiplier);
		BoxComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		OnGiantBreakableObjectBroken.Broadcast();
		
		if (bShouldShrink)
		{
			SetActorTickEnabled(true);
			if (ShrinkTime > 0.0)
				FutureShrinkTime = Time::GameTimeSeconds + ShrinkTime;
		}

		if(bIsDestructible)
		{
			AddActorDisable(this);
		}
	}

	UFUNCTION()
	private void OnDestructibleRockHit(USceneComponent HitComponent)
	{
		FImpactDestructibleRocksParams Params;
		Params.Location = HitComponent.WorldLocation;
		UPrimitiveComponent PrimComp = Cast<UPrimitiveComponent>(HitComponent);
		if (PrimComp != nullptr)
		{
			PrimComp.SetSimulatePhysics(false);
			PrimComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			PrimComp.SetHiddenInGame(true);
			UAdultDragonImpactDestructibleRocksEventHandler::Trigger_OnRockImpact(this, Params);
		}
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		Count--;
	}

}