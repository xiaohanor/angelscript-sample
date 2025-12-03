event void FOnMeltdownBossRainAttackDone();
event void FOnMeltdownBossRainAttackForVO();

enum EMeltdownBossPhaseThreeRainTargetingType
{
	// Randomized position in the arena
	RandomPosition,
	// Target a random player
	RandomPlayer,
	// Always target mio
	Mio,
	// Always target zoe
	Zoe,
}

struct FMeltdownBossPhaseThreeRainConfig
{
	UPROPERTY()
	float StartLaunchingDelay = 1.0;
	UPROPERTY()
	float LaunchInterval = 1.0;
	UPROPERTY(EditAnywhere)
	float MaxDistanceFromSpline = 100.0;

	UPROPERTY()
	EMeltdownBossPhaseThreeRainTargetingType TargetingType = EMeltdownBossPhaseThreeRainTargetingType::RandomPosition;

	// Predict the player's velocity forward in time for the targeting (only used when targeting player)
	UPROPERTY()
	float TargetingPredictionTime = 0.0;
	UPROPERTY()
	float TargetingPredictionDistance = 0.0;
}

struct FMeltdownBossPhaseThreeRainInstance
{
	float RemainingInterval = 0;
	FMeltdownBossPhaseThreeRainConfig Config;
}

class AMeltdownBossPhaseThreeRainAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent BlockingLeftGauntlet;
	default BlockingLeftGauntlet.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent BlockingRightGauntlet;
	default BlockingRightGauntlet.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent BlockingHydra;
	default BlockingHydra.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase HydraMesh;
	
	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase LeftGauntletMesh;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase RightGauntletMesh;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase PortalMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent LaunchLocation;

	UPROPERTY(DefaultComponent)
	USceneComponent StopLocation;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent PortalDamageTrigger;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent AudioMoveComp;

	UPROPERTY(EditAnywhere)
	USkeletalMesh DecapitatedHydra;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem HeadBleeding;

	UPROPERTY()
	TSubclassOf<AMeltdownBossPhaseThreeRainProjectile> ProjectileClass;

	UPROPERTY()
	FOnMeltdownBossRainAttackDone OnAttackDone;

	UPROPERTY(EditInstanceOnly)
	AMeltdownPhaseThreeBoss Rader;

	UPROPERTY()
	FPlayerLaunchToParameters LaunchParams;

	UPROPERTY(EditAnywhere)
	AMeltdownGlitchShootingPickup AvoidLocation;
	UPROPERTY(EditAnywhere)
	float AvoidLocationRadius = 600;

	TArray<FMeltdownBossPhaseThreeRainInstance> AttackInstances;
	bool bAttackFinished = false;

	bool bStartTrace;

	bool bStopProjectiles;

	UPROPERTY()
	UTexture2D PortalTextureCrystalGauntlet;
	UPROPERTY()
	UTexture2D PortalTextureHydra;

	UPROPERTY()
	FOnMeltdownBossRainAttackForVO OnGrabbingHydra;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		PortalDamageTrigger.DisableDamageTrigger(this);

		LaunchParams.LaunchToLocation = LaunchLocation.WorldLocation;
		
		// Reset portal clipping
		Material::SetVectorParameterValue(Rader.GlobalParameters, n"RaderPortalClipSphere0", FLinearColor(0, 0, 0, 0));
		Rader.SetPortalState(PortalMesh, PortalTextureCrystalGauntlet);

		HydraMesh.SetScalarParameterValueOnMaterials(n"bIsSwallowHydra", 1.0f);
		HydraMesh.SetScalarParameterValueOnMaterials(n"ThroatHidePlaneOffset", 3000.0f);
		HydraMesh.SetHiddenInGame(true);
	}

	UFUNCTION(DevFunction)
	void Launch()
	{
		Rader.CurrentLocomotionTag = n"HydraPortal";
		RemoveActorDisable(this);


		Rader.ActionQueue.Idle(0.1);
		Rader.ActionQueue.Event(this, n"SetPortalHideLocation");
		Rader.ActionQueue.Idle(2.8);
		Rader.ActionQueue.Event(this, n"HideRightHand");
		Rader.ActionQueue.Idle(2.4);
		Rader.ActionQueue.Event(this, n"HideLeftHand");
		Rader.ActionQueue.Idle(1.7);
		Rader.ActionQueue.Event(this, n"OpenGroundPortal");
		Rader.ActionQueue.Idle(3.0);
		Rader.ActionQueue.Event(this, n"ShowHydra");
		Rader.ActionQueue.Event(this, n"ActivateCollision");
		Rader.ActionQueue.Idle(1.0);
		Rader.ActionQueue.Event(this, n"StartSpawningProjectiles");
	}

	UFUNCTION(DevFunction)
	void StopAttacking()
	{
		bStopProjectiles = true;
		Rader.ActionQueue.Event(this, n"StartAttackExit");
		Rader.ActionQueue.Idle(5.0);
		Rader.ActionQueue.Event(this, n"OnFinished");
	}

	UFUNCTION()
	private void SetPortalHideLocation()
	{
		if(Rader.GlobalParameters == nullptr)
			return;
		
 		FVector Pos = PortalMesh.GetSocketLocation(n"Base")  + PortalMesh.GetSocketRotation(n"Base").UpVector * -2000;
		Material::SetVectorParameterValue(Rader.GlobalParameters, n"RaderPortalClipSphere0", FLinearColor(Pos.X, Pos.Y, Pos.Z, 2000));
	}

	UFUNCTION()
	private void HideLeftHand()
	{
		Rader.Mesh.HideBoneByName(n"LeftHand", EPhysBodyOp::PBO_None);
	}

	UFUNCTION()
	private void HideRightHand()
	{
		Rader.Mesh.HideBoneByName(n"RightHand", EPhysBodyOp::PBO_None);
	}
	
	UFUNCTION()
	private void ShowHydra()
	{
		HydraMesh.SetHiddenInGame(false);
	}
	UFUNCTION()
	private void OpenGroundPortal()
	{
		Rader.SetPortalState(PortalMesh, PortalTextureHydra, 1);
		PortalDamageTrigger.EnableDamageTrigger(this);
		BP_EnableGroundPortal();
		CheckPlayerDistance();
		Rader.SetPortalClipSphereEnabled(Rader.Mesh, true);
		OnGrabbingHydra.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void StopProjectiles()
	{
		AttackInstances.Empty();
	}

	UFUNCTION()
	private void ActivateCollision()
	{
		BlockingLeftGauntlet.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
		BlockingRightGauntlet.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
		BlockingHydra.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	}

	UFUNCTION()
	private void CheckPlayerDistance()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			{
				if(StopLocation.WorldLocation.Dist2D(Player.ActorLocation) < 3200.0)
				{
					Player.LaunchPlayerTo(this, LaunchParams);
				}
			}
	}

	UFUNCTION(BlueprintEvent)
	void BP_EnableGroundPortal() {}

	UFUNCTION()
	private void StartSpawningProjectiles()
	{
		Rader.SetPortalClipSphereEnabled(Rader.Mesh, false);
		const float SpawnDelay = 0.0;
		UMeltdownBossPhaseThreeRainAttackEffectHandler::Trigger_StartAttack(this);
		
		{
			FMeltdownBossPhaseThreeRainConfig Config;
			Config.StartLaunchingDelay = SpawnDelay + 0.0;
			Config.LaunchInterval = 1.6;
			Config.MaxDistanceFromSpline = 350.0;
			Config.TargetingType = EMeltdownBossPhaseThreeRainTargetingType::Mio;
			Config.TargetingPredictionDistance = 400.0;
			SpawnMultipleProjectiles(Config);
		}

		{
			FMeltdownBossPhaseThreeRainConfig Config;
			Config.StartLaunchingDelay = SpawnDelay + 0.2;
			Config.LaunchInterval = 1.6;
			Config.MaxDistanceFromSpline = 350.0;
			Config.TargetingType = EMeltdownBossPhaseThreeRainTargetingType::Zoe;
			Config.TargetingPredictionDistance = 400.0;
			SpawnMultipleProjectiles(Config);
		}

		{
			FMeltdownBossPhaseThreeRainConfig Config;
			Config.StartLaunchingDelay = SpawnDelay;
			Config.LaunchInterval = 1.0;
			Config.MaxDistanceFromSpline = 350.0;
			Config.TargetingType = EMeltdownBossPhaseThreeRainTargetingType::RandomPosition;
			SpawnMultipleProjectiles(Config);
		}
	}

	UFUNCTION()
	private void StartAttackExit()
	{
		AttackInstances.Empty();
		UMeltdownBossPhaseThreeRainAttackEffectHandler::Trigger_StopAttack(this);
		bAttackFinished = true;
	//	HydraMesh.SetSkeletalMeshAsset(DecapitatedHydra);
	//	Niagara::SpawnOneShotNiagaraSystemAttached(HeadBleeding,HydraMesh, n"Base");
	}
	
	UFUNCTION()
	private void OnFinished()
	{
		OnAttackDone.Broadcast();
		AddActorDisable(this);

		Rader.Mesh.UnHideBoneByName(n"LeftHand");
		Rader.Mesh.UnHideBoneByName(n"RightHand");
	}

	UFUNCTION(DevFunction)
	void SpawnMultipleProjectiles(FMeltdownBossPhaseThreeRainConfig AttackConfig)
	{
		RemoveActorDisable(this);

		FMeltdownBossPhaseThreeRainInstance Instance;
		Instance.Config = AttackConfig;
		Instance.RemainingInterval = AttackConfig.StartLaunchingDelay;
		AttackInstances.Add(Instance);
	}

	void TickInstance(FMeltdownBossPhaseThreeRainInstance& Instance, float DeltaSeconds)
	{
		Instance.RemainingInterval -= DeltaSeconds;
		if (Instance.RemainingInterval <= 0)
		{
			Instance.RemainingInterval += Instance.Config.LaunchInterval;
			SpawnProjectile(Instance);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (FMeltdownBossPhaseThreeRainInstance& Instance : AttackInstances)
			TickInstance(Instance, DeltaSeconds);
	}


	UFUNCTION(DevFunction)
	void SpawnProjectile(FMeltdownBossPhaseThreeRainInstance Instance)
	{
		if (!HasControl())
			return;

		FVector Location;
		if (Instance.Config.TargetingType == EMeltdownBossPhaseThreeRainTargetingType::RandomPosition)
		{
			float SplineDistance = Math::RandRange(0, Spline.SplineLength);
			SplineDistance = ApplySplineDistanceAvoid(SplineDistance);

			float Offset = Math::RandRange(-Instance.Config.MaxDistanceFromSpline, Instance.Config.MaxDistanceFromSpline);

			FTransform SplineTransform = Spline.GetWorldTransformAtSplineDistance(SplineDistance);
			Location = SplineTransform.Location + SplineTransform.Rotation.RightVector * Offset;
		}
		else
		{
			AHazePlayerCharacter TargetPlayer;
			if (Instance.Config.TargetingType == EMeltdownBossPhaseThreeRainTargetingType::RandomPlayer)
				TargetPlayer = Game::GetPlayer(EHazePlayer(Math::RandRange(0, 1)));
			else if (Instance.Config.TargetingType == EMeltdownBossPhaseThreeRainTargetingType::Mio)
				TargetPlayer = Game::Mio;
			else if (Instance.Config.TargetingType == EMeltdownBossPhaseThreeRainTargetingType::Zoe)
				TargetPlayer = Game::Zoe;
			else
				TargetPlayer = nullptr;

			FVector TargetLocation = TargetPlayer.ActorLocation;
			TargetLocation += TargetPlayer.ActorHorizontalVelocity * Instance.Config.TargetingPredictionTime;
			TargetLocation += TargetPlayer.ActorHorizontalVelocity.GetSafeNormal2D() * Instance.Config.TargetingPredictionDistance;

			float SplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(TargetLocation);
			SplineDistance = ApplySplineDistanceAvoid(SplineDistance);

			Location = Spline.GetWorldLocationAtSplineDistance(SplineDistance);
			Location += (TargetLocation - Location)
				.ConstrainToDirection(Spline.GetWorldRotationAtSplineDistance(SplineDistance).RightVector)
				.GetClampedToMaxSize(Instance.Config.MaxDistanceFromSpline);
		}


		NetSpawnProjectile(Location);
	}

	float ApplySplineDistanceAvoid(float SplineDistance)
	{
		if (AvoidLocation.bAllCollected)
		{
			float AvoidSplineDistance = Spline.GetClosestSplineDistanceToWorldLocation(AvoidLocation.ActorLocation);
			if (Math::Abs(SplineDistance - AvoidSplineDistance) < AvoidLocationRadius)
			{
				if (SplineDistance < AvoidSplineDistance)
					return AvoidSplineDistance - AvoidLocationRadius;
				else
					return AvoidSplineDistance + AvoidLocationRadius;
			}
		}

		return SplineDistance;
	}

	UFUNCTION(NetFunction)
	private void NetSpawnProjectile(FVector TargetLocation)
	{
		FVector SpawnLocation = HydraMesh.GetSocketLocation(n"Jaw");
		AMeltdownBossPhaseThreeRainProjectile Projectile = SpawnActor(ProjectileClass, SpawnLocation);
		Projectile.Launch(TargetLocation);
	}
};

class AMeltdownBossPhaseThreeRainProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ProjectileRoot;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseThreeTelegraph> TelegraphClass;

	AMeltdownBossPhaseThreeRainAttack Hydra;

	UPROPERTY(EditAnywhere)
	float TelegraphRadius = 200.0;

	UPROPERTY(EditAnywhere)
	float DamageRadius = 200.0;

	UPROPERTY(EditAnywhere)
	float TelegraphDelay = 0.0;

	UPROPERTY(EditAnywhere)
	float Gravity = 5000.0;

	AMeltdownBossPhaseThreeTelegraph Telegraph;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> ImpactShake;

	UPROPERTY(DefaultComponent, Attach = ProjectileRoot)
	UForceFeedbackComponent ImpactFeedback;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDamageEffect> ProjectileDamage;

	float ReachedExtraHeight = 2000;
	float Timer = 0.0;
	FVector StartLocation;
	FVector TargetLocation;
	FVector StartVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Hydra = TListedActors<AMeltdownBossPhaseThreeRainAttack>().GetSingle();
	}

	void Launch(FVector InTargetLocation)
	{
		StartLocation = ActorLocation;
		TargetLocation = InTargetLocation;

		StartVelocity = Trajectory::CalculateVelocityForPathWithHeight(ActorLocation, TargetLocation, Gravity, ReachedExtraHeight);
		Telegraph = MeltdownBossPhaseThree::SpawnTelegraph(TelegraphClass, TargetLocation, TelegraphRadius, Type = ETelegraphDecalType::Fantasy);

		UMeltdownBossPhaseThreeRainProjectileEffectHandler::Trigger_Spawn(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;

		FVector Location = StartLocation + FVector(0, 0, -Gravity) * Math::Square(Timer) * 0.5 + StartVelocity * Timer;

		// if(Hydra.bStopProjectiles)
		// {
		// 	AddActorDisable(this);
		// 	Telegraph.HideAndDestroy();
		// }

		if (Location.Z <= TargetLocation.Z)
		{
			Location.Z = TargetLocation.Z;
			SetActorLocation(Location);

			PlayerHealth::DamagePlayersInRadius(ActorLocation, DamageRadius, 0.5, DamageEffect = ProjectileDamage);

			FMeltdownBossPhaseThreeRainProjectileImpactParams ImpactParams;
			ImpactParams.ImpactLocation = Location;
			UMeltdownBossPhaseThreeRainProjectileEffectHandler::Trigger_Impact(this, ImpactParams);

			OnImpact();
			DestroyActor();
			Telegraph.HideAndDestroy();
		}
		else
		{
			SetActorLocation(Location);
		}
	}

	UFUNCTION()
	void OnImpact()
	{
		for (AHazePlayerCharacter PlayerChar : Game::Players)
		{
			PlayerChar.PlayWorldCameraShake(ImpactShake,this, ActorCenterLocation,500, 100,1);
			ImpactFeedback.Play();
		}
	}
};

struct FMeltdownBossPhaseThreeRainProjectileImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;
}

UCLASS(Abstract)
class UMeltdownBossPhaseThreeRainProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact(FMeltdownBossPhaseThreeRainProjectileImpactParams ImpactParams) {}
}

UCLASS(Abstract)
class UMeltdownBossPhaseThreeRainAttackEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartAttack() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopAttack() {}
}