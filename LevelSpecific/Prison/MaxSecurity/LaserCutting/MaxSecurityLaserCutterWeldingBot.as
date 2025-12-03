event void FMaxSecurityLaserCutterWeldingBotDestroyedEvent();

UCLASS(Abstract)
class AMaxSecurityLaserCutterWelderBot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BotRoot;

	UPROPERTY(DefaultComponent, Attach = BotRoot)
	UHazeSkeletalMeshComponentBase BotSkelMesh;

	UPROPERTY(DefaultComponent, Attach = BotRoot)
	USceneComponent WeldEmitterComp;

	UPROPERTY(DefaultComponent, Attach = WeldEmitterComp)
	UNiagaraComponent BeamComp;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::Standard;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.0;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserCutterWeakPoint WeakPoint;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike DropTimeLike;

	UPROPERTY()
	FMaxSecurityLaserCutterWeldingBotDestroyedEvent OnBotDestroyed;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FollowSpline;
	FSplinePosition SplinePos;

	bool bActive = false;

	UMaxSecurityLaserCutterWeakPointMeshComponent CurrentTargetPoint = nullptr;

	FVector CurrentWeldLocation;

	bool bLaunched = false;
	float LaunchTime = 0.0;
	FVector LaunchDirection;

	FVector StartLocation;
	FVector TargetLocation;

	bool bDropStarted = false;
	bool bDropped = false;

	float MoveSpeed = 320.0;

	bool bForwardFacingOnSpline = false;

	FHazeAcceleratedFloat AccSpeed;

	float WeldDistanceOffset = 400.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Always controlled on the laser side, since we will be changing the cut weak points
		SetActorControlSide(Game::Mio);

		MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"MagnetBurst");
		
		DropTimeLike.BindUpdate(this, n"UpdateDrop");
		DropTimeLike.BindFinished(this, n"FinishDrop");

		StartLocation = ActorLocation;
	}

	UFUNCTION()
	private void MagnetBurst(FMagneticFieldData Data)
	{
		if (!bDropped)
			return;

		// Crumb from zoes side for immediate feedback
		if (!Game::Zoe.HasControl())
			return;

		CrumbLaunched(Data.GetAverageForceDirection().ConstrainToPlane(FVector::UpVector));
	}

	UFUNCTION(CrumbFunction)
	private void CrumbLaunched(FVector InLaunchDirection)
	{
		bDropped = false;
		bActive = false;

		LaunchDirection = InLaunchDirection;
		bLaunched = true;

		BeamComp.DeactivateImmediately();

		OnBotDestroyed.Broadcast();
	}

	void Drop(FVector SpawnLocation, bool bForwardOnSpline)
	{
		bDropStarted = true;
		bLaunched = false;
		bActive = false;

		bForwardFacingOnSpline = bForwardOnSpline;
		SplinePos = FSplinePosition(FollowSpline.Spline, FollowSpline.Spline.GetClosestSplineDistanceToWorldLocation(SpawnLocation), bForwardFacingOnSpline);
		SplinePos.Move(-WeldDistanceOffset);

		TargetLocation = SplinePos.WorldLocation;

		FRotator SpawnRotation = SplinePos.WorldRotation.Rotator();

		TeleportActor(SpawnLocation, SpawnRotation, this);
		StartLocation = ActorLocation;

		BotRoot.SetRelativeRotation(FRotator::ZeroRotator);

		SetActorHiddenInGame(false);
		DropTimeLike.PlayFromStart();

		LaunchTime = 0.0;

		AccSpeed.SnapTo(0.0);
	}

	UFUNCTION()
	private void UpdateDrop(float CurValue)
	{
		FVector Loc = Math::Lerp(StartLocation, TargetLocation, CurValue);
		SetActorLocation(Loc);
	}

	UFUNCTION()
	private void FinishDrop()
	{
		if (bLaunched)
			return;

		bDropped = true;
		Timer::SetTimer(this, n"ActivateBot", 0.25);
	}

	UFUNCTION()
	void ActivateBot()
	{
		if (bLaunched)
			return;

		if (!bDropped)
			return;

		BeamComp.SetFloatParameter(n"Width", 50.0);
		BeamComp.Activate(true);
		CurrentWeldLocation = ActorLocation;
		bActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bLaunched)
		{
			AddActorWorldOffset(LaunchDirection * 4000.0 * DeltaTime);

			FQuat DeltaRotation = FQuat(-ActorForwardVector, 200.0 * DeltaTime);
			BotRoot.AddWorldRotation(DeltaRotation);

			LaunchTime += DeltaTime;
			if (LaunchTime >= 0.3)
				Explode();

			return;
		}

		if (!bActive)
			return;
		

		if (HasControl())
		{
			AccSpeed.AccelerateTo(MoveSpeed, 1.0, DeltaTime);
			SplinePos.Move(AccSpeed.Value * DeltaTime);
			SetActorLocation(SplinePos.WorldLocation);
			SetActorRotation(SplinePos.WorldRotation);
		}
		else
		{
			// Zoe just replicated the position
			const auto ActorPosition = SyncedActorPositionComp.GetPosition();

			SetActorVelocity((ActorPosition.WorldLocation - ActorLocation) / DeltaTime);
			SetActorLocationAndRotation(ActorPosition.WorldLocation, ActorPosition.WorldRotation);

			const float SplineDistance = SplinePos.CurrentSpline.GetClosestSplineDistanceToWorldLocation(ActorLocation);
			SplinePos = SplinePos.CurrentSpline.GetSplinePositionAtSplineDistance(SplineDistance, bForwardFacingOnSpline);
		}
		
		FHazeTraceSettings GroundTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		GroundTrace.IgnoreActor(this);
		GroundTrace.IgnorePlayers();
		GroundTrace.UseLine();

		FSplinePosition TraceSplinePosition = SplinePos;
		TraceSplinePosition.Move(WeldDistanceOffset);

		FVector TraceStartLoc = TraceSplinePosition.GetWorldLocation();

		TraceStartLoc.Z = ActorLocation.Z;
		FHitResult GroundHit = GroundTrace.QueryTraceSingle(TraceStartLoc, TraceStartLoc + (FVector::DownVector * 1000.0));
		
		CurrentWeldLocation = GroundHit.ImpactPoint;

		BeamComp.SetVisibility(true);
		BeamComp.SetVectorParameter(n"BeamStart", WeldEmitterComp.WorldLocation);
		BeamComp.SetVectorParameter(n"BeamEnd", CurrentWeldLocation);

		if (WeakPoint.HasControl())
		{
			if (GroundHit.bBlockingHit)
			{
				if (GroundHit.Actor == WeakPoint)
				{
					auto Point = Cast<UMaxSecurityLaserCutterWeakPointMeshComponent>(GroundHit.Component);
					if (Point != nullptr)
						WeakPoint.ControlRepairLocation(Point);
				}
			}
		}
	}

	void Explode()
	{
		BP_Explode();

		bLaunched = false;
		SetActorLocation(StartLocation);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode() {}

	UFUNCTION(CrumbFunction)
	private void CrumbSetCurrentTargetPoint(UMaxSecurityLaserCutterWeakPointMeshComponent InTargetPoint)
	{
		CurrentTargetPoint = InTargetPoint;
	}
}