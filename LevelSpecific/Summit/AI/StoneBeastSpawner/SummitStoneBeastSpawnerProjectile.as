class ASummitStoneBeastSpawnerProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default ProjectileComp.TraceType = ETraceTypeQuery::WorldGeometry;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UDecalComponent DecalComp;
	default DecalComp.SetHiddenInGame(true);
	default DecalComp.SetWorldScale3D(FVector(0.5));	

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default	ProjectileComp.Friction = 0.0;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	USummitStoneBeastSpawnerSettings Settings;
	AHazeActor Spawn;
	bool bLaunched = false;
	bool bLanded = false;
	float SpawnTime;

	void LaunchSpawn(AHazeActor ActorToSpawn, FVector Destination)
	{
		Settings = USummitStoneBeastSpawnerSettings::GetSettings(ProjectileComp.Launcher);
		Spawn = ActorToSpawn;
		bLaunched = true;
		bLanded = false;
		SpawnTime = Time::GameTimeSeconds + Settings.SpawnProjectileMaxDuration; 
		ProjectileComp.Gravity = Settings.SpawnProjectileGravity;

		DecalComp.DetachFromParent();
		DecalComp.WorldLocation = Destination + FVector(0,0,-40);
		DecalComp.WorldRotation = FVector::UpVector.Rotation();
		DecalComp.SetHiddenInGame(false);

		USummitStoneBeastSpawnerProjectileEffectHandler::Trigger_OnLaunch(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bLaunched)
			return;

		if ((Time::GameTimeSeconds > SpawnTime) && HasControl())
		{
			CrumbSpawn(ActorLocation);
			return;
		}

		if (bLanded)
			return;

		ActorRotation = FQuat::Slerp(ActorQuat, ProjectileComp.Velocity.ToOrientationQuat(), DeltaTime * 4.0).Rotator();		

		bool bRising = (ProjectileComp.Velocity.Z > 0.0);		
		FHitResult Obstruction;
		ActorLocation = ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Obstruction, bRising);
		if (Obstruction.bBlockingHit)
		{
			bLanded = true;
			SpawnTime = Time::GameTimeSeconds + Settings.SpawnProjectileLandDuration;	
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (!Player.HasControl())
					continue;
				if (!Player.ActorLocation.IsWithinDist(ActorLocation, Settings.SpawnProjectileBlastRadius))
					continue;
				Player.DamagePlayerHealth(Settings.SpawnProjectileDamage);
				if (Settings.SpawnProjectileKnockdownDuration > 0.0)
				{
					FVector Away = (Player.ActorLocation - ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
					Player.ApplyKnockdown(Away * Settings.SpawnProjectileKnockdownDistance, Settings.SpawnProjectileKnockdownDuration);
				}
			}
			DecalComp.SetHiddenInGame(true);
			USummitStoneBeastSpawnerProjectileEffectHandler::Trigger_OnLand(this);
		}	
	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawn(FVector Location)
	{
		USummitStoneBeastSpawnerProjectileEffectHandler::Trigger_OnSpawn(this);
		ProjectileComp.Expire();
		bLaunched = false;
		bLanded = false;

		// Teleport again in case spawn location moved due to obstructons
		Spawn.TeleportActor(Location, ProjectileComp.Launcher.ActorRotation, this);
		Spawn.RemoveActorDisable(ProjectileComp.Launcher);
	}
}

UCLASS(Abstract)
class USummitStoneBeastSpawnerProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawn(){}
};