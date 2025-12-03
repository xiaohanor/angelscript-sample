UCLASS(Abstract)
class AIslandOverseerWallBomb : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshOffset;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent, Attach=MeshOffset)
	UHazeSkeletalMeshComponentBase RedMesh;
	default RedMesh.CollisionProfileName = n"NoCollision";
	default RedMesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach=MeshOffset)
	UHazeSkeletalMeshComponentBase BlueMesh;
	default BlueMesh.CollisionProfileName = n"NoCollision";
	default BlueMesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent, Attach=MeshOffset)
	UCapsuleComponent TakeDamageCollision;

	UPROPERTY(DefaultComponent, Attach=TakeDamageCollision)
	UIslandRedBlueImpactResponseComponent ImpactResponseComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerRedBlueDamageComponent OverseerRedBlueDamageComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent WallDamage;

	UPROPERTY(DefaultComponent)
	USceneComponent WallContainer;

	UPROPERTY(DefaultComponent, Attach = WallContainer)
	UNiagaraComponent WallDamageFxUpper;
	default WallDamageFxUpper.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = WallContainer)
	UNiagaraComponent WallDamageFxLower;
	default WallDamageFxLower.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = WallContainer)
	UNiagaraComponent WallDamageFxFloor;
	default WallDamageFxFloor.bAutoActivate = false;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 15.0;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	AHazeActor OwningActor;
	FVector DeployWallLocation;
	bool bDeployed;
	bool bArrived;
	const float DeployDuration = 0.5;
	float ArriveTime;

	bool bBlue;
	float Health = 1;
	const float MaxHealth = 1;
	const float OriginalBeamWidth = 30;

	float TookDamageTime;
	const float TookDamageDuration = 0.015;
	const float TookDamageOffset = 25;
	FVector TookDamageScale;
	FHazeAcceleratedVector AccTookDamageScale;
	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedVector AccScale;
	FHazeAcceleratedVector AccWallScale;

	float FlashDuration = 0.1;
	float FlashTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileComp.OnLaunch.AddUFunction(this, n"OnLaunch");
		ImpactResponseComp.OnImpactEvent.AddUFunction(this, n"RedBlueImpact");
		OverseerRedBlueDamageComp.OnDamage.AddUFunction(this, n"RedBlueDamage");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		bDeployed = false;
		bArrived = false;

		WallDamageFxUpper.ResetSystem();
		WallDamageFxUpper.Deactivate();

		WallDamageFxLower.ResetSystem();
		WallDamageFxLower.Deactivate();
		
		WallDamageFxFloor.AttachTo(WallContainer, NAME_None, EAttachLocation::SnapToTarget);
		WallDamageFxFloor.ResetSystem();
		WallDamageFxFloor.Deactivate();

		DeployWallLocation = FVector::ZeroVector;
	}
	
	UFUNCTION()
	private void OnRespawn()
	{
		Health = MaxHealth;
		SetActorScale3D(FVector::OneVector);
		AccScale.SnapTo(FVector::OneVector);
		AccTookDamageScale.SnapTo(FVector::ZeroVector);
		bDeployed = false;
		bArrived = false;
		AccWallScale.SnapTo(FVector::ZeroVector);
		WallDamage.AddComponentCollisionBlocker(this);
		ArriveTime = 0;
	}

	UFUNCTION()
	private void RedBlueImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if(bBlue && Data.Player == Game::Mio)
			return;
		if(!bBlue && Data.Player == Game::Zoe)
			return;

		if(Time::GetGameTimeSince(FlashTime) > FlashDuration + 0.1)
		{
			DamageFlash::DamageFlashActor(this, FlashDuration, FLinearColor(0.9, 0, 0, 1));
			FlashTime = Time::GameTimeSeconds;
			FlashDuration = Math::RandRange(0.1, 0.2);
		}

		TookDamageTime = Time::GameTimeSeconds;
		TookDamageScale = FVector::OneVector * 1.15;
	}

	UFUNCTION()
	private void RedBlueDamage(float Damage, AHazeActor Instigator)
	{
		if(bBlue && Instigator == Game::Mio)
			return;
		if(!bBlue && Instigator == Game::Zoe)
			return;

		UIslandOverseerSettings Settings = UIslandOverseerSettings::GetSettings(OwningActor);
		Health -= Damage * Settings.WallBombRedBlueDamagePerSecond;

		if(Health <= 0)
		 	CrumbDestroyBomb();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDestroyBomb()
	{
		UIslandOverseerWallBombEventHandler::Trigger_OnDestroyed(this);
		ProjectileComp.Expire();

		IslandOverseerWallBomb::GetAudioManager().UnRegisterWallBomb(this);
	}

	UFUNCTION()
	private void OnLaunch(UBasicAIProjectileComponent Projectile)
	{
		UIslandOverseerWallBombEventHandler::Trigger_OnLaunch(this, FIslandOverseerWallBombOnLaunchEventData(Projectile.Owner.ActorLocation));
	}

	void SetColor(bool bColorBlue)
	{
		bBlue = bColorBlue;

		BlueMesh.SetVisibility(bBlue);
		RedMesh.SetVisibility(!bBlue);
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		DealWallDamage();

		if(TookDamageTime > 0 && Time::GetGameTimeSince(TookDamageTime) < TookDamageDuration)
			AccTookDamageScale.AccelerateTo(TookDamageScale, TookDamageDuration, DeltaTime);
		else
			AccTookDamageScale.AccelerateTo(FVector::OneVector, TookDamageDuration, DeltaTime);
		MeshOffset.RelativeScale3D = AccTookDamageScale.Value;

		AccScale.AccelerateTo(FVector::OneVector * 1.75, 4, DeltaTime);
		SetActorScale3D(AccScale.Value);

		if(bArrived)
		{
			AccRotation.SpringTo(FRotator::ZeroRotator, 175, 0.5, DeltaTime);
			SetActorRotation(AccRotation.Value);

			if(!bDeployed)
			{
				if(ArriveTime == 0)
					ArriveTime = Time::GameTimeSeconds;
				if(Time::GetGameTimeSince(ArriveTime) > DeployDuration)
				{
					CrumbDeploy();
				}
				return;
			}
		}

		if(bDeployed)
		{
			FVector DestroyLocation = ProjectileComp.Launcher.ActorLocation + ProjectileComp.Launcher.ActorForwardVector * 500;
			if(ProjectileComp.Launcher.ActorForwardVector.DotProduct((ActorLocation - DestroyLocation)) < 0)
			{
				CrumbDestroyBomb();
				return;
			}

			return;
		}

		if(DeployWallLocation != FVector::ZeroVector && ProjectileComp.Launcher.ActorForwardVector.DotProduct(DeployWallLocation - ActorLocation) < 0)
		{
			AccRotation.SnapTo(ProjectileComp.Velocity.Rotation() + FRotator(-90, 0, 0));
			bArrived = true;
			return;
		}

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		SetActorRotation(ProjectileComp.Velocity.Rotation() + FRotator(-90, 0, 0));

		if (Hit.bBlockingHit)
		{
			AActor Controller = ProjectileComp.Launcher;
			if ((Hit.Actor != nullptr) && (Hit.Actor.IsA(AHazePlayerCharacter)))
				Controller = Hit.Actor;
			if (Controller.HasControl())	
			{
				if (IsObjectNetworked())
					CrumbImpact(Hit); 
				else
					LauncherCrumbImpact(Hit);
			}
			else
			{
				// Visual impact only
				OnLocalImpact(Hit);
				UIslandOverseerWallBombEventHandler::Trigger_OnHit(this, FIslandOverseerWallBombOnHitEventData(Hit));
			}
		}
	}
	
	UFUNCTION(CrumbFunction)
	private void CrumbDeploy()
	{
		bDeployed = true;
		UIslandOverseerWallBombEventHandler::Trigger_OnDeployed(this);
		WallDamageFxUpper.Activate();
		WallDamageFxLower.Activate();
		WallDamageFxFloor.Activate();
		WallDamage.RemoveComponentCollisionBlocker(this);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + FVector::DownVector * 2000);
		if(Hit.bBlockingHit)
			WallDamageFxFloor.WorldLocation = Hit.ImpactPoint;
		WallDamageFxFloor.DetachFromParent(true);

		IslandOverseerWallBomb::GetAudioManager().RegisterWallBomb(this);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbImpact(FHitResult Hit)
	{
		OnImpact(Hit);
		Impact(Hit);
		UIslandOverseerWallBombEventHandler::Trigger_OnHit(this, FIslandOverseerWallBombOnHitEventData(Hit));
	}

	private void Impact(FHitResult Hit)
	{
		FBasicAiProjectileOnImpactData Data;
		Data.HitResult = Hit;
		UBasicAIProjectileEffectHandler::Trigger_OnImpact(ProjectileComp.HazeOwner, Data);
		BasicAIProjectile::DealDamage(Hit, ProjectileComp.Damage, ProjectileComp.DamageType, ProjectileComp.Launcher);
	}

	private void LauncherCrumbImpact(FHitResult Hit)
	{
		// Network impacts through the projectile launcher component that launched this projectile
		// Note that this means a single projectile can potentially impact against two different target on each side in network.
		UBasicAIProjectileLauncherComponent LaunchingWeapon = Cast<UBasicAIProjectileLauncherComponent>(ProjectileComp.LaunchingWeapon);	
		LaunchingWeapon.CrumbProjectileImpact(Hit, ProjectileComp.Damage, ProjectileComp.DamageType, ProjectileComp.Launcher);
		OnLocalImpact(Hit);
		UIslandOverseerWallBombEventHandler::Trigger_OnHit(this, FIslandOverseerWallBombOnHitEventData(Hit));
	}

	private void DealWallDamage()
	{
		if(!bDeployed)
			return;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(!Overlap::QueryShapeOverlap(WallDamage.GetCollisionShape(4), WallDamage.WorldTransform, Player.CapsuleComponent.GetCollisionShape(), Player.CapsuleComponent.WorldTransform))
				continue;

			if (Player.HasControl())
				Player.KillPlayer(DeathEffect = DeathEffect);
		}
	}

	UFUNCTION()
	void SetWallLocation(FVector _DeployWallLocation)
	{
		DeployWallLocation = _DeployWallLocation;
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}

	// Projectile impacted on local side, any gameplay need to be networked if started here
	UFUNCTION(BlueprintEvent)
	void OnLocalImpact(FHitResult Hit) {}
}