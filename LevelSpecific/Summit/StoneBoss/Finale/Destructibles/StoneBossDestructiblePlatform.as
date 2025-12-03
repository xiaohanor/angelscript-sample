event void FOnStoneBossDestructbilePlatformDestroyed();

class AStoneBossDestructiblePlatform : AHazeActor
{
	UPROPERTY()
	FOnStoneBossDestructbilePlatformDestroyed OnStoneBossDestructbilePlatformDestroyed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent TelegraphLoopSystem;
	default TelegraphLoopSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default MeshComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
	default MeshComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Block);

	UPROPERTY(EditAnywhere)
	float DestructionTime = 1.5;

	UPROPERTY(EditAnywhere)
	float ShakeIntensity = 1.0;

	UPROPERTY(EditAnywhere)
	ARespawnPointVolume AttachedRespawnVolume;

	UPROPERTY()
	UNiagaraSystem DestructionSystem;

	UPROPERTY()
	UMaterialInterface BreakMaterial;

	float TargetYaw = 1.5;
	float TargetZ = 5.0;
	float CurrentMultiplier;

	FVector StartLoc;
	FRotator StartRot;

	bool bPlatformDestroyed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		StartLoc = MeshRoot.RelativeLocation;
		StartRot = MeshRoot.RelativeRotation;
		CurrentMultiplier = 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		DestructionTime -= DeltaSeconds;

		CurrentMultiplier = Math::FInterpConstantTo(CurrentMultiplier, 1.0, DeltaSeconds, 0.5);

		float YawMultiplier = Math::Sin(Time::GameTimeSeconds * 30.0);
		float ZMultiplier = Math::Sin(Time::GameTimeSeconds * 40.5);
		float YawRot = TargetYaw * YawMultiplier * CurrentMultiplier * ShakeIntensity;
		float ZOffset = TargetYaw * ZMultiplier * CurrentMultiplier * ShakeIntensity;

		FVector NewLoc = StartLoc + FVector(0.0, 0.0, ZOffset);
		FRotator NewRot = StartRot + FRotator(0.0, YawRot, 0.0);
		MeshRoot.RelativeLocation = NewLoc;
		MeshRoot.RelativeRotation = NewRot;

		if (DestructionTime <= 0.0)
		{
			if (AttachedRespawnVolume != nullptr)
			{
				AttachedRespawnVolume.DisableRespawnPointVolume(this);
			}
			
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DestructionSystem, ActorLocation, ActorRotation);
			DestroyPlatform();
			OnStoneBossDestructbilePlatformDestroyed.Broadcast();
		}
	}

	UFUNCTION()
	void ActivateDestructiblePlatform()
	{
		if (bPlatformDestroyed)
			return;
		
		TelegraphLoopSystem.Activate();
		MeshComp.SetMaterial(0, BreakMaterial);
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void SetDestructiblePlatformEndState()
	{
		DestroyPlatform();
	}

	private void DestroyPlatform()
	{
		bPlatformDestroyed = true;
		MeshComp.SetHiddenInGame(true);
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		TelegraphLoopSystem.Deactivate();
		SetActorTickEnabled(false);
	}
};