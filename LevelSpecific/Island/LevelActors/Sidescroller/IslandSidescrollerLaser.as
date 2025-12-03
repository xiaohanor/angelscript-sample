event void FIslandSidescrollerLaserEvent(AIslandSidescrollerLaser Laser);

struct FIslandSidescrollerLaserEffectParams
{
	UPROPERTY(BlueprintReadOnly)
	float LaserHealth;
}

UCLASS(Abstract)
class AIslandSidescrollerLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LaserEmitter;

	UPROPERTY(DefaultComponent, Attach = LaserEmitter)
	UIslandRedBlueImpactCounterResponseComponent RedBlueImpactResponseComp;
	default RedBlueImpactResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UIslandRedBlueTargetableComponent Targetable;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LaserMesh;
	default LaserMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(EditAnywhere)
	EHazePlayer UsableByPlayer;

	UPROPERTY(EditAnywhere)
	bool bRotate = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bRotate", EditConditionHides))
	float RotationRate = 7.0;

	UPROPERTY(EditAnywhere)
	bool bLaserActive = true;

	UPROPERTY(EditAnywhere)
	float LaserMaxHP = 10.0;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffect")
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	FIslandSidescrollerLaserEvent OnDestroyedLaser;

	UPROPERTY()
	FIslandSidescrollerLaserEvent OnImpactLaser;

	const float MaxLaserLength = 3000.0;
	private float CurrentHP;
	private FQuat StartRotation;
	private bool bIsDestroyed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentHP = LaserMaxHP;
		StartRotation = ActorQuat;

		if(!bLaserActive)
			DeactivateLaser();

		RedBlueImpactResponseComp.OnImpactEvent.AddUFunction(this, n"OnImpact");
		RedBlueImpactResponseComp.BlockImpactForPlayer(Game::GetOtherPlayer(UsableByPlayer), n"InitialBlock");
		Targetable.DisableForPlayer(Game::GetOtherPlayer(UsableByPlayer), n"InitialBlock");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bLaserActive && bRotate)
		{
			ActorQuat = FQuat(FVector::LeftVector, Math::DegreesToRadians(RotationRate * DeltaTime)) * ActorQuat;
		}

		if(bLaserActive)
			Trace();
	}

	UFUNCTION()
	void ActivateLaser()
	{
		SetActorTickEnabled(true);
		LaserMesh.SetHiddenInGame(false);
		bLaserActive = true;
		CurrentHP = LaserMaxHP;
		Targetable.Enable(this);

		if(bIsDestroyed)
		{
			RemoveActorDisable(this);
			ActorQuat = StartRotation;
		}
	}

	UFUNCTION()
	void DeactivateLaser()
	{
		LaserMesh.SetHiddenInGame(true);
		Targetable.Disable(this);
		bLaserActive = false;
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void DestroyLaser()
	{
		UIslandSidescrollerLaserEffectHandler::Trigger_OnDestroy(this);
		AddActorDisable(this);
		bIsDestroyed = true;
		BP_OnDestroy();
		OnDestroyedLaser.Broadcast(this);
	}

	UFUNCTION(BlueprintPure)
	bool IsDestroyed() const
	{
		return bIsDestroyed;
	}

	UFUNCTION()
	private void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if(!bLaserActive)
			return;

		CurrentHP -= Data.ImpactDamageMultiplier;
		if(CurrentHP <= 0.0)
		{
			DestroyLaser();
		}
		else
		{
			BP_OnImpact();
			OnImpactLaser.Broadcast(this);

			FIslandSidescrollerLaserEffectParams Params;
			Params.LaserHealth = CurrentHP;
			UIslandSidescrollerLaserEffectHandler::Trigger_OnImpact(this, Params);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnImpact() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDestroy() {}

	private void Trace()
	{
		FBox CylinderActorBounds = LaserMesh.GetBoundingBoxRelativeToOwner();
		FBox CylinderLocalBounds = LaserMesh.GetComponentLocalBoundingBox();

		TArray<FVector> Origins;
		Origins.Add(LaserMesh.WorldLocation + LaserMesh.ForwardVector * CylinderActorBounds.Extent.X * ActorScale3D.X);
		Origins.Add(LaserMesh.WorldLocation - LaserMesh.ForwardVector * CylinderActorBounds.Extent.X * ActorScale3D.X);

		FHazeTraceSettings Trace = Trace::InitProfile(n"BlockAllDynamic");
		Trace.IgnoreActor(this);
		Trace.UseLine();

		float LongestDistance = 0.0;
		for(FVector Origin : Origins)
		{
			FHitResultArray Hits = Trace.QueryTraceMulti(Origin, Origin + LaserMesh.UpVector * MaxLaserLength);
			for(FHitResult Hit : Hits.BlockHits)
			{
				auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				if(Player != nullptr)
				{
					Player.KillPlayer(FPlayerDeathDamageParams((ActorForwardVector), 1.0), DeathEffect);
					continue;
				}

				float Dist = Hit.Distance;
				if(!Hit.bBlockingHit)
					Dist = MaxLaserLength;

				if(Dist > LongestDistance)
					LongestDistance = Dist;

				break;
			}

			if(!Hits.bHasBlockingHit)
				LongestDistance = MaxLaserLength;
		}

		LaserMesh.RelativeScale3D = FVector(LaserMesh.RelativeScale3D.X, LaserMesh.RelativeScale3D.Y, LongestDistance / (CylinderLocalBounds.Extent.Z * 2.0));
	}
}

UCLASS(Abstract)
class UIslandSidescrollerLaserEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FIslandSidescrollerLaserEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroy() {}
}