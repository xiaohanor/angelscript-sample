UCLASS(Abstract)
class ASummitBallFlyerProjectile : AHazeActor
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

	UPROPERTY(DefaultComponent)
	UHazeSphereCollisionComponent AcidHittableComp;
	default AcidHittableComp.SphereRadius = 50.0;
	default AcidHittableComp.CollisionProfileName = n"NoCollision";
	default AcidHittableComp.CollisionEnabled = ECollisionEnabled::QueryOnly;
	default AcidHittableComp.CollisionObjectType = ECollisionChannel::ECC_Destructible;
	default AcidHittableComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default AcidHittableComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default AcidHittableComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default AcidHittableComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceEnemy, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY()
	float RollSpeed = 5.0;

	UPROPERTY()
	float YawSpeed = 0.0;

	UBasicAIHealthComponent LauncherHealthComp = nullptr;
	USummitBallFlyerSettings Settings;
	bool bExpired = false;
	float AttackTime;
	FQuat TelegraphingRotation;
	float Angle = 0.0;
	float Roll = 0.0;

	FVector StartFlightLoc;
	FVector StartTangent;
	FVector TargetTangent;
	FVector TargetLoc;	
	float Speed;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (!ProjectileComp.bIsLaunched)
			return;
		if (Hit.PlayerInstigator.HasControl())
			CrumbExplode();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bExpired = false;
	}

	void Prepare(FVector SpawnLocation)
	{
		Settings = USummitBallFlyerSettings::GetSettings(ProjectileComp.Launcher);
		USummitBallFlyerProjectileEventHandler::Trigger_OnLaunch(this);
		AttackTime = BIG_NUMBER;
		AttachToActor(ProjectileComp.Launcher, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		LauncherHealthComp = UBasicAIHealthComponent::GetOrCreate(ProjectileComp.Launcher); 
		Speed = 0.0;
		SetActorLocation(SpawnLocation);
	}

	void Launch(float LaunchTangentSize, float StrikeTangentSize)
	{
		AttackTime = Time::GameTimeSeconds - SMALL_NUMBER;
		DetachFromActor();

		if (ProjectileComp.Target != nullptr)
		{
			// Launch towards target 
			StartFlightLoc = ActorLocation;
			TargetLoc = ProjectileComp.Target.ActorLocation;
			float LaunchYawOffset = ProjectileComp.Launcher.ActorTransform.InverseTransformPosition(ActorLocation).Rotation().Yaw;
			FRotator LaunchRot = (TargetLoc - ActorLocation).Rotation();
			LaunchRot.Yaw += LaunchYawOffset;
			LaunchRot.Pitch += 30.0 + Math::RandRange(-1.0, 1.0) * Settings.AttackScatterPitch;
			StartTangent = LaunchRot.Vector() * LaunchTangentSize;
			FRotator EndRot = LaunchRot;
			EndRot.Yaw -= 2.0 * LaunchYawOffset;
			EndRot.Pitch = -60.0 + Math::RandRange(-1.0, 1.0) * Settings.AttackScatterPitch; 
			TargetTangent = EndRot.Vector() * StrikeTangentSize;
			Speed = 1000.0; // Backup value;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) 
	{
		if (bExpired)
			return;

		// Roll projectile
		FRotator NewRot = ActorRotation;
		Roll = FRotator::NormalizeAxis(Roll + DeltaTime * 360.0 * RollSpeed);
		NewRot.Roll = Roll;
		
		FRotator MeshRot = Mesh.RelativeRotation;
		MeshRot.Yaw += DeltaTime * 360.0 * YawSpeed;
		Mesh.RelativeRotation = MeshRot;

		float CurTime = Time::GameTimeSeconds;
		if (CurTime < AttackTime)
		{
			// Just roll in place
			TelegraphingRotation = FQuat(NewRot);
			SetActorRotation(NewRot);

			// Autodestruct if launcher dies
			if ((LauncherHealthComp != nullptr) && LauncherHealthComp.IsDead() && HasControl())
				CrumbExpire();

			return;
		}
		
		// Local movement, if this is too obviously desynced we should crumb curve data
		FVector NewLoc = ActorLocation;
		if (CurTime < AttackTime + Settings.AttackProjectileFlightDuration)
		{
			// Fly along curve
			float Alpha = Math::EaseIn(0.0, 1.0, (CurTime - AttackTime) / Settings.AttackProjectileFlightDuration, 2.0);
			NewLoc = BezierCurve::GetLocation_2CP_ConstantSpeed(StartFlightLoc, StartFlightLoc + StartTangent, TargetLoc - TargetTangent, TargetLoc, Alpha);
			if (DeltaTime > 0.0)
				Speed = (NewLoc - ActorLocation).Size() / DeltaTime;
		}
		else
		{
			// Reached target location, continue along target tangent
			NewLoc = ActorLocation + TargetTangent.GetSafeNormal() * Speed * DeltaTime;
		}

		// Slerp pitch and yaw to align with curve
		float Alpha = Math::EaseInOut(0.0, 1.0, Math::Min(1.0, Time::GetGameTimeSince(AttackTime) * 1.5), 3.0);
		FRotator SlerpedRot = FQuat::Slerp(TelegraphingRotation, (NewLoc - ActorLocation).ToOrientationQuat(), Alpha).Rotator();		
		NewRot.Yaw = SlerpedRot.Yaw;
		NewRot.Pitch = SlerpedRot.Pitch;
		SetActorRotation(NewRot);

		if ((CurTime > AttackTime + Settings.AttackProjectileFlightDuration + 2.0) && (HasControl()))
		{
			// Time out!
			CrumbExplode();
			return;
		}

		// Trigger if any player is near
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.HasControl() && Player.ActorLocation.IsWithinDist(ActorLocation, Settings.AttackProjectileExplodeRadius))
			{
				CrumbExplode();
				return;
			}
		}

		// Ignore collision during start of flight
		if (CurTime > AttackTime + Settings.AttackProjectileFlightDuration * 0.5)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseLine();
			FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, NewLoc);
			if (Hit.bBlockingHit)
			{
				SetActorLocation(Hit.Location);
				if (HasControl())
					CrumbExplode();
				return;
			}
		}
		// Move!
		SetActorLocation(NewLoc);
	}

	UFUNCTION(CrumbFunction)
	void CrumbExpire()
	{
		if (bExpired)
			return; // Only trigger once per respawn (we can trigger from either side in network)
		ProjectileComp.Expire();
		USummitBallFlyerProjectileEventHandler::Trigger_OnExpireNoExplosion(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbExplode()
	{
		if (bExpired)
			return; // Only trigger once per respawn (we can trigger from either side in network)

		ProjectileComp.Expire();

		USummitBallFlyerProjectileEventHandler::Trigger_OnExplode(this);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;

			// Deal damage nearby
			float DamageFactor = Damage::GetRadialDamageFactor(Player.ActorLocation, ActorLocation, Settings.AttackProjectileDamageRadius);
			if (DamageFactor > 0.0)
			{
				Player.DamagePlayerHealth(Settings.AttackProjectileDamage * DamageFactor);
				Player.AddDamageInvulnerability(this, Settings.AttackProjectileDamageCooldown);
			}
		}	
	}
}

UCLASS(Abstract)
class USummitBallFlyerProjectileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpireNoExplosion() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {};
}
