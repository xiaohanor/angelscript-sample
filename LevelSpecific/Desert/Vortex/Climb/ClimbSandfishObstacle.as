class AClimbSandfishObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	USandFishResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnSandFishCollision.AddUFunction(this, n"OnSandfishCollision");
	}

	UFUNCTION()
	private void OnSandfishCollision(AHazeActor SandfishActor, FVector ImpactPoint)
	{
		// auto HealthComp = USandFishHealthComponent::Get(SandfishActor);
		// FSandfishTakeDamageData DamageData;
		// DamageData.Damage = 10;
		// DamageData.Instigator = this;
		// HealthComp.TakeDamage(DamageData);

		DestroyActor();
		Smash();
	}


	UFUNCTION(BlueprintEvent)
	void Smash()
	{

	}


};