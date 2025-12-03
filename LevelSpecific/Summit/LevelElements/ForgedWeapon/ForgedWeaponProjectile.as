
event void FOnForgeProjectileDestroyed(AForgedWeaponProjectile Projectile);

class AForgedWeaponProjectile : AHazeActor
{
	FOnForgeProjectileDestroyed OnProjectileDestroyed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;


	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ExplosionSystem;
	default ExplosionSystem.SetAutoActivate(false);


	UPROPERTY(DefaultComponent)
	UAcidFruitExplosionComponent AcidBombExplosionComp;

	
	float Gravity;
	FVector Velocity;
	AActor OurSpawner;


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Velocity -= FVector(0.0, 0.0, Gravity * DeltaSeconds);
		ActorLocation += Velocity * DeltaSeconds;


		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.IgnoreActor(this);
		TraceSettings.IgnoreActor(OurSpawner);

		TraceSettings.UseSphereShape(250.0);
		FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + Velocity.GetSafeNormal());

		if(Hit.bBlockingHit)
		{
			MeshComp.SetHiddenInGame(true);
			AcidBombExplosionComp.OnExplode();

			OnProjectileDestroyed.Broadcast(this);
			
		}
	}

}