
class AIslandBeamTurretronProjectile : AHazeActor
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
	default ProjectileComp.Friction = 0.0;
	default ProjectileComp.Gravity = 0.0;

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
		
		float YScale = Math::Clamp(1.5 - Scale, 0.5, 1.5);
		Mesh.SetWorldScale3D(FVector(Scale, YScale, Scale));
		Scale -= DeltaTime * 3.0;
		Scale = Math::Clamp(Scale, 0.3, 1.0);

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
		Hit = Trace.QueryTraceSingle(HitTraceLoc.WorldLocation - DeltaLocation.GetSafeNormal() * YScale * 100, HitTraceLoc.WorldLocation + DeltaLocation.GetSafeNormal() * YScale * 200);
		//Debug::DrawDebugSphere(HitTraceLoc.WorldLocation - DeltaLocation.GetSafeNormal() * YScale * 100, 20, 12,FLinearColor::DPink, bDrawInForeground = true);
		//Debug::DrawDebugSphere(HitTraceLoc.WorldLocation + DeltaLocation.GetSafeNormal() * YScale * 200, 20, 12,FLinearColor::DPink, bDrawInForeground = true);
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
		FIslandBeamTurretronProjectileOnImpactEventData Data;
		Data.HitResult = Hit;

		if (Hit.Actor != nullptr)
		{
			auto TurretSettings = UIslandBeamTurretronSettings::GetSettings(ProjectileComp.Launcher);
			
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if (Player != nullptr)
			{				

				FIslandBeamTurretronProjectileOnPlayerDamageEventData Params;

				Player.DealTypedDamage(ProjectileComp.Launcher, 
				TurretSettings.ProjectileDamagePlayer, 
				EDamageEffectType::ProjectilesLarge, 
				EDeathEffectType::ProjectilesLarge, DeathParams = FPlayerDeathDamageParams(-Params.ImpactDirection, 2.0));

				Params.HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
				devCheck(Params.HitPlayer != nullptr, "Hit owner of UPlayerHealtComponent was nullptr after casting.");
				Params.ImpactDirection = (Params.HitPlayer.ActorCenterLocation - Hit.ImpactPoint).GetSafeNormal();
				Params.ImpactLocation = Hit.Location;
				UIslandBeamTurretronProjectileEventHandler::Trigger_OnImpact(this, Data);
				
				// Special case for when player is on a hoverperch
				UHoverPerchPlayerComponent Perch = UHoverPerchPlayerComponent::Get(Hit.Actor);
				if (Perch != nullptr && Perch.PerchActor != nullptr)
				{
					Perch.PerchActor.AddMovementImpulse(ProjectileComp.Velocity.GetSafeNormal() * 2000);
					FauxPhysics::ApplyFauxImpulseToActorAt(Perch.PerchActor, Params.ImpactLocation, ProjectileComp.Velocity.GetSafeNormal() * 1000);
					Params.HitPlayer.ApplyAdditiveHitReaction(ProjectileComp.Velocity.GetSafeNormal(), EPlayerAdditiveHitReactionType::Big);
				}
				else if (TurretSettings.bEnableProjectileKnockdown)
				{
					// Knockdown
					Params.HitPlayer.ApplyKnockdown(Params.ImpactDirection * TurretSettings.ProjectileKnockdownMove, TurretSettings.ProjectileKnockdownDuration);
				}
				UIslandBeamTurretronProjectileEventHandler::Trigger_OnPlayerDamage(this, Params);

			}
			else
			{
				UIslandTurretronProjectileResponseComponent ResponseComp = UIslandTurretronProjectileResponseComponent::Get(Hit.Actor);
				if (ResponseComp != nullptr)
					ResponseComp.OnHit.Broadcast();

				UIslandBeamTurretronProjectileEventHandler::Trigger_OnImpact(this, Data);
				ProjectileComp.Expire();
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
