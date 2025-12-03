class ATundraBossFallingIcicle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach  = MeshRoot)
	USceneComponent MovementRoot;

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	UStaticMeshComponent IcicleMesh;
	default IcicleMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default IcicleMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTelegraphDecalComponent TelegraphDecal;

	UPROPERTY()
	FHazeTimeLike HideIcicleMeshTimelike;
	default HideIcicleMeshTimelike.Duration = 2;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ImpactVFX;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	float LerpLocationDuration = 1.5;
	float LerpLocationDurationTimer = 0;
	bool bShouldLerpLocation = false;
	FVector MovementRootStartLocation;
	FVector IcicleMeshStartingLocation;

	UPROPERTY(EditDefaultsOnly)
	float IcicleImpactHitRadius = 110;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForcefeedbackEffect;

	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> ImpactCameraShakeClass;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> ExplosionCameraShakeClass;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	float Scale = 1.0;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	bool bPlayInWorld = true;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	float InnerRadius = 600.0;
	UPROPERTY(EditDefaultsOnly, Category = "CameraShake")
	float OuterRadius = 3000.0;

	UPROPERTY()
	TSubclassOf<UDamageEffect> FallingIcicleDamageEffect;
	UPROPERTY()
	TSubclassOf<UDeathEffect> FallingIcicleDeathEffect;

	UPROPERTY(EditInstanceOnly)
	bool bDebugDrawDamageSpheres;

	UPROPERTY(EditInstanceOnly)
	bool bPreviewImpactLocation = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementRoot.SetRelativeLocation(FVector(0, 0, 10000));
		MovementRootStartLocation = MovementRoot.RelativeLocation;
		IcicleMeshStartingLocation = IcicleMesh.RelativeLocation;
		HideIcicleMeshTimelike.BindUpdate(this, n"HideIcicleMeshTimelikeUpdate");
		HideIcicleMeshTimelike.BindFinished(this, n"HideIcicleMeshTimelikeFinished");
	}

	UFUNCTION()
	private void HideIcicleMeshTimelikeFinished()
	{
		ResetIcicle();
	}

	UFUNCTION()
	private void HideIcicleMeshTimelikeUpdate(float CurrentValue)
	{
		IcicleMesh.SetRelativeLocation(Math::Lerp(IcicleMeshStartingLocation, IcicleMeshStartingLocation + FVector(0, 0, -400), CurrentValue));
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bPreviewImpactLocation)
			MovementRoot.SetRelativeLocation(FVector(0, 0, 0));
		else
			MovementRoot.SetRelativeLocation(FVector(0, 0, 10000));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bShouldLerpLocation)
		{
			float Alpha = Math::Saturate(LerpLocationDurationTimer / LerpLocationDuration);
			LerpLocationDurationTimer += DeltaSeconds;

			//Weird thing maybe, but we want the full lerp of the Icicle to start when the decal has lerped 75%
			if(Alpha >= 0.75)
			{
				MovementRoot.SetRelativeLocation(Math::Lerp(MovementRootStartLocation, FVector::ZeroVector, Math::Saturate((Alpha - 0.75) / (1.0 - 0.75))));
			}

			BP_IcicleLerpingTowardsGround(Alpha);

			if(Alpha >= 1)
			{
				bShouldLerpLocation = false;
				IcicleHitGround();
			}
		}
	}

	UFUNCTION()
	void StartIcicleDrop(FVector DropLocation, float ZValue, float DropDelay)
	{
		SetActorLocation(FVector(DropLocation.X, DropLocation.Y, ZValue));
		
		if(DropDelay > 0)
			Timer::SetTimer(this, n"DropIcicle", DropDelay);
		else
			DropIcicle();
	}

	UFUNCTION()
	private void DropIcicle()
	{
		LerpLocationDurationTimer = 0;
		IcicleMesh.SetHiddenInGame(false);
		TelegraphDecal.ShowTelegraph();
		bShouldLerpLocation = true;
		SetActorTickEnabled(true);
		UTundraBossFallingIcicleEffectEventHandler::Trigger_OnStartFalling(this);

		if(HideIcicleMeshTimelike.IsPlaying())
		{
			HideIcicleMeshTimelike.Stop();
		}
	}

	void IcicleHitGround()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactVFX, MeshRoot.WorldLocation);
		UTundraBossFallingIcicleEffectEventHandler::Trigger_OnHitGround(this);
		TelegraphDecal.HideTelegraph();

		ForceFeedback::PlayWorldForceFeedback(ForcefeedbackEffect, ActorLocation, false, this);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(ImpactCameraShakeClass, this, MeshRoot.WorldLocation, InnerRadius, OuterRadius, 1.0, Scale);

		HideIcicle();
		bShouldLerpLocation = false;

		CollisionCheck(IcicleImpactHitRadius);
		BP_IcicleHitGround();
	}

	UFUNCTION(BlueprintEvent)
	void BP_IcicleLerpingTowardsGround(float Alpha)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_IcicleHitGround()
	{
	}

	UFUNCTION()
	void HideIcicle()
	{
		HideIcicleMeshTimelike.PlayFromStart();
	}

	void ResetIcicle()
	{
		IcicleMesh.SetHiddenInGame(true);
		LerpLocationDurationTimer = 0;
		MovementRoot.SetRelativeLocation(MovementRootStartLocation);
		IcicleMesh.SetRelativeLocation(IcicleMeshStartingLocation);
	}

	void CollisionCheck(float SphereRadius)
	{
		for(auto Player : Game::Players)
		{
			FHazeShapeSettings CapsuleSettings = FHazeShapeSettings::MakeCapsule(Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.CapsuleHalfHeight);
			float DistToCapsule = CapsuleSettings.GetWorldDistanceToShape(Player.CapsuleComponent.WorldTransform, ActorLocation);

			if(DistToCapsule < SphereRadius)
			{
				FVector KnockdownCross = MeshRoot.RightVector.CrossProduct(FVector(0, 0, 1));
				float Multiplier;
				if(MeshRoot.RelativeRotation.Pitch > 0)
					Multiplier = 1;
				else
					Multiplier = -1;
				
				FPlayerDeathDamageParams DeathParams;
				DeathParams.ImpactDirection = KnockdownCross * Multiplier;
				Player.DamagePlayerHealth(0.25, DeathParams, FallingIcicleDamageEffect, FallingIcicleDeathEffect);

				Player.ApplyKnockdown(KnockdownCross * (Multiplier * 500), 0.75, Cooldown = 2);
			}
		}

		if(bDebugDrawDamageSpheres)
		{
			Debug::DrawDebugSphere(ActorLocation, SphereRadius, Duration = 2, LineColor = FLinearColor::Red);
		}
	}
};

class UTundraBossFallingIcicleEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFalling() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitGround() {}
};