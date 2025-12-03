class ASkylineFlyingCarGunnerProjectile : ABasicAIProjectile
{
	UPROPERTY(DefaultComponent)
	UBasicAIHomingProjectileComponent HomingProjectileComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION()
	private void OnReset()
	{
		HomingProjectileComponent.Target = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HomingProjectileComponent.Target != nullptr)
		{
			FVector RelativeVelocity = ProjectileComp.Velocity - HomingProjectileComponent.Target.ActorVelocity;

			FVector ToTarget = (HomingProjectileComponent.Target.ActorLocation - ActorLocation).GetSafeNormal();

			ProjectileComp.Velocity -= RelativeVelocity;
			ProjectileComp.Velocity += ToTarget * RelativeVelocity.Size();
		}

		Super::Tick(DeltaTime);
	}
}