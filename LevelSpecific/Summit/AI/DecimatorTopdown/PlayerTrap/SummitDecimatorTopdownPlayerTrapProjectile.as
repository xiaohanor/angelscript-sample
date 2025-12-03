class USummitDecimatorTopdownPlayerTrapLauncher : UBasicAIProjectileLauncherComponent
{
}

UCLASS(Abstract)
class ASummitDecimatorTopdownPlayerTrapProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	USummitDecimatorTopdownPlayerTrapProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;
	
	UBasicAITargetingComponent OwnerTargetComp;

	
	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		if (Hit.bBlockingHit)
		{
			if (Hit.Actor.IsA(AHazePlayerCharacter))
			{
				AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);

				// FSummitDecimatorTopdownPlayerTrapProjectileOnHitPlayerEventData Params;
				// Params.Location = Hit.Location;
				// Params.ImpactDirection = Hit.ImpactNormal * -1.0;
				// if (Params.ImpactDirection.Size2D() < SMALL_NUMBER)
				// 	Params.ImpactDirection = HitPlayer.ActorForwardVector * -1.0;
				// Params.HitPlayer = HitPlayer;
			}
			else
			{
				// FIslandShieldotronMortarProjectileOnHitEventData Params;
				// Params.Location = Hit.Location;
				// Params.ImpactNormal = Hit.ImpactNormal;
				// FSummitDecimatorTopdownPlayerTrapProjectileOnHitPlayerEventData::Trigger_OnHit(this, Params);				
			}
			Expire();
		}	
	}
	
	void Expire()
	{
		//FSummitDecimatorTopdownPlayerTrapProjectileOnHitPlayerEventData::Trigger_OnExpire(this);
		ProjectileComp.Expire();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbLocalImpact(FHitResult Hit)
	{	
		ProjectileComp.Impact(Hit);
	}


}
