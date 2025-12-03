event void FOnTrainFlyingEnemyCrash();

struct FTrainFlyingEnemyTargetingParams
{
	AHazePlayerCharacter TargetPlayer;
	ACoastTrainCart TargetCart;
	FVector TargetOffset;
};

UCLASS(Abstract)
class ATrainFlyingEnemy : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_HazeInput;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootSceneComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent RidingPlayerBox;
	default RidingPlayerBox.CollisionEnabled = ECollisionEnabled::NoCollision;
	default RidingPlayerBox.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UOneShotInteractionComponent DestroyInteraction;
	default DestroyInteraction.bUseLazyTriggerShapes = true;

	// UPROPERTY(DefaultComponent, Attach = Mesh)
	// UTrainFlyingEnemyForceFieldComponent ForceField;
	
	UPROPERTY(DefaultComponent, Attach = Mesh)
	UAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"TrainFlyingEnemyTargetPlayerCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TrainFlyingEnemyHoverMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TrainFlyingEnemyCrashCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TrainFlyingEnemyAttackCapability");
	// default CapabilityComp.DefaultCapabilities.Add(n"TrainFlyingEnemyForcefieldCapability");

	UPROPERTY(DefaultComponent)
	UCoastShoulderTurretGunResponseComponent DamageResponseComp;

	UPROPERTY(DefaultComponent)
	UBasicBehaviourComponent BehaviourComp;	

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent CrumbLocation;
	default CrumbLocation.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent CrumbRotation;
	default CrumbRotation.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(EditInstanceOnly)
	ACoastTrainCart TrainCart;

	// Camera settings to use while the player is on the flying car
	UPROPERTY(EditAnywhere, Category = "Camera Settings")
	UHazeCameraSettingsDataAsset CameraSettingsOnCar;

	// Blend time when applying camera settings for players on the car
	UPROPERTY(EditAnywhere, Category = "Camera Settings")
	float CameraSettingsOnCarBlendTime = 0.5;

	// Camera shake played while the car is crashing
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CrashingCameraShake;

	// Camera settings for player on top of crashing car
	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CrashingCameraSettings;

	// Camera shake played when the car explodes
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ExplodesCameraShake;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UGrapplePointComponent GrapplePoint;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent ProjectileSpawnPoint;

	UPROPERTY(Category = "Crashing")
	FOnTrainFlyingEnemyCrash OnCrash;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UDummyVisualizationComponent VisualizerComp;
	default VisualizerComp.Color = FLinearColor::Yellow;
#endif	

	UPROPERTY()
	TSubclassOf<ATrainFlyingEnemyProjectile> ProjectileType;

	UTrainFlyingEnemySettings Settings;
	bool bDestroyedByPlayer = false;
	bool bRetarget = false;
	bool bIsFlyingIn = true;
	FTrainFlyingEnemyTargetingParams Target;
	FVector HoverOffset;
	FRotator WantedTargetRotation;
	TPerPlayer<bool> PlayerIsOnCar;
	FVector SplineOffset;
	bool bReposition = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR		
		VisualizerComp.ConnectedActors.Empty(1);
		if (TrainCart != nullptr)
			VisualizerComp.ConnectedActors.Add(TrainCart);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UTrainFlyingEnemySettings::GetSettings(this);

		DestroyInteraction.OnOneShotBlendingOut.AddUFunction(this, n"EnemyDestroyed");
		AddActorDisable(this);
		DamageResponseComp.OnBulletHit.AddUFunction(this, n"OnHitByTurret");

		// Place actor at train cart spline, offset mesh
		if (!devEnsure(TrainCart != nullptr, "" + Name + " does not have a train cart, will not function correctly."))
			return;

		// Place actor at spline, offset mesh to where actor was placed
		UHazeSplineComponent SplineComp = TrainCart.RailSpline;
		FTransform SplineTransform = SplineComp.GetClosestSplineWorldTransformToWorldLocation(ActorLocation);
		SplineOffset = SplineTransform.InverseTransformPosition(Mesh.WorldLocation);
	}

	UFUNCTION()
	private void OnHitByTurret(FCoastShoulderTurretBulletHitParams Params)
	{
		// if (!ForceField.IsDepleted())
		// 	return;
		HealthComp.TakeDamage(Settings.DamageFromTurretsFactor * Params.Damage, EDamageType::Projectile, Params.PlayerInstigator);
		if (HealthComp.IsDead())
		 	DestroySelf();
	}

	UFUNCTION()
	void EnemyDestroyed(AHazePlayerCharacter Player, UOneShotInteractionComponent Interaction)
	{
		DestroySelf();
	}

	void DestroySelf()
	{
		bDestroyedByPlayer = true;
		DestroyInteraction.Disable(n"EnemyDestroyed");
		GrapplePoint.Disable(n"Destroyed");

		for (auto CheckPlayer : Game::Players)
			CheckPlayer.ClearCameraSettingsByInstigator(this);

		OnCrash.Broadcast();
	}

	bool IsPlayerOnTopOfCar(AHazePlayerCharacter Player) const
	{
		FHazeShapeSettings ShapeSettings;
		ShapeSettings.InitializeAsBox(RidingPlayerBox.BoxExtent);
		return ShapeSettings.IsPointInside(RidingPlayerBox.WorldTransform, Player.ActorLocation);
	}

	bool IsPlayerInLineOfSight(AHazePlayerCharacter Player)
	{
		FHazeTraceSettings Trace;
		Trace.TraceWithChannel(ECollisionChannel::ECC_Visibility);
		Trace.UseLine();
		Trace.IgnoreActor(Player);
		Trace.IgnoreActor(Player.OtherPlayer);
		Trace.IgnoreActor(this);

		FHitResult Hit = Trace.QueryTraceSingle(
			ActorLocation + FVector(0.0, 0.0, 5000.0), Player.ActorLocation
		);
		return !Hit.bBlockingHit;
	}

	UFUNCTION(DevFunction)
	void StartCarMio()
	{
		ActivateCar(Game::Mio);
	}

	UFUNCTION(DevFunction)
	void StartCarZoe()
	{
		ActivateCar(Game::Zoe);
	}

	UFUNCTION()
	void ActivateCar(AHazePlayerCharacter EnteringTargetPlayer)
	{
		if (EnteringTargetPlayer == nullptr)
			return;
		
		RemoveActorDisable(this);

		ACoastTrainCart Cart = TrainCart.Driver.GetCartClosestToPlayer(EnteringTargetPlayer);
		if (Cart != nullptr)
		{
			Target.TargetPlayer = EnteringTargetPlayer;
			Target.TargetCart = Cart;
			Target.TargetOffset = Cart.CurrentPosition.WorldTransform.InverseTransformPositionNoScale(EnteringTargetPlayer.ActorLocation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::Players)
		{
			if (IsPlayerOnTopOfCar(Player))
			{
				if (!PlayerIsOnCar[Player])
				{
					// GrapplePoint.DisableForPlayer(Player, n"OnTopOfCar");
					Player.ApplyCameraSettings(CameraSettingsOnCar, Settings.OnCarCameraSettingsBlendtime, this, EHazeCameraPriority::Medium, 120);
					PlayerIsOnCar[Player] = true;
				}
			}
			else
			{
				if (PlayerIsOnCar[Player])
				{
					// GrapplePoint.EnableForPlayer(Player, n"OnTopOfCar");
					Player.ClearCameraSettingsByInstigator(this);
					PlayerIsOnCar[Player] = false;
				}
			}
		}
	}
}