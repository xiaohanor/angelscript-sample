class ASkylineWhipBird : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::WorldGeometry, ECollisionResponse::ECR_Block);
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Block);
	default Collision.SphereRadius = 50.0;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkeletalMesh;
	default SkeletalMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UGravityWhipTargetComponent WhipTargetComp;
	default WhipTargetComp.bInvisibleTarget = true;

	UPROPERTY(DefaultComponent, Attach = WhipTargetComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponseComp;
	default WhipResponseComp.GrabMode = EGravityWhipGrabMode::Sling;
	default WhipResponseComp.bAllowMultiGrab = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncedActorPositionComp;
	default CrumbSyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::Standard;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(USkylineWhipBirdMovementCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USkylineWhipBirdProximityReactionCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USkylineWhipBirdGrabCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USkylineWhipBirdThrowCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USkylineWhipBirdGrabbedCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USkylineWhipBirdLandCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USkylineWhipBirdSitCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USkylineWhipBirdFlyToTargetCapability);

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY()
	float ProximityRadius = 400.0;

	UPROPERTY()
	float LandDistance = 100.0;

	UPROPERTY()
	float LandTime = 1.0;

	UPROPERTY()
	float HoverTime = 5.0;
	float ExpireTime = 0.0;

	bool bIsFlying = false;
	bool bIsLanding = false;
	bool bIsLifting = false;
	bool bIsSitting = false;	
	bool bIsThrown = false;
	bool bIsLanded = false;

	FTransform InitialRelativeTransform;

	USkylineWhipBirdTargetComponent CurrentTarget;

	FVector Velocity;
	FVector Force;
	float Drag = 1.0;
	float FlySpeed = 2000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRelativeTransform = ActorRelativeTransform;

		WhipResponseComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		WhipResponseComp.OnThrown.AddUFunction(this, n"HandleThrown");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PrintToScreen("Force: " + Force, 0.0, FLinearColor::Green);	
//		Debug::DrawDebugSphere(ActorLocation, Collision.SphereRadius, 6, FLinearColor::Red, 3.0, 0.0);
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		USkylineWhipBirdEventHandler::Trigger_OnGrabbed(this);
	}

	UFUNCTION()
	private void HandleThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
		auto Player = Cast<AHazePlayerCharacter>(UserComponent.Owner);

		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
		Trace.IgnoreActor(this);
		Trace.IgnoreActor(Player);
		FVector Start = Player.ViewLocation;
		FVector End = Player.ViewLocation + Player.ViewRotation.ForwardVector * 20000.0;

		auto AimHitResult = Trace.QueryTraceSingle(Start, End);
		if (AimHitResult.bBlockingHit)
			End = AimHitResult.ImpactPoint;

		FVector Direction = (End - ActorLocation).SafeNormal;

		bIsThrown = true;
		ExpireTime = Time::GameTimeSeconds + HoverTime;

//		Debug::DrawDebugPoint(End, 10.0, FLinearColor::Red, 1.0);
		
		ActorVelocity = Direction * 4000.0;

		USkylineWhipBirdEventHandler::Trigger_OnThrown(this);
	}

	void UpdateTarget()
	{
		auto Manager = TListedActors<ASkylineWhipBirdManager>().Single;
		if (Manager == nullptr)
			Manager = SpawnActor(ASkylineWhipBirdManager);

		USkylineWhipBirdTargetComponent ClosestTarget;
		float ClosestDistance = BIG_NUMBER;
		for (auto Target : Manager.Targets)
		{
			auto WhipBirdTarget = Cast<USkylineWhipBirdTargetComponent>(Target);

			if (WhipBirdTarget.bIsOccupied)
				continue;

			FVector ToTarget = ActorLocation - Target.WorldLocation;
			float Distance = ToTarget.Size();

			if (Distance < ClosestDistance)
			{
				if (!CanSeeTarget(WhipBirdTarget))
					continue;

				ClosestDistance = Distance;
				ClosestTarget = WhipBirdTarget;
			}
		}

		if (ClosestTarget != nullptr)
		{
			ClearTarget();
			SetTarget(ClosestTarget);
		}

//		if (CurrentTarget != nullptr)
//			Debug::DrawDebugLine(ActorLocation, CurrentTarget.WorldLocation, FLinearColor::Green, 10.0, 2.0);
	}

	void SetTarget(USkylineWhipBirdTargetComponent Target)
	{
		CurrentTarget = Target;
		CurrentTarget.bIsOccupied = true;
	}

	void ClearTarget()
	{
		if (HasValidTarget())
			CurrentTarget.bIsOccupied = false;

		CurrentTarget = nullptr;
	}

	bool CanSeeTarget(USkylineWhipBirdTargetComponent Target)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(this);
		Trace.IgnoreActor(Target.Owner);
		Trace.IgnoreActors(Game::Players);
		FVector Start = ActorLocation;
		FVector End = Target.WorldLocation;
		FVector StartToEnd = End - Start;

		End = Start + (StartToEnd.SafeNormal * (StartToEnd.Size() - Target.TargetRadius));

//		Debug::DrawDebugPoint(End, 10.0, FLinearColor::Red, 1.0);

		auto HitResult = Trace.QueryTraceSingle(Start, End);

		return !HitResult.bBlockingHit;
	}

	void Splat(FVector Normal)
	{
		USkylineWhipBirdEventHandler::Trigger_OnWallImpact(this);
		BP_Splat(Velocity, Normal);
		Die();
	}

	void Die()
	{
		if (CurrentTarget != nullptr)
			CurrentTarget.bIsOccupied = false;

		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Splat(FVector ImpactVelocity, FVector ImpactNormal) { }

	void AddForce(FVector ForceToAdd)
	{
		Force += ForceToAdd;
	}

	FVector ConsumeForce()
	{
		FVector ConsumedForce = Force;
		Force = FVector::ZeroVector;

		return ConsumedForce;
	}

	bool HasValidTarget()
	{
		return IsValid(CurrentTarget);
	}
}