class UIslandWalkerClusterMineLauncherComponent : UBasicAINetworkedProjectileLauncherComponent
{
	default RelativeRotation = FRotator(90.0, 0.0, 0.0);
	int Index;
}

UCLASS(Abstract)
class AIslandWalkerClusterMine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = CollisionComp)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueTargetableComponent TargetableComp;
	default TargetableComp.TargetShape.Type = EHazeShapeType::Sphere;
	default TargetableComp.TargetShape.SphereRadius = 60.0;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent ShootableResponseComp;

	UPROPERTY(DefaultComponent)
	UIslandWalkerClusterMineHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bResolveMovementLocally.DefaultValue = true;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerClusterMineLaunchCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerClusterMineFallCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerClusterMineFollowCapability");

	UIslandWalkerSettings Settings;
	AIslandWalkerArenaLimits Arena = nullptr;
	FWalkerArenaLanePosition LanePosition;

	AHazePlayerCharacter Target;

	bool bLaunched = false;
	bool bLanded;
	bool bBounced;
	bool bExploded;
	bool bTelegraphedExplosion;
	float ExplodeTime;
	float ExpireTime;
	float Health;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh.AddComponentVisualsBlocker(this);
		ShootableResponseComp.OnImpactEvent.AddUFunction(this, n"OnBulletImpact");
		TargetableComp.Disable(this);
		HealthBarComp.HideHealthBar();
		CollisionComp.AddComponentCollisionBlocker(this);
	}

	void LaunchAt(AHazePlayerCharacter PlayerTarget, FWalkerArenaLanePosition LanePos)
	{
		Target = PlayerTarget;
		LanePosition = LanePos;

		Settings = UIslandWalkerSettings::GetSettings(ProjectileComp.Launcher);
		if (Arena == nullptr)
			Arena = UIslandWalkerComponent::Get(ProjectileComp.Launcher).ArenaLimits;

		bLaunched = true;
		bLanded = false;
		bBounced = false;
		bTelegraphedExplosion = false;
		bExploded = false;
		ExplodeTime = BIG_NUMBER;
		ExpireTime = BIG_NUMBER;

		Mesh.RemoveComponentVisualsBlocker(this);
		CollisionComp.RemoveComponentCollisionBlocker(this);
		CollisionComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

		Health = 1.0;
		HealthBarComp.Initialize();
		HealthBarComp.HideHealthBar();

		SetActorRotation(FRotator::MakeFromZX(FVector::UpVector, Target.ActorLocation - ActorLocation));

		UIslandWalkerClusterMineEventHandler::Trigger_OnLaunch(this);
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bLaunched)
			return;

		if (bLanded)
		{
			float CurTime = Time::GameTimeSeconds;
			if (!bTelegraphedExplosion && (CurTime > ExplodeTime - Settings.ClusterMineTelegraphExplosionTime))
			{
				bTelegraphedExplosion = true;
				UIslandWalkerClusterMineEventHandler::Trigger_OnTelegraphExplosion(this);
			}

			if ((CurTime > ExplodeTime) && HasControl())
				CrumbExplode(true);
			if (CurTime > ExpireTime)
				Expire();
		}
	}

	void Land()
	{
		bLanded = true;
		ExplodeTime = Time::GameTimeSeconds + Settings.ClusterMineMaxExplosionDelay;
		ExpireTime = ExplodeTime + Settings.ClusterMineExpirationDelay;
		TargetableComp.Enable(this);
		CollisionComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
		ProjectileComp.Velocity = FVector::ZeroVector;
		UIslandWalkerClusterMineEventHandler::Trigger_OnLand(this);
	}

	void Bounce()
	{
		bBounced = true;
		ProjectileComp.Velocity = MoveComp.Velocity;
	}

	UFUNCTION(CrumbFunction)
	void CrumbExplode(bool bAffectPlayers)
	{
		if (ExplodeTime == BIG_NUMBER)
			return; // Already exploded from other source

		bExploded = true;
		ExplodeTime = BIG_NUMBER;
		ExpireTime = Time::GameTimeSeconds + Settings.ClusterMineExpirationDelay;
		
		if (bAffectPlayers)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (!Player.HasControl())
					continue;
				if (!Player.ActorLocation.IsWithinDist(ActorLocation, Settings.ClusterMineDamageRadius))
					continue;
				Player.DealTypedDamage(ProjectileComp.Launcher, Settings.ClusterMineDamage, EDamageEffectType::Explosion, EDeathEffectType::Explosion);
				FVector StumbleMove = (Player.ActorLocation - ActorLocation).GetNormalizedWithFallback(-Player.ActorForwardVector) * 500.0;
				Player.ApplyStumble(StumbleMove, 0.5);
			}
		}

		Mesh.AddComponentVisualsBlocker(this);
		TargetableComp.Disable(this);
		CollisionComp.AddComponentCollisionBlocker(this);
		HealthBarComp.HideHealthBar();

		UIslandWalkerClusterMineEventHandler::Trigger_OnExplode(this);
	}

	void Expire()
	{
		ExpireTime = BIG_NUMBER;
		bLaunched = false;
		if (!bExploded)
		{
			TargetableComp.Disable(this);
			CollisionComp.AddComponentCollisionBlocker(this);
			HealthBarComp.HideHealthBar();
		}
		ProjectileComp.Expire();
	}

	UFUNCTION()
	private void OnBulletImpact(FIslandRedBlueImpactResponseParams Data)
	{
		// These hits are networked, so health should correspond roughly on both sides
		if (!bLanded)
			return;
		if (ExplodeTime == BIG_NUMBER)
			return;

		Health -= Settings.ClusterMineDamageFromBullets * Data.ImpactDamageMultiplier;
		if (Health < SMALL_NUMBER)
		{
			Health = 0.0;
			if (Data.Player.HasControl())
				CrumbExplode(false);
		}
		else
		{
			// This will also show health bar
			HealthBarComp.ModifyHealth(Health);
		}
	}
};

UCLASS(Abstract)
class UIslandWalkerClusterMineEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMovementJump() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMovementLand() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphExplosion() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}
}
