UCLASS(Abstract)
class ASummitCrystalSkullMine : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 0.0;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	USummitCrystalSkullSettings Settings;
	bool bExploded = false;
	FVector RotationAxis;
	float Angle = 0.0;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunchMine");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		RotationAxis = Math::GetRandomPointInSphere();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bExploded = false;
	}

	UFUNCTION()
	private void OnLaunchMine(UBasicAIProjectileComponent Projectile)
	{
		Settings = USummitCrystalSkullSettings::GetSettings(ProjectileComp.Launcher);
		USummitCrystalSkullMineEventHandler::Trigger_OnLaunch(this);
	}

	UFUNCTION(DevFunction)
	void TestLaunch()
	{
		ProjectileComp.Launcher = Game::Mio;
		ProjectileComp.Launch(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) 
	{
		if (bExploded)
			return;
		
		if (HasControl() && (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > Settings.MineSelfDestructDuration))
		{
			CrumbExplode();
			return;
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.HasControl() && Player.ActorLocation.IsWithinDist(ActorLocation, Settings.MineTriggerRadius))
			{
				CrumbExplode();
				return;
			}
		}

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		if (HasControl() && Hit.bBlockingHit)
		{
			CrumbExplode();
			return;
		}

		// Rotate mine
		Angle += PI * 2.0 * 1.0 * DeltaTime;
		SetActorRotation(FQuat(RotationAxis, Angle));
	}

	UFUNCTION(CrumbFunction)
	void CrumbExplode()
	{
		if (bExploded)
			return; // Only explode once per respawn (we can explode from either side in network)

		ProjectileComp.Expire();
		USummitCrystalSkullMineEventHandler::Trigger_OnExplode(this);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			float DamageFactor = Damage::GetRadialDamageFactor(Player.ActorLocation, ActorLocation, Settings.MineDamageRadius, Settings.MineDamageInnerRadius);
			if (DamageFactor > 0.0)
				Player.DamagePlayerHealth(Settings.MineDamage * DamageFactor);
		}	
	}
}
