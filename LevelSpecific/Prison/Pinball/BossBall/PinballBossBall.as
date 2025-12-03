asset PinballBossBallSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UPinballBossBallUpdateMeshRotationCapability);
	Capabilities.Add(UPinballBossBallLaunchedOffsetCapability);
};

asset PinballBossBallControlSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UPinballBallTriggerCapability);

	Capabilities.Add(UPinballBossBallAirMoveCapability);
	Capabilities.Add(UPinballBossBallLaunchedCapability);
	Capabilities.Add(UPinballBossBallLaunchedTrailCapability);
	Capabilities.Add(UPinballBossBallMoveCapability);
	Capabilities.Add(UPinballBossBallLaunchTrajectoryCapability);
};

asset PinballBossBallRemoteSheet of UHazeCapabilitySheet
{
	Components.Add(UPinballBossBallPredictionComponent);
	Capabilities.Add(UPinballBossBallPredictionMoveCapability);
	Capabilities.Add(UPinballBossBallPredictionLaunchCapability);
	Capabilities.Add(UPinballBossBallPredictionImpactsCapability);
};

namespace Pinball
{
	APinballBossBall GetBossBall()
	{
		return TListedActors<APinballBossBall>().Single;
	}
}

namespace APinballBossBall
{
	const float Radius = 125.0;
};

UCLASS(Abstract)
class APinballBossBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Sphere;
	default Sphere.CollisionProfileName = n"EnemyCharacter";
	default Sphere.SphereRadius = APinballBossBall::Radius;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent MeshRootComp;

	UPROPERTY(DefaultComponent, Attach = MeshRootComp)
	UStaticMeshComponent BallMesh;
	default BallMesh.CollisionProfileName = n"NoCollision";
	default BallMesh.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent)
	UPinballBossAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bCanRerunMovement = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::High;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;
	default SyncedActorPositionComp.SleepAfterIdleTime = MAX_flt;

	UPROPERTY(DefaultComponent)
	UPinballBallComponent BallComp;
	default BallComp.BallType = EPinballBallType::BossBall;
	default BallComp.bCanBeSquished = false;

	UPROPERTY(DefaultComponent)
	UPinballGlobalResetComponent GlobalResetComp;

	UPROPERTY(DefaultComponent)
	UPinballBossBallLaunchedComponent LaunchComp;

	UPROPERTY(DefaultComponent)
	UPinballBossBallLaunchedOffsetComponent LaunchedOffsetComp;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(PinballBossBallSheet);
	default CapabilityComp.InitialStoppedSheets.Add(PinballBossBallControlSheet);
	default CapabilityComp.InitialStoppedSheets.Add(PinballBossBallRemoteSheet);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(BlueprintReadOnly)
	APinballBoss Boss;

	UPROPERTY(BlueprintReadOnly)
	int Phase = 0;

	UPROPERTY(BlueprintReadOnly)
	int Health = 2;

	UPinballMovementSettings MovementSettings;
	FTransform BallSocketTransform;
	bool bHasLerpedIn = false;
	TArray<APinballBossBallAutoAimVolume> AutoAimVolumes;

	const float BossBallNormalImpulse = 1500;
	const float BossBallVerticalImpulse = 500;

	const float MagnetDroneHorizontalImpulse = 750;
	const float MagnetDroneVerticalImpulse = 500;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		check(HasControl() == Pinball::GetBallPlayer().HasControl());

		MovementSettings = UPinballMovementSettings::GetSettings(this);
		MagneticSurfaceComp.OnMagnetDroneAttached.AddUFunction(this, n"OnMagnetDroneAttach");
		MagneticSurfaceComp.OnMagnetDroneDetached.AddUFunction(this, n"OnMagnetDroneDetached");
		GlobalResetComp.PreActivateProgressPoint.AddUFunction(this, n"PreActivateProgressPoint");

		if(HasControl())
			StartCapabilitySheet(PinballBossBallControlSheet, this);
		else
			StartCapabilitySheet(PinballBossBallRemoteSheet, this);

		UMovementSweepingSettings::SetPerformEdgeDetection(this, true, this);
	}

	UFUNCTION()
	void OnMagnetDroneAttach(FOnMagnetDroneAttachedParams Params)
	{
		UPinballBossBallEventHandler::Trigger_OnMagnetDroneAttractKnockback(this, Params);

#if !RELEASE
		TEMPORAL_LOG(this).Event("OnMagnetDroneAttach");
#endif
	}

	UFUNCTION()
	private void OnMagnetDroneDetached(FOnMagnetDroneDetachedParams Params)
	{
		if(!Pinball::GetBallPlayer().HasControl())
			return;

		const FVector MagnetDroneImpulse = GetMagnetDroneImpulse(Params.Player);
		Pinball::GetBallPlayer().AddMovementImpulse(MagnetDroneImpulse);

		const FVector BossBallImpulse = GetBossBallImpulse(Params.Player);

#if !RELEASE
		TEMPORAL_LOG(this).Event("OnMagnetDroneDetached")
			.DirectionalArrow("Magnet Drone Impulse", Params.Player.ActorLocation, MagnetDroneImpulse)
			.DirectionalArrow("Boss Ball Impulse", ActorLocation, BossBallImpulse)
		;
#endif

		if(!AutoAimVolumes.IsEmpty())
		{
			for(auto AutoAimVolume : AutoAimVolumes)
			{
				if(BossBallImpulse.DotProduct(AutoAimVolume.GetLaunchHorizontalDirection()) < 0)
				{
					// Faces the wrong way
					continue;
				}

				LaunchComp.bLaunchIsTrajectory = true;
				LaunchComp.LaunchTrajectory = AutoAimVolume.CalculateTrajectory(ActorLocation);

				if(Pinball::Prediction::IsPredictedGame())
				{
					auto PredictionComp = UPinballBossBallPredictionComponent::Get(this);
					LaunchComp.LaunchTrajectoryStartTime = PredictionComp.PredictionStartTime;
				}

#if !RELEASE
			TEMPORAL_LOG(this).Event("OnMagnetDroneDetached: Use auto aim launch");
			;
#endif

				// Don't apply an impulse, instead we let UPinballBossBallLaunchTrajectoryCapability kick in
				return;
			}
		}

#if !RELEASE
		TEMPORAL_LOG(this).Event("OnMagnetDroneDetached: Apply ball impulse");
		;
#endif

		AddMovementImpulse(BossBallImpulse);
	}

	/**
	 * Boss Ball is reused, so reset all state here.
	 */
	void OnSpawned(APinballBoss InBoss, int InPhase, FTransform InBallSocketTransform)
	{
		Boss = InBoss;
		Phase = InPhase;
		BallSocketTransform = InBallSocketTransform;

		Health = 1;
		bHasLerpedIn = false;

		LaunchComp.ResetLaunch();
		LaunchComp.ResetLaunchTrajectory();
	}

	void DamageBoss(FVector NewLocation, FVector ImpulseDirection, bool bResetVelocity, bool&out bWasKilled)
	{
		if(Health == 0)
		{
			KillBoss(NewLocation);
			bWasKilled = true;
			return;
		}

		Boss.SmallDamage();
		Health--;

		UPinballBossBallEventHandler::Trigger_OnDamaged(this);

		if(bResetVelocity)
		{
			ResetMovement();
		}

		AddMovementImpulse(ImpulseDirection);
		BP_DamageEffect();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DamageEffect() {}
	
	void KillBoss(FVector NewLocation)
	{
		Boss.BarBreak(NewLocation);
		UPinballBossBallEventHandler::Trigger_OnDeath(this);
		UPinballBossEventHandler::Trigger_OnKillDamage(Boss);
	}

	// UFUNCTION(NetFunction)
	// private void NetBallToPaddleApplyImpulses(FVector BallImpulse, FVector MagnetDroneImpulse)
	// {
	// 	AddMovementImpulse(BallImpulse);
	// 	Pinball::GetBallPlayer().AddMovementImpulse(MagnetDroneImpulse);
	// }

	private FVector GetBossBallImpulse(AHazePlayerCharacter Player) const
	{
		FVector Impulse = FVector::UpVector * BossBallVerticalImpulse;

		const FVector Normal = (ActorLocation - Player.ActorLocation).GetSafeNormal();
		Impulse += Normal * BossBallNormalImpulse;

		return Impulse;
	}
	
	private FVector GetMagnetDroneImpulse(AHazePlayerCharacter Player) const
	{
		FVector Impulse = FVector::UpVector * MagnetDroneVerticalImpulse;

		const FVector HorizontalDirection = (Player.ActorLocation - ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		Impulse += HorizontalDirection * MagnetDroneHorizontalImpulse;

		return Impulse;
	}

	UFUNCTION()
	private void PreActivateProgressPoint()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintCallable)
	void OnBallKnockedOut()
	{
		UPinballBossBallEventHandler::Trigger_OnKnockedOut(this);
	}
};