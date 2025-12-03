UCLASS(Abstract)
class AVortexSandFishBreakablePillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	USandFishResponseComponent ResponseComp;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem CollisionFX;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnSandFishCollision.AddUFunction(this, n"OnSandFishCollision");
		Desert::GetManager().Pillars.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Desert::GetManager().Pillars.RemoveSingle(this);
	}

	UFUNCTION()
	private void OnSandFishCollision(AHazeActor SandfishActor, FVector ImpactPoint)
	{
		if(CollisionFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(CollisionFX, ImpactPoint, FRotator::ZeroRotator, FVector(100, 100, 100));

		AVortexSandFish SandFish = Cast<AVortexSandFish>(SandfishActor);
		if(SandFish != nullptr)
		{
			// auto HealthComp = USandFishHealthComponent::Get(SandFish);
			// if(HealthComp.IsAlive())
			// {
			// 	FSandfishTakeDamageData DamageData;
			// 	DamageData.Damage = 30;
			// 	DamageData.Instigator = this;
			// 	HealthComp.TakeDamage(DamageData);
			// }

			DestroyActor();
			return;
		}
	}
}