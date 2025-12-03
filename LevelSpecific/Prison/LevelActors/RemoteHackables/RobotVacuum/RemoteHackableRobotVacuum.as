UCLASS(Abstract)
class ARemoteHackableRobotVacuum : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftDusterRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightDusterRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftWheelRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightWheelRoot;

	UPROPERTY(DefaultComponent)
	URemoteHackingResponseComponent HackableComp;
	default HackableComp.bCanCancel = false;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bAllowUsingBoxCollisionShape = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncedComponent;
	default CrumbSyncedComponent.SyncRate = EHazeCrumbSyncRate::PlayerSynced;
	default CrumbSyncedComponent.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableRobotVacuumCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableRobotVacuumCancelCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000.0;

	UPROPERTY()
	FRemoteHackingEvent OnHackStarted;

	UPROPERTY()
	FRemoteHackingEvent OnHackStopped;

	UPROPERTY(EditInstanceOnly)
	ASplineActor IdleSpline;
	UHazeSplineComponent IdleSplineComp;

	UPROPERTY(EditInstanceOnly)
	TArray<ASplineActor> CollisionSplines;

	bool bIdling = true;
	float IdleSplineDist = 0.0;
	float IdleMoveSpeed = 200.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		if (IdleSpline != nullptr)
			IdleSplineComp = IdleSpline.Spline;

		HackableComp.OnHackingStarted.AddUFunction(this, n"Hacked");
		HackableComp.OnHackingStopped.AddUFunction(this, n"HackStopped");

		if (!CollisionSplines.IsEmpty())
			MoveComp.ApplySplineCollision(CollisionSplines, this);
	}

	UFUNCTION()
	private void Hacked()
	{
		bIdling = false;
		OnHackStarted.Broadcast();
	}

	
	UFUNCTION()
	private void HackStopped()
	{
		OnHackStopped.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		LeftDusterRoot.AddLocalRotation(FRotator(0.0, 1000.0 * DeltaTime, 0.0));
		RightDusterRoot.AddLocalRotation(FRotator(0.0, -1000.0 * DeltaTime, 0.0));

		if (bIdling && IdleSplineComp != nullptr)
		{
			FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
			Trace.IgnoreActor(this);
			Trace.UseCapsuleShape(150.0, 150.0);
			
			FVector TraceStartLoc = ActorLocation - (FVector::UpVector * 130.0) + (ActorForwardVector * 10.0);
			FHitResult Hit = Trace.QueryTraceSingle(TraceStartLoc, TraceStartLoc + (ActorForwardVector * 60.0));

			if (Hit.bBlockingHit)
				return;

			IdleSplineDist += IdleMoveSpeed * DeltaTime;
			if (IdleSplineDist >= IdleSplineComp.SplineLength)
				IdleSplineDist = 0.0;

			FVector IdleLoc = IdleSplineComp.GetWorldLocationAtSplineDistance(IdleSplineDist);
			FRotator IdleRot = IdleSplineComp.GetWorldRotationAtSplineDistance(IdleSplineDist).Rotator();

			SetActorLocationAndRotation(IdleLoc, IdleRot);

			LeftWheelRoot.AddLocalRotation(FRotator(0.0, 0.0, 50.0 * DeltaTime));
			RightWheelRoot.AddLocalRotation(FRotator(0.0, 0.0, -50.0 * DeltaTime));

		}
	}
}