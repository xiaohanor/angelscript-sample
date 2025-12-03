event void FControllableDropShipEnemyShipDestroyedEvent(AControllableDropShipEnemyShip Ship);

UCLASS(Abstract)
class AControllableDropShipEnemyShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DropShipRoot;

	UPROPERTY(DefaultComponent, Attach = DropShipRoot)
	USceneComponent HoverRoot;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	USceneComponent WobbleRoot;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	UBoxComponent CollisionComp1;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	UBoxComponent CollsionComp2;

	UPROPERTY(DefaultComponent, Attach = WobbleRoot)
	UHazeSkeletalMeshComponentBase ShipSkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = ShipSkelMeshComp, AttachSocket = "TurretBase")
	USceneComponent TurretBase;

	UPROPERTY(DefaultComponent, Attach = ShipSkelMeshComp, AttachSocket = "Base")
	USceneComponent PilotAttachmentComp;
		
	UPROPERTY(DefaultComponent, Attach = PilotAttachmentComp)
	UHazeSkeletalMeshComponentBase PilotSkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = ShipSkelMeshComp, AttachSocket = "Base")
	UControllableDropShipAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(DefaultComponent, Attach = TurretBase)
	UHazeSkeletalMeshComponentBase TurretSkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = TurretBase)
	UHazeSkeletalMeshComponentBase GunnerSkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = TurretSkelMeshComp, AttachSocket = "LeftMuzzle")
	UArrowComponent LeftMuzzleComp;

	UPROPERTY(DefaultComponent, Attach = TurretSkelMeshComp, AttachSocket = "RightMuzzle")
	UArrowComponent RightMuzzleComp;

	UPROPERTY(DefaultComponent, Attach = ShipSkelMeshComp, AttachSocket = "LeftThruster")
	USceneComponent LeftTrusterRoot;

	UPROPERTY(DefaultComponent, Attach = ShipSkelMeshComp, AttachSocket = "RightThruster")
	USceneComponent RightThrusterRoot;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(DefaultComponent)
	UControllableDropShipShotResponseComponent ShotResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedShipPosition;
	default SyncedShipPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;
	default SyncedShipPosition.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY()
	FControllableDropShipEnemyShipDestroyedEvent OnShipDestroyed;

	float MoveSpeed = 0.0;
	float MaxMoveSpeed = 4800.0;

	bool bShootingAtPlayers = false;
	bool bShootLeft = false;

	FVector CurrentAimDirection;

	int CurrentHits = 0;
	int HitsRequired = 15;

	FVector SpawnEndLocation;

	float VerticalOffsetFromPlayers;
	float AngleOffsetFromPlayers = 0.0;

	int MinShotsPerBurst = 12;
	int MaxShotsPerBurst = 24;
	int ShotsPerBurst = 10;
	int CurrentShotAmount = 0;
	FVector2D BurstCooldownRange = FVector2D(0.25, 0.5);
	float BurstCooldown = 0.1;
	float CurrentBurstCooldown = 0.0;
	float ShootInterval = 0.04;
	FVector2D ShootIntervalRange = FVector2D(0.04, 0.15);
	float CurrentShootTime = 0.0;

	bool bDodged = false;
	bool bDodgeSpinClockwise = true;
	int DodgeHitThreshold = 5;
	float DodgeStartVerticalOffset;
	float DodgeEndVerticalOffset;
	float DodgeStartAngleOffset;
	float DodgeEndAngleOffset;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike DodgeTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve DodgeWobbleCurve;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve DodgeYawCurve;

	bool bDestroyPrepared = false;
	bool bDestroyed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		ShotResponseComp.OnHit.AddUFunction(this, n"GetHit");

		ShootInterval = Math::RandRange(ShootIntervalRange.X, ShootIntervalRange.Y);

		DodgeTimeLike.BindUpdate(this, n"UpdateDodge");
		DodgeTimeLike.BindFinished(this, n"FinishDodge");
	}

	UFUNCTION()
	private void GetHit()
	{
		UControllableDropShipEnemyShipEffectEventHandler::Trigger_Hit(this);
		
		CurrentHits++;

		if (Game::Zoe.HasControl() && !bDodged && CurrentHits >= DodgeHitThreshold)
		{
			Dodge();
		}

		if (CurrentHits >= HitsRequired)
		{
			if (Game::Zoe.HasControl())
				CrumbDestroy();
		}
	}

	void Dodge()
	{
		bDodged = true;
		CrumbDodge();
	}

	UFUNCTION(CrumbFunction)
	void CrumbDodge()
	{
		DodgeStartVerticalOffset = VerticalOffsetFromPlayers;
		DodgeStartAngleOffset = AngleOffsetFromPlayers;

		if (DodgeStartAngleOffset < DodgeEndAngleOffset)
			bDodgeSpinClockwise = false;

		DodgeTimeLike.PlayFromStart();

		StopShootingAtPlayers();
		Timer::SetTimer(this, n"StartShootingAtPlayers", DodgeTimeLike.Duration);

		UControllableDropShipEnemyShipEffectEventHandler::Trigger_Dodge(this);
	}

	UFUNCTION()
	private void UpdateDodge(float CurValue)
	{
		VerticalOffsetFromPlayers = Math::Lerp(DodgeStartVerticalOffset, DodgeEndVerticalOffset, CurValue);
		AngleOffsetFromPlayers = Math::Lerp(DodgeStartAngleOffset, DodgeEndAngleOffset, CurValue);

		float WobbleAlpha = Math::Lerp(0.0, 1.0, DodgeWobbleCurve.GetFloatValue(CurValue));
		float YawAlpha = Math::Lerp(0.0, 1.0, DodgeYawCurve.GetFloatValue(CurValue));
		float CurrentYaw = YawAlpha * 30.0;
		if (!bDodgeSpinClockwise)
			CurrentYaw *= -1;

		WobbleRoot.SetRelativeRotation(FRotator(WobbleAlpha * 22.0, CurrentYaw, WobbleAlpha * 16.0));
	}

	UFUNCTION()
	private void FinishDodge()
	{
	}

	void Spawn(float VerticalOffset, float Angle, float DodgeOffset, float DodgeAngle)
	{
		VerticalOffsetFromPlayers = VerticalOffset;
		AngleOffsetFromPlayers = Angle;
		DodgeEndVerticalOffset = DodgeOffset;
		DodgeEndAngleOffset = DodgeAngle;

		FVector DirToPlayer = (Game::Mio.ActorCenterLocation - TurretBase.WorldLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		SetActorRotation(DirToPlayer.Rotation());

		Timer::SetTimer(this, n"StartShootingAtPlayers", 1.0);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDestroy()
	{
		if (!bDestroyPrepared || bDestroyed)
		{
			bDestroyPrepared = true;
			PrepareDestroy();
			Timer::SetTimer(this, n"Destroy", 0.3);
		}
	}

	void PrepareDestroy()
	{
		BP_PrepareDestroy();
	}

	UFUNCTION(BlueprintEvent)
	void BP_PrepareDestroy() {}

	UFUNCTION()
	void Destroy()
	{
		if (bDestroyed)
			return;

		bDestroyed = true;

		OnShipDestroyed.Broadcast(this);

		UControllableDropShipEnemyShipEffectEventHandler::Trigger_Destroyed(this);

		StopShootingAtPlayers();

		BP_Destroy();
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Destroy() {}

	UFUNCTION()
	void StartShootingAtPlayers()
	{
		bShootingAtPlayers = true;
	}

	UFUNCTION()
	void StopShootingAtPlayers()
	{
		bShootingAtPlayers = false;
		CurrentBurstCooldown = 0.0;
		CurrentShootTime = 0.0;
	}

	void Shoot()
	{
		UArrowComponent MuzzleComp = !bShootLeft ? LeftMuzzleComp : RightMuzzleComp;
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(this);
		Trace.UseLine();

		FVector TraceStartLoc = MuzzleComp.WorldLocation;
		FVector TraceDir = (Game::Mio.ActorCenterLocation - TraceStartLoc).GetSafeNormal();
		FVector TraceEndLoc = TraceStartLoc + (TraceDir * 20000.0);

		FHitResult Hit = Trace.QueryTraceSingle(TraceStartLoc, TraceEndLoc);
		UControllableDropShipShotResponseComponent ResponseComp;

		FVector EndLocation = TraceEndLoc;
		if (Hit.bBlockingHit)
		{
			ResponseComp = UControllableDropShipShotResponseComponent::Get(Hit.Actor);
			EndLocation = Hit.ImpactPoint;
		}

		// Debug::DrawDebugSphere(EndLocation, 100.0, 12, FLinearColor::Red, 10.0, 2.0);

		bool bHit = Hit.bBlockingHit;
		CrumbShoot(bHit, ResponseComp, EndLocation, Hit.ImpactNormal);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbShoot(bool bHit, UControllableDropShipShotResponseComponent ResponseComp, FVector ImpactPoint, FVector ImpactNormal)
	{
		bShootLeft = !bShootLeft;

		UArrowComponent MuzzleComp = bShootLeft ? LeftMuzzleComp : RightMuzzleComp;

		if (bHit)
		{
			if (ResponseComp != nullptr)
				ResponseComp.Hit();
		}

		FControllableDropShipEnemyShipShotFiredParams Params;
		Params.bLeft = bShootLeft;
		Params.bHit = bHit;
		Params.ImpactPoint = ImpactPoint;
		Params.ImpactNormal = ImpactNormal;
		if (ResponseComp != nullptr)
			Params.ResponseComp = ResponseComp;
		UControllableDropShipEnemyShipEffectEventHandler::Trigger_ShotFired(this, Params);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector DirToPlayer = (Game::Mio.ActorCenterLocation - TurretBase.WorldLocation).GetSafeNormal();
		FRotator Rot = Math::RInterpTo(ActorRotation, DirToPlayer.Rotation(), DeltaTime, 5.0);
		SetActorRotation(FRotator(0.0, Rot.Yaw, 0.0));

		AHazePlayerCharacter FollowPlayer = Game::Mio;
		FVector TargetLoc = FollowPlayer.ActorLocation;
		FVector Dir = -FollowPlayer.ActorForwardVector.ConstrainToPlane(FVector::UpVector).RotateAngleAxis(AngleOffsetFromPlayers, FVector::UpVector);
		TargetLoc += Dir * ControllableDropShip::EnemyDistance;
		TargetLoc += FVector::UpVector * VerticalOffsetFromPlayers;

		FVector Loc = Math::VInterpTo(ActorLocation, TargetLoc, DeltaTime, 5.0);
		SetActorLocation(Loc);

		if (bShootingAtPlayers)
		{
			if (CurrentBurstCooldown > 0)
				CurrentBurstCooldown -= DeltaTime;
			else
			{
				CurrentShootTime += DeltaTime;
				if (CurrentShootTime >= ShootInterval)
				{
					CurrentShootTime = 0.0;
					Shoot();
					CurrentShotAmount++;
					if (CurrentShotAmount >= ShotsPerBurst)
					{
						CurrentBurstCooldown = Math::RandRange(BurstCooldownRange.X, BurstCooldownRange.Y);
						CurrentShotAmount = 0;
						ShotsPerBurst = Math::RandRange(MinShotsPerBurst, MaxShotsPerBurst);
					}
				}
			}
		}

		if (Game::Zoe.HasControl())
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::EnemyCharacter);
			Trace.IgnoreActor(this);
			Trace.UseBoxShape(CollisionComp1);
			
			FHitResult HitResult = Trace.QueryTraceSingle(CollisionComp1.WorldLocation, CollisionComp1.WorldLocation + (ActorForwardVector * (CollisionComp1.BoxExtent.X/2)));
			if (HitResult.bBlockingHit)
			{
				CrumbDestroy();
			}
		}
	}
}

UCLASS(Abstract)
class UControllableDropShipEnemyShipEffectEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AControllableDropShipEnemyShip Ship;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ship = Cast<AControllableDropShipEnemyShip>(Owner);
	}

	UFUNCTION(BlueprintEvent)
	void ShotFired(FControllableDropShipEnemyShipShotFiredParams Params) {}

	UFUNCTION(BlueprintEvent)
	void Hit() {}

	UFUNCTION(BlueprintEvent)
	void Dodge() {}

	UFUNCTION(BlueprintEvent)
	void Destroyed() {}
}

struct FControllableDropShipEnemyShipShotFiredParams
{
	UPROPERTY()
	bool bLeft = false;

	UPROPERTY()
	bool bHit = false;

	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	UControllableDropShipShotResponseComponent ResponseComp;
}