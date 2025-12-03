event void FOnCrystalJungleDestroyed();

class AStoneBeastCrystalJungle : AHazeActor
{
	UPROPERTY()
	FOnCrystalJungleDestroyed OnCrystalJungleDestroyed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;	
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default Collision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 2500.0;
	default DisableComp.bActorIsVisualOnly = true;

	UPROPERTY(DefaultComponent)
	UDragonSwordCombatResponseComponent ResponseComp;
	default ResponseComp.bCanTakeDamageFromOuterRadius = false;
	default ResponseComp.ResponseDetailLevel = EDragonSwordResponseDetailLevel::None;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent CallBackComp;
	
	UPROPERTY(EditDefaultsOnly)
	TArray<UStaticMesh> CrystalMeshes;

	UPROPERTY(EditAnywhere)
	int MaxHits = 1;

	UPROPERTY(EditAnywhere)
	AStoneBeastCrystalJungleManager Manager;

	TArray<AHazePlayerCharacter> Players;

	float MinScale = 0.85;
	float MaxScale = 1.15;

	int CurrentHits;
	FTransform TransformBeforeDisable;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHitNoData.AddUFunction(this, n"OnHit");
		if (Manager != nullptr)
		{
			Manager.Crystals.AddUnique(this);
			if (Manager.bStartDisabled)
				AddActorDisable(Manager);
		}

		CallBackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpactedByPlayer");
	}

	UFUNCTION(CallInEditor)
	void RandomizeScale()
	{
		ActorScale3D = FVector(Math::RandRange(MinScale, MaxScale));
	}

	UFUNCTION(CallInEditor)
	void RandomizeMesh()
	{
		MeshComp.SetStaticMesh(CrystalMeshes[Math::RandRange(0, CrystalMeshes.Num() - 1)]);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if (Root.AttachParent != nullptr)
		{
			// Stop moving with the parent when disabled
			TransformBeforeDisable = GetActorRelativeTransform();

			FTransform PrevWorldTransform = GetActorTransform();
			Root.SetAbsoluteAndUpdateTransform(true, true, true, PrevWorldTransform);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if (Root.AttachParent != nullptr)
		{
			// Start moving with the parent again
			Root.SetAbsolute(false, false, false);
			Root.SetRelativeTransform(TransformBeforeDisable);
		}
	}

	UFUNCTION()
	private void OnHit()
	{
		CurrentHits++;

		// if (CurrentHits < MaxHits)
		// {
		// 	UStoneBeastCrysatlJungleEffectHandler::Trigger_Hit(this, FOnStoneBeastCrystalJungleHitParams(HitData.ImpactPoint, HitData.ImpactNormal));
		// 	return;
		// }

		UStoneBeastCrysatlJungleEffectHandler::Trigger_Destroyed(this, FOnStoneBeastCrystalJungleParams(ActorLocation + FVector(0,0,120.0)));
		SetEndState();
		OnCrystalJungleDestroyed.Broadcast();
	}

	UFUNCTION()
	private void OnGroundImpactedByPlayer(AHazePlayerCharacter Player)
	{
		Player.KillPlayer(FPlayerDeathDamageParams(FVector::UpVector, 5.0));
	}

	UFUNCTION()
	private void OnAnyImpactByPlayer(AHazePlayerCharacter Player)
	{
		Players.AddUnique(Player);
	}

	UFUNCTION()
	private void OnAnyImpactByPlayerEnded(AHazePlayerCharacter Player)
	{
		Players.Remove(Player);
	}

	void SetEndState()
	{
		Collision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		AddActorDisable(this);
	}

	UFUNCTION()
	void UpdateAutoDisableState()
	{
		DisableComp.UpdateAutoDisable();
	}
}