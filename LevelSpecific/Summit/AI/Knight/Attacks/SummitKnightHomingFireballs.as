class USummitKnightHomingFireballsLauncher : UBasicAIProjectileLauncherComponent
{
	TArray<ASummitKnightHomingFireball> ActiveFireballs;
}

class ASummitKnightHomingFireball : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// UPROPERTY(DefaultComponent)
	// UStaticMeshComponent Mesh;
	// default Mesh.CollisionProfileName = n"NoCollision";
	// default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	USummitKnightComponent KnightComp;
	USummitKnightHomingFireballsLauncher HomingFireballsLauncher;

	FVector LaunchLocation;
	FVector LaunchVelocity;
	FVector LandTangent;
	FVector TargetLocation;
	float TotalFlightDuration;
	float StartExpirationTime;
	float DealDamageStartTime;
	TArray<AHazePlayerCharacter> AvailableTargets;

	USummitKnightSettings Settings;

	void LaunchAt(FVector TargetLoc, float FlightDurationFactor, USummitKnightHomingFireballsLauncher FireballLauncher)
	{
		Settings = USummitKnightSettings::GetSettings(ProjectileComp.Launcher);
		KnightComp = USummitKnightComponent::Get(ProjectileComp.Launcher);

		LaunchLocation = ActorLocation;
		LaunchVelocity = ProjectileComp.Velocity;
		TargetLocation = TargetLoc;
		TargetLocation.Z -= 10.0;
		TotalFlightDuration = Settings.HomingFireballsFlightDuration * FlightDurationFactor;
		StartExpirationTime = BIG_NUMBER;
		DealDamageStartTime = BIG_NUMBER;
		AvailableTargets = Game::Players;

		// Land at a random fairly steep angle
		FVector ToTarget = TargetLoc - LaunchLocation;
		FVector LandDir = Math::GetRandomConeDirection(ToTarget - FVector::UpVector * Settings.HomingFireballsSteepness, PI * 0.02);
		LandTangent = LandDir * Settings.HomingFireballsSteepness; 
		ActorRotation = ProjectileComp.Velocity.Rotation();	

		USummitKnightHomingFireballEventHandler::Trigger_OnLaunch(this);
		HomingFireballsLauncher = FireballLauncher;
		HomingFireballsLauncher.ActiveFireballs.Add(this);
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		float CurTime = Time::GameTimeSeconds;
		if ((CurTime > DealDamageStartTime) && (CurTime < DealDamageStartTime + Settings.HomingFireballsDamageDuration))
			CheckForPlayerDamage();		

		if (CurTime > StartExpirationTime + 5.0)
		{
			HomingFireballsLauncher.ActiveFireballs.RemoveSingleSwap(this);
			ProjectileComp.Expire();
		}
		if (CurTime > StartExpirationTime)
			return;

		// Local movement 
		float FlightDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		float Alpha = FlightDuration / TotalFlightDuration;
		FVector NewLoc = BezierCurve::GetLocation_2CP_ConstantSpeed(LaunchLocation, LaunchLocation + LaunchVelocity, TargetLocation - LandTangent, TargetLocation, Alpha);
		ActorRotation = (NewLoc - ActorLocation).Rotation();	

		FHitResult Hit;
		if ((FlightDuration > TotalFlightDuration * 0.25) && !ActorLocation.IsWithinDist(NewLoc, 0.1))
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ProjectileComp.TraceType);
			Trace.UseLine();
			Trace.IgnoreActor(ProjectileComp.Launcher);
			Hit = Trace.QueryTraceSingle(ActorLocation, NewLoc - FVector::UpVector);
		}

		if (Hit.bBlockingHit)
		{
			// Impact!
			SetActorLocation(Hit.Location);
			
			FSummitKnightHomingFireballImpactParams Params;
			Params.Location = Hit.Location;
			Params.ImpactNormal = Hit.ImpactNormal;
			DealDamageStartTime = CurTime;
			USummitKnightHomingFireballEventHandler::Trigger_OnImpact(this, Params);
			USummitKnightEventHandler::Trigger_OnFireballImpact(Cast<AHazeActor>(KnightComp.Owner), FSummitKnightProjectileImpactParams(Hit.Location));

			StartExpiring();
		}
		else 
		{
			// Unimpeded flight
			SetActorLocation(NewLoc);
			if (Alpha > 0.999)
			{
				FSummitKnightHomingFireballImpactParams Params;
				Params.Location = Hit.Location;
				Params.ImpactNormal = FVector::UpVector;
				DealDamageStartTime = CurTime;
				USummitKnightHomingFireballEventHandler::Trigger_OnImpact(this, Params);
				USummitKnightEventHandler::Trigger_OnFireballImpact(Cast<AHazeActor>(KnightComp.Owner), FSummitKnightProjectileImpactParams(NewLoc));
				StartExpiring();
			}
		}

#if EDITOR
		//ProjectileComp.Launcher.bHazeEditorOnlyDebugBool = true;
		if (ProjectileComp.Launcher.bHazeEditorOnlyDebugBool)
		{
			FVector PrevLoc = LaunchLocation;
			for (float A = 0.05; A < 1.01; A += 0.05)	
			{
				FVector Loc = BezierCurve::GetLocation_2CP(LaunchLocation, LaunchLocation + LaunchVelocity, TargetLocation - LandTangent, TargetLocation, A);
				Debug::DrawDebugLine(PrevLoc, Loc, FLinearColor::Red);
				PrevLoc = Loc;
			}
		}
#endif		
	}

	void StartExpiring()
	{
		if (Time::GameTimeSeconds < StartExpirationTime)
			StartExpirationTime = Time::GameTimeSeconds;
	}

	void CheckForPlayerDamage()
	{
		for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
		{
			AHazePlayerCharacter Target = AvailableTargets[i];
			if (!Target.HasControl())
				continue;
			if (!Target.ActorLocation.IsWithinDist2D(ActorLocation, Settings.HomingFireballsDamageRadius))			
				continue;
			if (Target.ActorLocation.Z > ActorLocation.Z + Settings.HomingFireballsDamageRadius + 100.0)
				continue;
			
			// Damage and stumble are both internally networked
			Target.DealTypedDamage(KnightComp.Owner, Settings.HomingFireballsDamage, EDamageEffectType::FireImpact, EDeathEffectType::FireImpact, true);
			FVector HitDir = (Target.ActorLocation - KnightComp.Owner.ActorLocation).GetNormalized2DWithFallback(-Target.ActorForwardVector);
			FVector StumbleMove = HitDir * Settings.HomingFireballsStumbleDistance;
			KnightComp.StumbleDragon(Target, StumbleMove, 0.0, 0.4, 200.0);

			if (Target.HasControl() && Target.IsPlayerDead())
				KnightComp.CrumbDeathWhichCouldHaveBeenDashAvoided(Target);

			AvailableTargets.RemoveAt(i);
		}
	}
}



UCLASS(Abstract)
class USummitKnightHomingFireballEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(Transient)
	UNiagaraComponent ProjectileVFX;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ProjectileVFX = UNiagaraComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSummitKnightHomingFireballImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerImpact(FSummitKnightHomingFireballImpactParams Params) {}

	UFUNCTION(BlueprintPure)
	FVector GetLocationProjectedToArena(FVector Location)
	{
		UBasicAIProjectileComponent Projectile = UBasicAIProjectileComponent::Get(Owner);
		USummitKnightComponent KnightComp = ((Projectile != nullptr) && (Projectile.Launcher != nullptr)) ? USummitKnightComponent::Get(Projectile.Launcher) : nullptr;
		if (KnightComp == nullptr)
			return Location;
		return KnightComp.GetArenaLocation(Location, Cast<AHazePlayerCharacter>(Projectile.Target));
	}
}

struct FSummitKnightHomingFireballImpactParams
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactNormal;
}






