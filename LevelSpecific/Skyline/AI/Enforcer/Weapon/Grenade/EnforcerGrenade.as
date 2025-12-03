class AEnforcerGrenade : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.TraceType = ETraceTypeQuery::WorldGeometry;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UEnforcerDangerZone DangerZoneRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegisterComp;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	UEnforcerGrenadeSettings Settings;

	bool bThrown = false;
	bool bLanded = false;
	bool bExploded = false;
	float ThrowTime = 0.0;
	float DetonationTime = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh.AddComponentVisualsBlocker(this);		
	}

	void Wield(USceneComponent WieldComp)
	{
		AttachRootComponentTo(WieldComp, NAME_None, EAttachLocation::SnapToTarget);
		bThrown = false;
		bLanded = false;
		bExploded = false;
		Mesh.RemoveComponentVisualsBlocker(this);
		UEnforcerGrenadeEventHandler::Trigger_OnWield(this);
	}

	void Throw(AHazeActor Thrower, FVector ThrowVelocity)
	{
		bThrown = true;
		DetachRootComponentFromParent(true);
		ThrowTime = Time::GameTimeSeconds;
		Settings = UEnforcerGrenadeSettings::GetSettings(Thrower);
		ProjectileComp.Velocity = ThrowVelocity;
		DetonationTime = Time::GameTimeSeconds + Settings.MaxDuration;

		UEnforcerGrenadeEventHandler::Trigger_OnThrow(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bThrown)
			return;

		if (!bLanded)
		{
			bool bIgnoreCollision = (ProjectileComp.Velocity.Z > 0.0);
			FHitResult Hit;
			ActorLocation = ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit, bIgnoreCollision);
			if (Hit.bBlockingHit)
			{
				bLanded = true;
				DetonationTime = Time::GameTimeSeconds + Settings.LandedFuseTime;
				UEnforcerGrenadeEventHandler::Trigger_OnLand(this);
			}
		}

		if (!bExploded && (Time::GameTimeSeconds > DetonationTime))
		{
			bExploded = true;
			Mesh.AddComponentVisualsBlocker(this);

			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (!Player.HasControl())		
					continue;
				if (!Player.ActorLocation.IsWithinDist(ActorLocation, Settings.BlastRadius))
					continue;
				auto HealthComp = UPlayerHealthComponent::Get(Player);

				FVector Direction = (Player.ActorLocation - ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
				HealthComp.DamagePlayer(Settings.Damage, DamageEffect, DeathEffect, false, FPlayerDeathDamageParams(Direction, 10.0));
			}
			if (Settings.AIDamage > 0.0)
			{
				UHazeTeam AITeam = HazeTeam::GetTeam(AITeams::Default);
				if (AITeam != nullptr)
				{
					for (AHazeActor AI : AITeam.GetMembers())
					{
						if (AI == nullptr)
							continue;
						if (!AI.HasControl())
							continue;
						if (!AI.ActorLocation.IsWithinDist(ActorLocation, Settings.BlastRadius))
							continue;
						UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(AI);
						if (HealthComp == nullptr)
							continue;
						// Giving no instigator makes damage occur on AI's own control side, not control side of grenade thrower
						HealthComp.TakeDamage(Settings.AIDamage, EDamageType::Explosion, nullptr);
					}
				}
			}

			UEnforcerGrenadeEventHandler::Trigger_OnExplode(this, FEnforcerGrenadeEventHandlerData(Settings.BlastRadius));
		}

		if (bExploded && (Time::GameTimeSeconds > DetonationTime + Settings.PostExplosionRemainDuration))
		{
			ProjectileComp.Expire(); // We stay in place a while (invisible) so that attached effects can peter out.
		}

		DangerZoneRoot.Update(DeltaTime);
	}
};


UCLASS(Abstract)
class UEnforcerGrenadeEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	UEnforcerDangerZone DangerZone;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DangerZone = UEnforcerDangerZone::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWield(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrow(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode(FEnforcerGrenadeEventHandlerData Data){}
}

struct FEnforcerGrenadeEventHandlerData
{
	UPROPERTY()
	float BlastRadius;

	FEnforcerGrenadeEventHandlerData(float _BlastRadius)
	{
		BlastRadius = _BlastRadius;
	}
}