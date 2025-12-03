class ATundraBossFallingIceBlock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach  = MeshRoot)
	USceneComponent MovementRoot;

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	UStaticMeshComponent IceBlockMesh;
	default IceBlockMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default IceBlockMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTelegraphDecalComponent TelegraphDecal;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent FFComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ImpactVFX;
	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem CrackVFX;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	float LerpLocationDuration = 2.5;
	float LerpLocationDurationTimer = 0;
	bool bShouldLerpLocation = false;
	FVector MovementRootStartLocation;

	UPROPERTY(EditDefaultsOnly)
	float IceBlockImpactHitRadius = 350;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForcefeedbackEffect;

	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> ImpactCameraShakeClass;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	float Scale = 1.0;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	bool bPlayInWorld = true;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	float InnerRadius = 850.0;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	float OuterRadius = 3000.0;

	UPROPERTY(EditInstanceOnly)
	bool bDebugDrawDamageSpheres;

	UPROPERTY(EditInstanceOnly)
	bool bPreviewImpactLocation = false;

	UPROPERTY()
	TSubclassOf<UDamageEffect> FallingIceBlockDamageEffect;
	UPROPERTY()
	TSubclassOf<UDeathEffect> FallingIceBlockDeathEffect;

	FVector DecalStartingScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementRoot.SetRelativeLocation(FVector(0, 0, 10000));
		MovementRootStartLocation = MovementRoot.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bShouldLerpLocation)
		{
			float Alpha = Math::Saturate(LerpLocationDurationTimer / LerpLocationDuration);
			LerpLocationDurationTimer += DeltaSeconds;

			//When the block mesh should start lerping down
			float DropAlpha = 0.8;
			if(Alpha >= DropAlpha)
				MovementRoot.SetRelativeLocation(Math::Lerp(MovementRootStartLocation, FVector::ZeroVector, Math::Saturate((Alpha - DropAlpha) / (1.0 - DropAlpha))));

			BP_IceBlockLerpingTowardsGround(Alpha);

			if(Alpha >= 1)
			{
				bShouldLerpLocation = false;
				IceBlockHitGround();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bPreviewImpactLocation)
			MovementRoot.SetRelativeLocation(FVector(0, 0, 0));
		else
			MovementRoot.SetRelativeLocation(FVector(0, 0, 10000));
	}

	UFUNCTION()
	void DropIceBlock()
	{
		MovementRoot.SetRelativeLocation(FVector(0, 0, 10000));
		LerpLocationDurationTimer = 0;
		IceBlockMesh.SetHiddenInGame(false);
		TelegraphDecal.ShowTelegraph();
		bShouldLerpLocation = true;
		SetActorTickEnabled(true);
		BP_IceBlockStartedFalling();
		UTundraBossFallingIceBlockEffectEventHandler::Trigger_OnStartFalling(this);
	}

	void IceBlockHitGround()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactVFX, MeshRoot.WorldLocation);
		TelegraphDecal.HideTelegraph();

		ForceFeedback::PlayWorldForceFeedback(ForcefeedbackEffect, ActorLocation, false, this);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(ImpactCameraShakeClass, this, MeshRoot.WorldLocation, InnerRadius, OuterRadius, 1.0, Scale);

		bShouldLerpLocation = false;

		CollisionCheck(IceBlockImpactHitRadius);
		BP_IceBlockHitGround();
		FFComp.Play();

		UTundraBossFallingIceBlockEffectEventHandler::Trigger_OnHitGround(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_IceBlockStartedFalling()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_IceBlockLerpingTowardsGround(float Alpha)
	{}

	UFUNCTION(BlueprintEvent)
	void BP_IceBlockHitGround()
	{}

	void CollisionCheck(float SphereRadius)
	{
		for(auto Player : Game::Players)
		{
			FHazeShapeSettings CapsuleSettings = FHazeShapeSettings::MakeCapsule(Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.CapsuleHalfHeight);
			float DistToCapsule = CapsuleSettings.GetWorldDistanceToShape(Player.CapsuleComponent.WorldTransform, ActorLocation);

			if(DistToCapsule < SphereRadius)
			{
				FPlayerDeathDamageParams DeathParams;
				DeathParams.ImpactDirection = FVector::DownVector;
				DeathParams.ForceScale = 5;
				Player.DamagePlayerHealth(1.0, DeathParams, FallingIceBlockDamageEffect, FallingIceBlockDeathEffect);
			}
		}

		if(bDebugDrawDamageSpheres)
		{
			Debug::DrawDebugSphere(ActorLocation, SphereRadius, Duration = 2, LineColor = FLinearColor::Red);
		}
	}

	UFUNCTION(CallInEditor)
	void SetRandomYaw()
	{
		SetActorRotation(FRotator(ActorRotation.Pitch, Math::RandRange(0, 359), ActorRotation.Roll));
	}
};

class UTundraBossFallingIceBlockEffectEventHandler : UHazeEffectEventHandler
{
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFalling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitGround() {}

};