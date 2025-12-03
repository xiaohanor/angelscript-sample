UCLASS(Abstract)
class ASummitSmashapultGlob : AHazeActor
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
	default ProjectileComp.Friction = 0.0;
	default ProjectileComp.Gravity = 982.0;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeSphereCollisionComponent AcidHittableComp;
	default AcidHittableComp.SphereRadius = 150.0;
	default AcidHittableComp.CollisionProfileName = n"NoCollision";
	default AcidHittableComp.CollisionEnabled = ECollisionEnabled::QueryOnly;
	default AcidHittableComp.CollisionObjectType = ECollisionChannel::ECC_Destructible;
	default AcidHittableComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);
	default AcidHittableComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceZoe, ECollisionResponse::ECR_Block);
	default AcidHittableComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTracePlayer, ECollisionResponse::ECR_Block);
	default AcidHittableComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceEnemy, ECollisionResponse::ECR_Ignore);

	USummitSmashapultSettings Settings;
	FSplinePosition DragonSplinePos;
	USummitTeenDragonRollingLiftComponent DragonLiftComp;
	AHazeActor Target;

	float LobbedTime = BIG_NUMBER;
	bool bSplattered = false;
	bool bLanded = false;
	FVector BaseScale = FVector::OneVector;
	float LandedDuration = 0.0;
	float LandedHeight;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		BaseScale = ActorScale3D;
	}

	void PrimeGlob()
	{
		Settings = USummitSmashapultSettings::GetSettings(ProjectileComp.Launcher);
		USummitSmashapultGlobEventHandler::Trigger_OnPrime(this);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Target = nullptr;
		LobbedTime = BIG_NUMBER;
		bSplattered = false;
		bLanded = false;
		LandedDuration = 0.0;
		ProjectileComp.Reset();
		SetActorScale3D(BaseScale);
	}

	void LobGlob(FVector Velocity)
	{
		USummitSmashapultGlobEventHandler::Trigger_OnLaunch(this);
		LobbedTime = Time::GameTimeSeconds;
		ProjectileComp.Velocity = Velocity;
		ProjectileComp.Gravity = Settings.ProjectileGravity;
		Target = Game::Zoe;

		DragonLiftComp = USummitTeenDragonRollingLiftComponent::Get(Target);
		if (DragonLiftComp.CurrentSpline != nullptr)
			DragonSplinePos = DragonLiftComp.CurrentSpline.GetClosestSplinePositionToWorldLocation(Target.ActorLocation);
		else
			DragonSplinePos = FSplinePosition();

		auto RollingComp = USummitTeenDragonRollingLiftComponent::Get(Target);
		if ((RollingComp != nullptr) && (RollingComp.CurrentRollingLift != nullptr))
			Target = RollingComp.CurrentRollingLift;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) 
	{
		if (Target == nullptr)
			return;

		if (bSplattered)
			return;
		
		if (LobbedTime == BIG_NUMBER)
			return;	


		// Update target spline position (note that if taret moves off spline, we use last spline position)
		if (DragonLiftComp.CurrentSpline != nullptr)
		{
			float Delta = DragonSplinePos.WorldForwardVector.DotProduct(Target.ActorLocation - DragonSplinePos.WorldLocation);
			DragonSplinePos.Move(Delta);
		}

		FVector TargetLoc = Target.ActorLocation;
		float LobbedDuration = Time::GetGameTimeSince(LobbedTime);
		if (HasControl())
		{
			if ((LandedDuration > Settings.ProjectileExplodeTime) || (LobbedDuration > Settings.ProjectileExplodeTime + 4.0))
			{
				// Time is up!
				CrumbDetonate(Target);
				return;
			}
			if ((ProjectileComp.Velocity.Z < 0.0) && (ActorLocation.Z < TargetLoc.Z - 1500.0))
			{
				// Falling far below target, likely missed the ground
				CrumbDetonate(Target);
				return;
			}
		}

		if (bLanded)
		{
			// Stay in place, detonate if target is near.
			LandedDuration += DeltaTime;

			if (!Target.HasControl())
				return;
			if (IsTargetInRange(Settings.ProjectileBlastRadius * Settings.ProjectileDetonationFraction))
				CrumbDetonate(Target);

			// Wobble size
			float WobbleScale = 1.0 + 0.4 * Math::Sin(LandedDuration * 6.28) + LandedDuration * 0.2;
			SetActorScale3D(BaseScale * WobbleScale);

			// Push out of ground
			float TargetHeight = LandedHeight + ActorScale3D.Z * 120;
			float SpeedFactor = Math::Sin(0.5 * 3.15 * LandedDuration / Settings.ProjectileExplodeTime);
			float HeightDelta = TargetHeight - ActorLocation.Z;
			SetActorLocation(ActorLocation + FVector(0.0, 0.0, HeightDelta * SpeedFactor * DeltaTime));
			return; 
		}

		// Ignore initial collision
		bool bIgnoreCollision = (LobbedDuration < 0.5);

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit, bIgnoreCollision));
		if (Hit.bBlockingHit)
		{
			bLanded = true;
			LandedHeight = ActorLocation.Z;
		}
	}

	bool IsTargetInRange(float Range)
	{
		if (Target == nullptr)
			return false;

		FVector TargetLoc = Target.ActorLocation;
		if (ActorLocation.IsWithinDist(TargetLoc, Range))
			return true;

		if ((DragonLiftComp != nullptr) && (DragonLiftComp.CurrentSpline != nullptr))
		{
			// Are we within spline distance from target?
			float SplineDistance = DragonSplinePos.WorldForwardVector.DotProduct(TargetLoc - ActorLocation);
			if (Math::Abs(SplineDistance) < Range)
				return true;
		}

		return false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbDetonate(AHazeActor DetonationTarget)
	{
		Target = DetonationTarget;
		if (bSplattered)
			return; // Only explode once per respawn (we can explode from either side in network)

		bSplattered = true;
		ProjectileComp.Expire();
		USummitSmashapultGlobEventHandler::Trigger_OnSplatter(this);

		if (DetonationTarget == nullptr)
			return;
		
		auto Driver = Game::Zoe;
		
		auto RollingComp = USummitTeenDragonRollingLiftComponent::Get(Driver);
		if (RollingComp == nullptr)
			return;

		auto MoveComp = UHazeMovementComponent::Get(Driver);

		if (IsTargetInRange(Settings.ProjectileBlastRadius))
		{
			// Push lift away from explosion (along rolling direction)
			FVector RollDir = Target.ActorForwardVector;
			if (DragonSplinePos.CurrentSpline != nullptr)
			 	RollDir = DragonSplinePos.WorldForwardVector;
			float PushForce = Settings.ProjectileBlastPushForce;
			FVector FromBlast = (Target.ActorLocation - ActorLocation).ProjectOnTo(RollDir);
			if (FromBlast.IsNearlyZero(100.0)) // When very close to center, push backwards
				FromBlast = -RollDir;
			else if (FromBlast.DotProduct(RollDir) > 0.0)
				PushForce *= 0.2; // Reduce forwards push
			FVector Impulse = FromBlast.GetSafeNormal() * PushForce;
			MoveComp.AddPendingImpulse(Impulse);
			//RollingComp.CustomImpulses.Add(Impulse);

			AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(Target);
			if (PlayerTarget != nullptr)
				PlayerTarget.DamagePlayerHealth(Settings.ProjectileDamage);		
		}

		Target = nullptr;
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (!Hit.PlayerInstigator.HasControl())
			return;
		CrumbDissolveByAcid();
	}

	UFUNCTION(CrumbFunction)
	void CrumbDissolveByAcid()
	{
		if (bSplattered)
			return; // Only explode once per respawn (we can explode from either side in network)

		// Note that We do not set bSplattered here: if projectile detonates on Zoe side while 
		// it's being hit by acid on Mio side we still want Zoe to be affected by tha blast.
		ProjectileComp.Expire();
		USummitSmashapultGlobEventHandler::Trigger_OnDissolveByAcid(this);
	}
}
