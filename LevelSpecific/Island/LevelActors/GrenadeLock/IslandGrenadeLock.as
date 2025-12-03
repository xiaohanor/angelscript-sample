event void FIslandGrenadeLockEventSelfParam(AIslandGrenadeLock Lock);

class AIslandGrenadeLock : AHazeActor
{
	access ReadOnly = private, * (readonly);

	UPROPERTY()
	FIslandGrenadeLockEventSelfParam OnActivated;

	UPROPERTY()
	FIslandGrenadeLockEventSelfParam OnDeactivated;

	UPROPERTY()
	FIslandGrenadeLockEventSelfParam OnCompleted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	
	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent ShootMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent MovingRootComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueTargetableComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeLidComp;

    UPROPERTY(DefaultComponent)
	USceneComponent ActivatedLocation;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueReflectComponent ReflectComp;

	UPROPERTY(DefaultComponent)
	UIslandForceFieldStateComponent ForceFieldStateComp;
	default ForceFieldStateComp.bForceFieldIsOnEnemy = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(BlueprintReadOnly)
	UMaterialInterface SourceShieldMaterial;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	FLinearColor RedForceFieldColor = FLinearColor(10, 0.025, 0, 1);

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	FLinearColor BlueForceFieldColor = FLinearColor(0, 2, 4, 1);

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	UPROPERTY()
	UMaterialInterface ActiveMaterial;

	UPROPERTY()
	UMaterialInterface CompletedMaterial;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY(EditAnywhere)
	float TimeUntilReset = 3;

	UPROPERTY(EditAnywhere)
	FVector RelativeConnectedLineOffset = FVector(25.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere, Category = "Visuals")
	bool EdgeGlowUseVertexColor = false;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	float Tiling = 1.0;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	float Intensity = 1.0;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	float Fresnel = 1.0;

	UPROPERTY(EditAnywhere, Category = "Visuals")
	float DepthFade = 1.0;
	
	const float AnimationDuration = 1;

	FHazeTimeLike MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	AIslandGrenadeLockListener GrenadeListener;

	access:ReadOnly bool bFinishedAnimation;
	access:ReadOnly bool bActivated;
	access:ReadOnly bool bCompleted;
	access:ReadOnly bool bActivatedByGrenade;
	access:ReadOnly int ActivatedByGrenadeExplosionIndex;

	private FVector StartLocation;
    private FVector EndLocation;
	private FRotator StartRotationLeft;
	private FRotator EndRotationLeft;
	private FRotator StartRotationRight;
	private FRotator EndRotationRight;
	private float TimeUntilResetTimer;
	
	private TArray<AIslandGrenadeLock> ConnectedLocks;

	bool bShouldRotate = true;

	FRotator RotationSpeed = FRotator(0,0, 80);

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			ShootMesh.SetMaterial(1, MioMaterial);
			ShootMesh.SetMaterial(3, MioMaterial);
		}
		else
		{
			ShootMesh.SetMaterial(1, ZoeMaterial);
			ShootMesh.SetMaterial(3, ZoeMaterial);
		}
	}

	UFUNCTION()
	void SetGrenadeShieldMaterialParameters(UStaticMeshComponent GrenadeShield)
	{
		GrenadeShield.SetScalarParameterValueOnMaterials(FName(n"EdgeGlowVertexColor"), EdgeGlowUseVertexColor ? 1 : 0);
		GrenadeShield.SetScalarParameterValueOnMaterials(FName(n"Tiling"), Tiling);
		GrenadeShield.SetScalarParameterValueOnMaterials(FName(n"Intensity"), Intensity);
		GrenadeShield.SetScalarParameterValueOnMaterials(FName(n"Fresnel"), Fresnel);
		GrenadeShield.SetScalarParameterValueOnMaterials(FName(n"DepthFadeMultiplier"), DepthFade);
	
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			GrenadeShield.SetMaterial(1, MioMaterial);
		}
		else
		{
			GrenadeShield.SetMaterial(1, ZoeMaterial);
		}
	
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceFieldStateComp.SetCurrentForceFieldType(IslandRedBlueWeapon::GetPlayerColor(Game::GetPlayer(UsableByPlayer)) == EIslandRedBlueWeaponType::Red ? EIslandForceFieldType::Red : EIslandForceFieldType::Blue);
		GrenadeResponseComp.OnDetonated.AddUFunction(this, n"OnDetonated");

		TimeUntilResetTimer = TimeUntilReset;

        StartLocation = MovingRootComp.GetRelativeLocation();
        EndLocation = ActivatedLocation.GetRelativeLocation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"MoveAnimationOnUpdate");
		MoveAnimation.BindFinished(this, n"MoveAnimationOnFinished");

		if(UsableByPlayer == EHazePlayer::Mio)
		{
			GrenadeResponseComp.bTriggerForRedPlayer = true;
			GrenadeResponseComp.bTriggerForBluePlayer = false;
		}

		if(UsableByPlayer == EHazePlayer::Zoe)
		{
			GrenadeResponseComp.bTriggerForRedPlayer = false;
			GrenadeResponseComp.bTriggerForBluePlayer = true;
			RotationSpeed = RotationSpeed.Inverse;
		}

		ReflectComp.OnBulletReflect.AddUFunction(this, n"OnBulletReflect");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bShouldRotate)
		{
			float ClosestPlayerDistance = Game::GetDistanceFromLocationToClosestPlayer(ActorLocation);
			if (ClosestPlayerDistance < 7500.0)
			{
				RotateRoot.AddLocalRotation(RotationSpeed * (DeltaSeconds * Math::GetMappedRangeValueClamped(
					FVector2D(7500, 6500),
					FVector2D(0, 1),
					ClosestPlayerDistance
				)));
			}
		}

		//DrawLinesToConnectedLocks();

		if(!bActivated)
			return;

		if(bCompleted)
			return;

		TimeUntilResetTimer -= DeltaSeconds;
		if (TimeUntilResetTimer <= 0)
		{
			DeactivateLock();
		}
	}

	// void DrawLinesToConnectedLocks()
	// {
	// 	if(!bActivated)
	// 		return;

	// 	if(bCompleted)
	// 		return;

	// 	for(int i = ConnectedLocks.Num() - 1; i >= 0; --i)
	// 	{
	// 		// Connected lock has been deactivated so don't draw to it anymore!
	// 		if(!ConnectedLocks[i].bActivated)
	// 		{
	// 			ConnectedLocks.RemoveAt(i);
	// 			continue;
	// 		}

	// 		FVector Origin = GetConnectedLineWorldLocation();
	// 		FVector Destination = ConnectedLocks[i].GetConnectedLineWorldLocation();
	// 		Debug::DrawDebugLine(Origin, Destination, UsableByPlayer == EHazePlayer::Mio ? FLinearColor::Red : FLinearColor::Blue, 5.0);
	// 	}
	// }

	FVector GetConnectedLineWorldLocation()
	{
		return ActorLocation + ActorTransform.TransformVectorNoScale(RelativeConnectedLineOffset);
	}

	UFUNCTION()
	private void OnDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	{
		if(bActivated)
			return;

		if (Data.GrenadeOwner != Game::GetPlayer(UsableByPlayer))
			return;

		if(bCompleted)
			return;

		GrenadeLidComp.SetHiddenInGame(true, true);

		bActivatedByGrenade = true;
		ActivatedByGrenadeExplosionIndex = Data.ExplosionIndex;
		ActivateLock();
	}

	private void StartAnimation()
	{
        MoveAnimation.Play();
	}

	UFUNCTION()
	private void MoveAnimationOnUpdate(float Alpha)
	{
		MovingRootComp.SetRelativeLocation(Math::Lerp(StartLocation, EndLocation, Alpha));
	}

	UFUNCTION()
	private void MoveAnimationOnFinished()
	{
		bFinishedAnimation = !MoveAnimation.IsReversed();
	}

	void ActivateLock()
	{
		if(bActivated)
			return;

		bShouldRotate = false;


		if(GrenadeListener != nullptr)
		{
			TArray<AIslandGrenadeLock> ActiveChildren = GrenadeListener.GetActiveChildren();

			for(int i = 0; i < ActiveChildren.Num(); i++)
			{
				if(ActiveChildren[i].UsableByPlayer != UsableByPlayer)
					continue;

				if(bActivatedByGrenade && ActiveChildren[i].bActivatedByGrenade &&
					ActiveChildren[i].ActivatedByGrenadeExplosionIndex != ActivatedByGrenadeExplosionIndex)
					continue;
				
				ConnectedLocks.Add(ActiveChildren[i]);
			}
		}

		StartAnimation();
		BP_OnActivated();
		UIslandGrenadeLockEffectHandler::Trigger_OnLockActivated(this);
		UIslandGrenadeLockEffectHandler::Trigger_OnForceFieldDestroyed(this);
		OnActivated.Broadcast(this);
		bActivated = true;
	}

	void DeactivateLock()
	{
		if(GrenadeListener != nullptr && GrenadeListener.bCompleted)
			return;

		bShouldRotate = true;
		bActivated = false;

		GrenadeLidComp.SetHiddenInGame(false, true);

		MoveAnimation.Reverse();
		bCompleted = false;
		bActivatedByGrenade = false;
		ConnectedLocks.Empty();
		TimeUntilResetTimer = TimeUntilReset;
		BP_OnDeactivated();
		UIslandGrenadeLockEffectHandler::Trigger_OnLockDeactivated(this);
		UIslandGrenadeLockEffectHandler::Trigger_OnForceFieldRegenerated(this);
		OnDeactivated.Broadcast(this);
	}

	void SetCompleted()
	{
		if(!bActivated)
		{
			bActivatedByGrenade = true;
			ActivateLock();
		}

		bShouldRotate = false;
		bCompleted = true;
		ShootMesh.SetMaterial(1, CompletedMaterial);
		ShootMesh.SetMaterial(3, CompletedMaterial);
		BP_OnCompleted();
		UIslandGrenadeLockEffectHandler::Trigger_OnLockCompleted(this);
		OnCompleted.Broadcast(this);
	}

	UFUNCTION()
	private void OnBulletReflect(AIslandRedBlueWeaponBullet Bullet, AActor Actor, FVector ReflectImpactPoint)
	{
		FIslandGrenadeLockReflectEffectParams Params;
		Params.ReflectImpactPoint = ReflectImpactPoint;
		UIslandGrenadeLockEffectHandler::Trigger_OnBulletReflectOnForceField(this, Params);
	}

	bool IsForceFieldDeactivated()
	{
		return bActivated;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnCompleted() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivated() {}
}

struct FIslandGrenadeLockReflectEffectParams
{
	UPROPERTY()
	FVector ReflectImpactPoint;
}

UCLASS(Abstract)
class UIslandGrenadeLockEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLockActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLockDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLockCompleted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldDestroyed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldRegenerated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBulletReflectOnForceField(FIslandGrenadeLockReflectEffectParams Params) {}
}