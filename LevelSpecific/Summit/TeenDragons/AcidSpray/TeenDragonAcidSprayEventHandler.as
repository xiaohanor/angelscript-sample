struct FTeenDragonAcidProjectileEventParams
{
	UPROPERTY()
	FVector LaunchLocation;
	UPROPERTY()
	FVector LaunchDirection;

	// For audio business
	UPROPERTY()
	FVector LaunchTarget;

	UPROPERTY()
	bool bStreamBlockingHit = false;
};

struct FTeenDragonAcidProjectileImpactParams
{
	UPROPERTY()
	USceneComponent ImpactComponent;
	UPROPERTY()
	FVector ImpactLocation;
	UPROPERTY()
	FVector ImpactNormal;
};

struct FTeenDragonAcidTrajectoryParams
{
	UPROPERTY()
	FVector StartLocation;
	UPROPERTY()
	FVector EndLocation;
	UPROPERTY()
	FVector Direction;
	UPROPERTY()
	float HorizontalSpeed;
	UPROPERTY()
	float Gravity;
}

UCLASS(Abstract)
class UTeenDragonAcidSprayEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	UHazeCharacterSkeletalMeshComponent Mesh;

	UPROPERTY(BlueprintReadOnly)
	UNiagaraComponent SprayEffect;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		auto DragonComp = UPlayerTeenDragonComponent::Get(Owner);
		check(DragonComp != nullptr);

		Mesh = DragonComp.DragonMesh;
		SprayEffect = UNiagaraComponent::Get(Mesh.Owner);
	}

	UFUNCTION(BlueprintPure)
	ATeenDragon FindTeenDragon() const
	{
		if(Owner == nullptr)
			return nullptr;

		TArray<AActor> AttachedActors;
		Owner.GetAttachedActors(AttachedActors, true, false);


		for(auto IterActor : AttachedActors)
		{
			if(IterActor == nullptr || IterActor.IsActorBeingDestroyed())
				continue;

			ATeenDragon PotentialDragon = Cast<ATeenDragon>(IterActor);
			if(PotentialDragon != nullptr)
			{
				return PotentialDragon;
			}
		}

		return nullptr;
	}

	UFUNCTION()
	bool FindAndActivateImpactEffectOnMoveable(
		USceneComponent InTargetComponent,
		FVector ImpactLocation, 
		FVector ImpactNormal, 
		UNiagaraSystem VFXAsset
	)
	{
		if(InTargetComponent == nullptr)
			return false;

		if(VFXAsset == nullptr)
			return false;

		if(InTargetComponent.Mobility != EComponentMobility::Movable)
			return false;

		const FName AcidNameTag = n"AcidImpactComp";

		UNiagaraComponent ImpactComp = UNiagaraComponent::Get(InTargetComponent.Owner, AcidNameTag);

		if(ImpactComp == nullptr)
		{
			// create a new one once, and then re-use it upon successive hits.
			ImpactComp = UNiagaraComponent::Create(InTargetComponent.Owner, AcidNameTag);
			ImpactComp.SetAutoDestroy(false);
			ImpactComp.SetAsset(VFXAsset);
			ImpactComp.ReinitializeSystem();
			// PrintToScreen("Created a new one on " + InTargetComponent.Owner, 3.0, FLinearColor::Yellow);
		}

		ImpactComp.SetWorldLocation(ImpactLocation);
		ImpactComp.SetWorldRotation(FQuat::MakeFromX(ImpactNormal));

		// this will trigger the emitters to burst out new particles, 
		// while still keeping the old ones alive
		ImpactComp.Activate(true);

		return true;
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidProjectileStartFiring() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidProjectileFired(FTeenDragonAcidProjectileEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidProjectileStopFiring() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidSprayTrajectory(FTeenDragonAcidTrajectoryParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AcidProjectileImpact(FTeenDragonAcidProjectileImpactParams Params) {}
};