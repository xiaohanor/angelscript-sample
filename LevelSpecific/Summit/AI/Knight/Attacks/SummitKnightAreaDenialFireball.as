UCLASS(HideCategories = "Animation Mesh Clothing Physics Collision LeaderPoseComponent Lighting AnimationRig Deformer SkinWeights Rendering Navigation Debug Activation Cooking Tags SkeletalMesh Optimization MaterialParameters TextureStreaming LevelofDetail")
class USummitKnightAreaDenialFireballLauncher : UBasicAIProjectileLauncherComponent
{
	// Use these when players have breached the outer shield wall
	UPROPERTY(EditInstanceOnly)
	TArray<ASummitKnightAreaDenialZone> NearZones;

	// Used when the players are outside the outer shield wall
	UPROPERTY(EditInstanceOnly)
	TArray<ASummitKnightAreaDenialZone> FarZones;

	TArray<ASummitKnightAreaDenialFireball> ActiveFireballs;
}

class ASummitKnightAreaDenialFireball : AHazeActor
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

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	FVector LaunchLocation;
	FVector LaunchVelocity;
	FVector LandTangent;
	USummitKnightAreaDenialSphereComponent TargetArea;
	float LandedTime;
	float IgnitedTime;
	float CoolingDownTime;

	USummitKnightSettings Settings;
	USummitKnightComponent KnightComp;
	USummitKnightAreaDenialFireballLauncher FireballLauncher;

	void LaunchAt(USummitKnightAreaDenialSphereComponent AreaDenialTarget, USummitKnightAreaDenialFireballLauncher Launcher)
	{
		Settings = USummitKnightSettings::GetSettings(ProjectileComp.Launcher);
		KnightComp = USummitKnightComponent::Get(ProjectileComp.Launcher); 

		LandedTime = BIG_NUMBER;
		IgnitedTime = BIG_NUMBER;
		CoolingDownTime = BIG_NUMBER;

		LaunchLocation = ActorLocation;
		LaunchVelocity = ProjectileComp.Velocity;
		TargetArea = AreaDenialTarget;

		// Land at a random fairly steep angle
		FVector ToTarget = TargetArea.WorldLocation - LaunchLocation;
		FVector LandDir = Math::GetRandomConeDirection(ToTarget - FVector::UpVector * Settings.AreaDenialFireballSteepness, PI * 0.02);
		LandTangent = LandDir * Settings.AreaDenialFireballSteepness; 

		FSummitKnightAreaDenialFireballMeshParams Params;
		Params.Mesh = Mesh;
		USummitKnightAreaDenialFireballEventHandler::Trigger_OnLaunch(this, Params);

		ActorRotation = ToTarget.GetSafeNormal2D().Rotation();
		FireballLauncher = Launcher;
		FireballLauncher.ActiveFireballs.Add(this);
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		float CurTime = Time::GameTimeSeconds;
		if (CurTime > CoolingDownTime)
		{
			UpdateCoolingDown();
			return;
		}

		if (CurTime > IgnitedTime)
		{
			UpdateIgnited(DeltaTime);
			return;
		}	

		if (CurTime > LandedTime)
		{
			UpdateLanded();
			return;
		}
				
		// Local movement in flight
		float FlightDuration = Time::GetGameTimeSince(ProjectileComp.LaunchTime);
		float Alpha = Math::Min(FlightDuration / Settings.AreaDenialFireballFlightDuration, 1.0);
		FVector TargetLocation = TargetArea.WorldLocation;
		FVector NewLoc = BezierCurve::GetLocation_2CP_ConstantSpeed(LaunchLocation, LaunchLocation + LaunchVelocity, TargetLocation - LandTangent, TargetLocation, Alpha);
		SetActorLocation(NewLoc);

		if (FlightDuration > Settings.AreaDenialFireballFlightDuration) 
		{
			LandedTime = Time::GameTimeSeconds;
			USummitKnightAreaDenialFireballEventHandler::Trigger_OnLand(this);

			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (Player.HasControl() && ActorLocation.IsWithinDist(Player.ActorLocation, Settings.AreaDenialFireballLandDamageRadius))
				{
					// Damage and stumble are both networked internally
					Player.DamagePlayerHealth(Settings.AreaDenialFireballLandDamage);
					FVector StumbleMove = (Player.ActorLocation - ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector) * Settings.AreaDenialFireballLandStumbleDistance;
					KnightComp.StumbleDragon(Player, StumbleMove);

					FSummitKnightProjectileDamageParams DamageEventParams;
					DamageEventParams.Player = Player; 
					DamageEventParams.Damage = Settings.AreaDenialFireballLandDamage; 
					DamageEventParams.Direction = (Player.ActorLocation - ActorLocation).GetSafeNormal2D();
					USummitKnightProjectileDamageEventHandler::Trigger_OnPlayerDamage(this, DamageEventParams);
				}
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

	void UpdateLanded()
	{
		if (Time::GetGameTimeSince(LandedTime) > Settings.AreaDenialFireballIgnitionDuration)
		{
			FSummitKnightAreaDenialFireballIgnitionParams Kaboom;
			Kaboom.Location = TargetArea.WorldLocation;
			Kaboom.Radius = TargetArea.ScaledRadius;
			Kaboom.Mesh = Mesh;
			USummitKnightAreaDenialFireballEventHandler::Trigger_OnIgnite(this, Kaboom);
			IgnitedTime = Time::GameTimeSeconds;
		} 			
	}

	void UpdateIgnited(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.HasControl() && ActorLocation.IsWithinDist(Player.ActorLocation, TargetArea.ScaledSphereRadius))
			{
				Player.DealBatchedDamageOverTime(Settings.AreaDenialFireballDamagePerSecond * DeltaTime, FPlayerDeathDamageParams());

				FSummitKnightProjectileDamageParams DamageEventParams;
				DamageEventParams.Player = Player; 
				DamageEventParams.Damage = Settings.AreaDenialFireballDamagePerSecond * DeltaTime; 
				DamageEventParams.Direction = FVector::UpVector;
				USummitKnightProjectileDamageEventHandler::Trigger_OnPlayerDamage(this, DamageEventParams);
			}
		}

		if (Time::GetGameTimeSince(IgnitedTime) > Settings.AreaDenialFireballCooldownDuration - 5.0)
		{
			USummitKnightAreaDenialFireballEventHandler::Trigger_OnCooldown(this);
			CoolingDownTime = Time::GameTimeSeconds;
		}
	}

	void UpdateCoolingDown()
	{
		if (Time::GameTimeSeconds > CoolingDownTime + 5.0)
		{
			FireballLauncher.ActiveFireballs.Add(this);
			ProjectileComp.Expire();
		}
	}
}


struct FSummitKnightAreaDenialFireballMeshParams
{
	UPROPERTY()
	UStaticMeshComponent Mesh;
}

struct FSummitKnightAreaDenialFireballIgnitionParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	float Radius;

	UPROPERTY()
	UStaticMeshComponent Mesh;
}

UCLASS(Abstract)
class USummitKnightAreaDenialFireballEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(Transient, NotVisible)
	FVector DefaultScale = FVector::ZeroVector;

	UPROPERTY(Transient, NotVisible)
	UMaterialInterface DefaultMaterial = nullptr;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FSummitKnightAreaDenialFireballMeshParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIgnite(FSummitKnightAreaDenialFireballIgnitionParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCooldown() {}
}







