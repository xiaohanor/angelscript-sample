UCLASS(Abstract)
class ASummitStoneBeastCrystalTurretProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach=Mesh)
	UScenepointComponent HitTraceLoc;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 5.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION()
	private void OnReset()
	{
		ProjectileComp.TraceType = ETraceTypeQuery::WeaponTraceEnemy;
		Scale = 1.0;
	}

	float Scale = 1.0;
	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;
		
		//float XScale = Math::Clamp(2.0 - Scale, 0.5, 1.5);
		//Mesh.SetWorldScale3D(FVector(XScale, Scale, Scale));
		//Scale -= DeltaTime * 3.0;
		//Scale = Math::Clamp(Scale, 0.2, 1.0);

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		FVector NewLocation = ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit, true);
		FVector DeltaLocation = NewLocation - ActorLocation;
		SetActorLocation(NewLocation);
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::WeaponTraceEnemy);
		Trace.UseLine();

		if (ProjectileComp.Launcher != nullptr)
		{	
			Trace.IgnoreActor(ProjectileComp.Launcher);			
		}
		Hit = Trace.QueryTraceSingle(HitTraceLoc.WorldLocation, HitTraceLoc.WorldLocation + DeltaLocation);
		if (Hit.bBlockingHit)
		{
			OnImpact(Hit);
			Impact(Hit);
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	void Impact(FHitResult Hit)
	{
		FSummitStoneBeastCrystalTurretProjectileOnImpactEventData Data;
		Data.HitResult = Hit;

		if (Hit.Actor != nullptr)
		{
			auto TurretSettings = USummitStoneBeastCrystalTurretSettings::GetSettings(ProjectileComp.Launcher);
			UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Hit.Actor);
			if (PlayerHealthComp != nullptr)
			{
				PlayerHealthComp.DamagePlayer(TurretSettings.ProjectileDamagePlayer, nullptr, nullptr);
				FSummitStoneBeastCrystalTurretProjectileOnPlayerDamageEventData Params;
				Params.HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
				devCheck(Params.HitPlayer != nullptr, "Hit owner of UPlayerHealtComponent was nullptr after casting.");
				Params.ImpactDirection = (Params.HitPlayer.ActorCenterLocation - Hit.ImpactPoint).GetSafeNormal();
				Params.ImpactLocation = Hit.Location;
				USummitStoneBeastCrystalTurretProjectileEventHandler::Trigger_OnImpact(this, Data);								
				USummitStoneBeastCrystalTurretProjectileEventHandler::Trigger_OnPlayerDamage(this, Params);

			}
			else
			{
				USummitStoneBeastCrystalTurretProjectileEventHandler::Trigger_OnImpact(this, Data);
			}
		}
		else
		{
			ProjectileComp.Expire();
		}
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}
}
