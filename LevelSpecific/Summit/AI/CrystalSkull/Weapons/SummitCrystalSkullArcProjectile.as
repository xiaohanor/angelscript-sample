UCLASS(Abstract)
class ASummitCrystalSkullArcProjectile : AHazeActor
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

	UPROPERTY()
	float RollSpeed = 5.0;

	UPROPERTY()
	float YawSpeed = 0.0;

	UBasicAIHealthComponent LauncherHealthComp = nullptr;
	USummitCrystalSkullSettings Settings;
	bool bTriggered = false;
	float AttackTime;
	FQuat TelegraphingRotation;
	float Angle = 0.0;
	float Roll = 0.0;
	float LaunchYawOffset = 0.0;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bTriggered = false;
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		Settings = USummitCrystalSkullSettings::GetSettings(ProjectileComp.Launcher);
		USummitCrystalSkullProjectileEventHandler::Trigger_OnLaunch(this);
		AttackTime = Time::GameTimeSeconds + Settings.ArcAttackTelegraphDuration;
		AttachToActor(ProjectileComp.Launcher, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		LauncherHealthComp = UBasicAIHealthComponent::GetOrCreate(ProjectileComp.Launcher); 
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) 
	{
		if (bTriggered)
			return;

		// Roll projectile
		FRotator NewRot = ActorRotation;
		Roll = FRotator::NormalizeAxis(Roll + DeltaTime * 360.0 * RollSpeed);
		NewRot.Roll = Roll;
		
		FRotator MeshRot = Mesh.RelativeRotation;
		MeshRot.Yaw += DeltaTime * 360.0 * YawSpeed;
		Mesh.RelativeRotation = MeshRot;

		if (Time::GameTimeSeconds < AttackTime)
		{
			// Just roll in place
			TelegraphingRotation = FQuat(NewRot);
			SetActorRotation(NewRot);

			// Autodestruct if launcher dies
			if ((LauncherHealthComp != nullptr) && LauncherHealthComp.IsDead())
			{
				LocalTrigger();
				return;
			}
			return;
		}
		
		// We're off!
		if (AttachParentActor != nullptr)
		{
			DetachFromActor();

			if (ProjectileComp.Target != nullptr)
			{
				// Launch towards target, maintaining yaw spread and speed			
				FRotator LaunchRot = (ProjectileComp.Target.ActorCenterLocation - ActorCenterLocation).Rotation();
				LaunchRot.Yaw += LaunchYawOffset;
				LaunchRot.Pitch += Math::RandRange(-1.0, 1.0) * Settings.ArcAttackScatterPitch;
				ProjectileComp.Velocity = LaunchRot.Vector() * Settings.ArcAttackProjectileSpeed;
			}
		}

		// Slerp pitch and yaw to align with velocity
		float Alpha = Math::EaseInOut(0.0, 1.0, Math::Min(1.0, Time::GetGameTimeSince(AttackTime) * 1.5), 3.0);
		FRotator SlerpedRot = FQuat::Slerp(TelegraphingRotation, ProjectileComp.Velocity.ToOrientationQuat(), Alpha).Rotator();		
		NewRot.Yaw = SlerpedRot.Yaw;
		NewRot.Pitch = SlerpedRot.Pitch;
		SetActorRotation(NewRot);

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > Settings.ArcProjectileLifetime)
		{
			LocalTrigger();
			return;
		}

		// Trigger if any player is within a sphere slice near projectile
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.HasControl() && 
				(Math::Abs(Player.ActorLocation.Z - ActorLocation.Z) < Settings.ArcProjectileTriggerHeight) && 
				Player.ActorLocation.IsWithinDist(ActorLocation, Settings.ArcProjectileTriggerRadius))
			{
				// Note that we do not network this; projectiles might be desynced on each side and 
				// they are numerous enough that this will likely not be noticed.
				// If we do want to network triggering and do not want to network spawn etc, we'd need to do it through launcher.
				LocalTrigger();
				return;
			}
		}

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		if (Hit.bBlockingHit)
		{
			LocalTrigger();
			return;
		}
	}

	void LocalTrigger()
	{
		if (bTriggered)
			return; // Only trigger once per respawn (we can trigger from either side in network)

		ProjectileComp.Expire();

		if (Time::GameTimeSeconds < AttackTime + 0.3)
		{
			USummitCrystalSkullProjectileEventHandler::Trigger_OnExpireNoExplosion(this);
			return; // Never deal damage until properly launched
		}

		USummitCrystalSkullProjectileEventHandler::Trigger_OnExplode(this);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;

			// Deal damage in a sphere slice
			if (Math::Abs(Player.ActorLocation.Z - ActorLocation.Z) > Settings.ArcProjectileTriggerHeight) 
				continue; 

			float DamageFactor = Damage::GetRadialDamageFactor(Player.ActorLocation, ActorLocation, Settings.ArcProjectileDamageRadius);
			if (DamageFactor > 0.0)
			{
				Player.DamagePlayerHealth(Settings.ArcProjectileDamage * DamageFactor);
				Player.AddDamageInvulnerability(this, Settings.ArcProjectileDamageCooldown);
			}
		}	
	}
}

class USummitArcProjectileLauncher : UBasicAIProjectileLauncherComponent
{
	bool bSplitTargets = false;
	float ProjectilesMultiple = 1.0;
}
