event void OnEnforcerRifleProjectilePlayerHitSignature(AHazePlayerCharacter Player, FPlayerDeathDamageParams DeathParams);
event void OnEnforcerRifleProjectileExpire(AEnforcerRifleProjectile Projectile);

class AEnforcerRifleProjectile : AHazeActor
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
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	// Ricocheting code, we don't want this anymore
	//UPROPERTY(DefaultComponent)
	//UGravityBladeCombatResponseComponent GravityBladeResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	default WhipResponse.GrabMode = EGravityWhipGrabMode::Sling;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent)
	UBasicAIHomingProjectileComponent HomingProjectileComp;

	OnEnforcerRifleProjectilePlayerHitSignature OnPlayerHit;
	OnEnforcerRifleProjectileExpire OnExpire;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 3.0;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	AHazeActor OriginalLauncher;
	bool bWhipGrabbed = false;
	bool bWhipThrown = false;
	float DefaultFriction;
	float GrabbedSpeed;

	bool bDeflected = false;

	UEnforcerWeaponComponent OwnerWeaponComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Ricocheting code, we don't want this anymore
		//GravityBladeResponseComp.OnHit.AddUFunction(this, n"GravityBladeHit");

		// WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		// WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");
		WhipTarget.Disable(this);

		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");

		JoinTeam(EnforcerRifleProjectileTags::EnforcerRifleProjectileTeam);

		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
		ProjectileComp.OnPrime.AddUFunction(this, n"OnPrime");
	}

	UFUNCTION()
	private void OnPrime(UBasicAIProjectileComponent Projectile)
	{
		USkylineEnforcerRifleProjectileEffectEventHandler::Trigger_OnPrime(this);
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		USkylineEnforcerRifleProjectileEffectEventHandler::Trigger_OnLaunch(this);
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		bWhipGrabbed = false;
		bDeflected = false;
		bWhipThrown = false;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(EnforcerRifleProjectileTags::EnforcerRifleProjectileTeam);
	}

	UFUNCTION()
	private void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult, FVector Impulse)
	{
		bWhipGrabbed = false;
		bWhipThrown = true;
		ProjectileComp.bIsLaunched = false;

		FVector AimDir = Impulse.GetSafeNormal();

		UTargetableComponent PrimaryTarget = UPlayerTargetablesComponent::GetOrCreate(UserComponent.Owner).GetPrimaryTargetForCategory(n"AutoAim");
		if(PrimaryTarget != nullptr)
		{
			HomingProjectileComp.Target = Cast<AHazeActor>(PrimaryTarget.Owner);
			AimDir = (Cast<AHazeActor>(PrimaryTarget.Owner).FocusLocation - ActorLocation).GetSafeNormal();
		}

		ProjectileComp.Friction = DefaultFriction;
		ProjectileComp.Damage = UEnforcerRifleSettings::GetSettings(OriginalLauncher).AIDamage;
		ProjectileComp.Launch(AimDir * GrabbedSpeed * 2.0);		
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		bWhipGrabbed = true;
		
		OriginalLauncher = ProjectileComp.Launcher;
		ProjectileComp.TraceType = ETraceTypeQuery::WeaponTracePlayer;
		ProjectileComp.Launcher = Cast<AHazeActor>(UserComponent.Owner);
		ProjectileComp.Friction = 0.8;
		GrabbedSpeed = ProjectileComp.Velocity.Size();
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		if(bWhipGrabbed)
		{
			return;
		}

		if(HomingProjectileComp.Target != nullptr)
		{
			FVector TargetLocation = HomingProjectileComp.Target.ActorCenterLocation;
			if((bWhipThrown || bDeflected) && ProjectileComp.Velocity.DotProduct(TargetLocation - ActorLocation) > 0)
			{
				float LaunchDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
				ProjectileComp.Velocity += HomingProjectileComp.GetPlanarHomingAcceleration(TargetLocation, ProjectileComp.Velocity.GetSafeNormal(), 300.0 * Math::Min(1, LaunchDuration)) * DeltaTime;
			}
		}

		LocalMovement(DeltaTime);

		if(!DestroyOtherProjectiles())
		{
			UHazeTeam Team = HazeTeam::GetTeam(EnforcerRifleProjectileTags::EnforcerRifleProjectileTeam);
			if(Team != nullptr)
			{
				for(AHazeActor Member: Team.GetMembers())
				{
					if(!Member.ActorLocation.IsWithinDist(ActorLocation, 50))
						continue;

					if(!Cast<AEnforcerRifleProjectile>(Member).DestroyOtherProjectiles())
						continue;

					FHitResult Hit;
					Hit.Location = ActorLocation;
					OnImpact(Hit);
					Impact(Hit);
					break;
				}
			}
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	bool DestroyOtherProjectiles()
	{
		if(bDeflected)
			return true;
		if(bWhipThrown)
			return true;
		return false;
	}

	void LocalMovement(float DeltaTime)
	{
		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));

		if (Hit.bBlockingHit)
		{
			OnImpact(Hit);
			Impact(Hit);
		}
	}

	void Impact(FHitResult Hit)
	{
		AHazePlayerCharacter HitPlayer = (Hit.Actor != nullptr) ? Cast<AHazePlayerCharacter>(Hit.Actor) : nullptr;
		
		FVector ImpactDirection = FVector(0.0);

		if (HitPlayer != nullptr)
			ImpactDirection = (HitPlayer.ActorCenterLocation - ActorLocation).GetSafeNormal(); 
		
		//BasicAIProjectile::DealDamage(Hit, ProjectileComp.Damage, ProjectileComp.DamageType, ProjectileComp.Launcher, FPlayerDeathDamageParams(ImpactDirection), DamageEffect, DeathEffect);

		if (HitPlayer != nullptr)
		{
			// UEnforcerRifleSettings RifleSettings = UEnforcerRifleSettings::GetSettings(ProjectileComp.LaunchingWeapon);	
			OnPlayerHit.Broadcast(HitPlayer, FPlayerDeathDamageParams(ImpactDirection, 5.0));
		}

		FSkylineEnforcerRifleProjectileOnImpactData Data;
		Data.HitResult = Hit;
		USkylineEnforcerRifleProjectileEffectEventHandler::Trigger_OnImpact(this, Data);

		if(OwnerWeaponComp == nullptr)			
			OwnerWeaponComp = Cast<UEnforcerWeaponComponent>(ProjectileComp.GetLaunchingWeapon());

		USkylineEnforcerRifleProjectileEffectEventHandler::Trigger_OnImpact(OwnerWeaponComp.WeaponActor, Data);
		ProjectileComp.Expire();
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		OnExpire.Broadcast(this);
	}
}

namespace EnforcerRifleProjectileTags
{
	const FName EnforcerRifleProjectileTeam = n"EnforcerRifleProjectileTeam";
}