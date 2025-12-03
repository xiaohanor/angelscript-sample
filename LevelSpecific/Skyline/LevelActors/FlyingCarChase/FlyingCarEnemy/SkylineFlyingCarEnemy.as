event void FOnEnemyEnabledSignature();
class ASkylineFlyingCarEnemy : AHazeActor
{
	access Resolver = private, USkylineFlyingCarEnemyMovementResolver, USkylineFlyingCarImpactMovementResolverExtension;

	default PrimaryActorTick.bStartWithTickEnabled = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereCollision;
	default SphereCollision.SphereRadius = 300.0;
	default SphereCollision.SetCollisionProfileName(n"EnemyCharacter");
	default SphereCollision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent VisualRoot;

	UPROPERTY(DefaultComponent, Attach = VisualRoot)
	UBasicAIProjectileLauncherComponent ProjectileLauncherComponent;
	

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarRifleTargetableComponent RifleTargetableComponent;
	default RifleTargetableComponent.WidgetVisualOffset = FVector::UpVector * 600;


	UPROPERTY(DefaultComponent)
	USkylineFlyingCarBazookaTargetableComponent BazookaTargetableComponent;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarBazookaResponseComponent BazookaResponseComponent;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	FOnEnemyEnabledSignature OnEnemyEnabled;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnableComponent;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComponent;

//	UPROPERTY(DefaultComponent)
//	UBasicAIHealthBarComponent HealthBarComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineFlyingCarEnemyMovementCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineFlyingCarEnemyShootCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineFlyingCarEnemyAvoidanceCapability");

	UPROPERTY(EditAnywhere)
	ASkylineFlyingCarEnemyManager EnemyManager;

	UPROPERTY(EditAnywhere)
	float Acceleration = 8000.0;

	UPROPERTY(EditAnywhere)
	float Drag = 2.0;

	UPROPERTY(EditAnywhere)
	AHazeActor FollowTarget;

	UPROPERTY(EditAnywhere)
	AActorTrigger Trigger;

	UPROPERTY(EditAnywhere)
	float DistanceFromTarget = -3000.0;

	UPROPERTY(EditAnywhere)
	FVector DesiredOffsetOnSpline;

	UPROPERTY(EditInstanceOnly)
	AActor ActorWithSpline;
	UHazeSplineComponent Spline;

	UPROPERTY(EditAnywhere)
	bool bStartDisabled;

	UPROPERTY(EditDefaultsOnly)
	bool bShouldLookAtPlayer = false;

	UPROPERTY(EditDefaultsOnly)
	FVector HealthBarWidgetOffset = FVector::UpVector * 500;

	FVector AngularVelocity;
	float AngularDrag = 4.0;

	FVector Avoidance;

	UBasicAIHealthBarComponent HealthBarComponent;

	// Updated by movement capability
	float CurrentDistanceToTarget = BIG_NUMBER;

	FHazeAcceleratedQuat AccVisualRotation;

	UPROPERTY(EditDefaultsOnly, Category = "Bazooka")
	float LinearImpulseFromBazooka = 5000;

	UPROPERTY(EditDefaultsOnly, Category = "Bazooka")
	float AngularImpulseFromBazooka = 3;

	UFUNCTION(BlueprintEvent)
	void BP_Damage() {}

	UFUNCTION(BlueprintEvent)
	void BP_Explode() {}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		HealthComponent.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		BazookaResponseComponent.OnHit.AddUFunction(this, n"OnHitByBazooka");
		RespawnableComponent.OnRespawn.AddUFunction(this, n"OnReset");

		if (ActorWithSpline != nullptr)
		{
			Spline = Spline::GetGameplaySpline(ActorWithSpline, this);
		}
		else
			Print("ActorWithoutSpline:" + this);
		if (Trigger != nullptr)
			Trigger.OnActorEnter.AddUFunction(this, n"OnTriggered");

		if (bStartDisabled)
			AddActorDisable(this);

		HealthBarComponent = UBasicAIHealthBarComponent::Get(this);
		if (HealthBarComponent != nullptr)
		{
			auto Settings = UBasicAIHealthBarSettings::GetSettings(this);
			Settings.HealthBarOffset = HealthBarWidgetOffset;

			HealthBarComponent.SetPlayerVisibility(EHazeSelectPlayer::Mio);

			HealthBarComponent.ShouldShowHealthBarDelegate.BindUFunction(this, n"ShouldShowHealthBar");
		}

		MovementComponent.SetupShapeComponent(SphereCollision);
		AccVisualRotation.SnapTo(VisualRoot.RelativeRotation.Quaternion());
	}

	UFUNCTION()
	private void OnReset()
	{
		// PrintScaled("OnReset!", 2.0, FLinearColor::Green);

//		DesiredOffsetOnSpline = RespawnableComponent.SpawnParameters.Location;

//		if (RespawnableComponent.SpawnParameters.Scenepoint != nullptr)

		if (RespawnableComponent.SpawnParameters.Spline != nullptr)
			Spline = RespawnableComponent.SpawnParameters.Spline;

		RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	PrintScaled("DesiredOffsetOnSpline:" + DesiredOffsetOnSpline, 0.0, FLinearColor::Green);
		// Get car, there should only be one in the level!
		if (FollowTarget == nullptr)
			FollowTarget = TListedActors<ASkylineFlyingCar>().GetSingle();

		if (Spline == nullptr)
			Spline = RespawnableComponent.SpawnParameters.Spline;

		if (HealthBarComponent != nullptr)
			HealthBarComponent.UpdateHealthBarVisibility();

		if (bInPlayerSights)
		{
			if (CurrentDistanceToTarget > RifleTargetableComponent.MaximumDistance)
				bInPlayerSights = false;
		}
		else
		{
			if (CurrentDistanceToTarget < RifleTargetableComponent.MaximumDistance)
			{
				bInPlayerSights = true;
				UFlyingCarEnemyEventHandler::Trigger_OnWidgetAdd(this);
			}
		}
	}

	bool bInPlayerSights;

	UPROPERTY(EditAnywhere)
	bool bShouldExplodeAtEndOfSpline = false;

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		BP_Damage();

		if (HealthComponent.IsDead())
		{
			Explode();
		}
		else
		{
			FFlyingCarEnemyDamageData DamageData;
			DamageData.DamageAmount = Damage;
			DamageData.RemainingHealth = HealthComponent.CurrentHealth;

			UFlyingCarEnemyEventHandler::Trigger_OnTakeDamage(this, DamageData);
		}
	}

	UFUNCTION()
	private void OnHitByBazooka(FVector ImpactPoint, FVector ImpulseDirection)
	{
		MovementComponent.AddPendingImpulse(ImpulseDirection * LinearImpulseFromBazooka);
		AddImpulseAsAngularImpulse(ImpulseDirection * AngularImpulseFromBazooka);
	}

	UFUNCTION()
	void Explode()
	{
		BP_Explode();
		Disable();
		UFlyingCarEnemyEventHandler::Trigger_OnDestroyed(this, FFlyingCarEnemyDestroyedData(VisualRoot));
		
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		HealthComponent.Die();
		RespawnableComponent.UnSpawn();
		AddActorDisable(this);

		// AddActorDisable(this);

	//	DestroyActor();
	}

	UFUNCTION()
	private void OnTriggered(AHazeActor Actor)
	{
		if(EnemyManager.CanAddEnemy(this))
		{
			EnemyManager.AddEnemy();
			Enable();
		}
	}

	UFUNCTION(BlueprintEvent)
	void Enable()
	{
		OnEnemyEnabled.Broadcast();
		RemoveActorDisable(this);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, false, true);
		for(auto AttachedActor : AttachedActors)
		{
			AttachedActor.RemoveActorDisable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, false, true);
		for(auto AttachedActor : AttachedActors)
		{
			AttachedActor.AddActorDisable(this);
		}
	}


	UFUNCTION()
	void Disable()
	{
		if (EnemyManager != nullptr)
			EnemyManager.RemoveEnemy();

		// AddActorDisable(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private bool ShouldShowHealthBar()
	{
		if (CurrentDistanceToTarget > RifleTargetableComponent.MaximumDistance)
			return false;

		return true;
	}

	/**
	 * We hit something!
	 */
	access:Resolver
	void OnImpactOther(USkylineFlyingCarImpactResponseComponent ResponseComp, FFlyingCarOnImpactData ImpactData)
	{
		if(!ensure(HasControl()))
			return;

		CrumbOnImpactOther(ResponseComp, ImpactData);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnImpactOther(USkylineFlyingCarImpactResponseComponent ResponseComp, FFlyingCarOnImpactData ImpactData)
	{
		FVector Deceleration = MovementComponent.Velocity - MovementComponent.PreviousVelocity;
		AddImpulseAsAngularImpulse(Deceleration.GetSafeNormal() * -5);
	}

	access:Resolver
	void OnHitOtherCar(FVector HitOtherCarImpulse, FVector HitOtherCarImpactPoint, ASkylineFlyingCarEnemy OtherCar)
	{
		if(!ensure(HasControl()))
			return;

		CrumbOnHitOtherCar(HitOtherCarImpulse, HitOtherCarImpactPoint, OtherCar);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnHitOtherCar(FVector HitOtherCarImpulse, FVector HitOtherCarImpactPoint, ASkylineFlyingCarEnemy OtherCar)
	{
		AddImpulseAsAngularImpulse(HitOtherCarImpulse.GetSafeNormal() * -SkylineFlyingCarEnemy::HitOtherCarAngularImpulse);

		OtherCar.AddMovementImpulse(-HitOtherCarImpulse);
		OtherCar.AddImpulseAsAngularImpulse(HitOtherCarImpulse.GetSafeNormal() * SkylineFlyingCarEnemy::HitOtherCarAngularImpulse);

		{
			const FFlyingCarEnemyOnHitOtherCarEventData EventData(
				HitOtherCarImpulse,
				HitOtherCarImpactPoint,
				OtherCar
			);
			UFlyingCarEnemyEventHandler::Trigger_OnHitOtherCar(this, EventData);
		}

		{
			const FFlyingCarEnemyOnHitOtherCarEventData EventData(
				-HitOtherCarImpulse,
				HitOtherCarImpactPoint,
				this
			);
			UFlyingCarEnemyEventHandler::Trigger_OnHitByOtherCar(OtherCar, EventData);
		}
	}

	access:Resolver
	void OnExplodeFromWallImpact()
	{
		if(!ensure(HasControl()))
			return;

		CrumbExplodeFromWallImpact();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbExplodeFromWallImpact()
	{
		Explode();
	}

	access:Resolver
	void OnReflectOffWall(FVector ReflectionImpulse, FVector WallImpactPoint, FVector WallImpactNormal)
	{
		if(!ensure(HasControl()))
			return;

		CrumbOnReflectOffWall(ReflectionImpulse, WallImpactPoint, WallImpactNormal);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnReflectOffWall(FVector ReflectionImpulse, FVector WallImpactPoint, FVector WallImpactNormal)
	{
		AddImpulseAsAngularImpulse(ReflectionImpulse.GetSafeNormal() * -SkylineFlyingCarEnemy::ReflectOffWallAngularImpulse);

		const FFlyingCarEnemyOnReflectOffWallEventData EventData(
			ReflectionImpulse,
			WallImpactPoint,
			WallImpactNormal	
		);

		UFlyingCarEnemyEventHandler::Trigger_OnReflectOffWall(this, EventData);
	}

	void AddImpulseAsAngularImpulse(FVector LinearImpulse)
	{
		if(LinearImpulse.IsNearlyZero())
			return;

		const FVector AngularImpulse = ActorUpVector.CrossProduct(LinearImpulse);
		AccVisualRotation.VelocityAxisAngle += AngularImpulse;
	}
}

class ASkylineFlyingCarEnemyWithTurret : ASkylineFlyingCarEnemy
{
	default CapabilityComponent.DefaultCapabilities.Remove(n"SkylineFlyingCarEnemyShootCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineFlyingCarEnemyFireTurretCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineFlyingCarEnemyReloadCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineFlyingCarEnemyRotateCapability");

	default bShouldExplodeAtEndOfSpline = true;

	UPROPERTY(Category = "Lights")
	float LightsRotationSpeed = 360.0;
	
	UPROPERTY(DefaultComponent, Attach = VisualRoot)
	USkylineFlyingCarEnemyTurretComponent TurretComp;

	UPROPERTY(DefaultComponent, Attach = TurretComp)
	USceneComponent TurretYawPivot;

	UPROPERTY(DefaultComponent, Attach = TurretYawPivot)
	USceneComponent TurretPitchPivot;

	UPROPERTY(DefaultComponent, Attach = VisualRoot)
	USceneComponent LightsRotationPivot;

	UPROPERTY(DefaultComponent, Attach = TurretPitchPivot)
	USkylineFlyingCarEnemyTurretMuzzleComponent TurretLeftMuzzleComp;

	UPROPERTY(DefaultComponent, Attach = TurretPitchPivot)
	USkylineFlyingCarEnemyTurretMuzzleComponent TurretRightMuzzleComp;
}

class ASkylineFlyingCarEnemyStaticWithTurret : ASkylineFlyingCarEnemyWithTurret
{
	default CapabilityComponent.DefaultCapabilities.Remove(n"SkylineFlyingCarEnemyShootCapability");
	default CapabilityComponent.DefaultCapabilities.Remove(n"SkylineFlyingCarEnemyMovementCapability");
	default CapabilityComponent.DefaultCapabilities.Remove(n"SkylineFlyingCarEnemyAvoidanceCapability");

	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineFlyingCarEnemyBobbingCapability");

	default bShouldExplodeAtEndOfSpline = false;
}


class ASkylineFlyingCarEnemyShip : ASkylineFlyingCarEnemy
{
	default CapabilityComponent.DefaultCapabilities.Remove(n"SkylineFlyingCarEnemyShootCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineFlyingCarEnemyBurstFireCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineFlyingCarEnemyAimCapability");

	UPROPERTY(EditAnywhere)
	USkylineFlyingCarEnemyShipSettings Settings;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarEnemyTrackingLaserComponent TrackingLaserComp;
	
	UPROPERTY(DefaultComponent, Attach = VisualRoot)
	USceneComponent CannonPivot;

	UPROPERTY(DefaultComponent, Attach = CannonPivot)
	USceneComponent LaserPivot;
	
	// Used instead of base class' launcher component for attaching to cannon pivot.
	UPROPERTY(DefaultComponent, Attach = CannonPivot)
	UBasicAIProjectileLauncherComponent LeftCannonProjectileLauncherComponent;

		// Used instead of base class' launcher component for attaching to cannon pivot.
	UPROPERTY(DefaultComponent, Attach = CannonPivot)
	UBasicAIProjectileLauncherComponent RightCannonProjectileLauncherComponent;
}