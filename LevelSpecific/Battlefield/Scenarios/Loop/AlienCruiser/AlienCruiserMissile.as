struct FAlienCruiserMissileInitParams
{
	AAlienCruiserMissileTarget Target;
	USceneComponent CruiserRotationPivot;
	FRotator CruiserRotationAtLaunch;
	float MissileForwardSpeed;
	float OrbitSpeed;
	float OrbitSpeedSlowDown;
	float MissileInwardSpeed;
	float MissileDistanceFromCenterTarget;
	float MissileDistanceFromTargetThreshold;
	float ExplosionRadius;
	float MissileSpeedMultiplier;
}

class AAlienCruiserMissile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MissileMesh;
	default MissileMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent TrailEffect;

	TArray<UNiagaraComponent> Emitters;
	TArray<UStaticMeshComponent> Meshes;

	FAlienCruiserMissileInitParams MissileParams;

	FVector LastLocation;
	FVector CurrentVelocity;
	float DistanceFromCenter;

	bool bHasReachedTargetInwardDistance = false;
	FVector SeekStartLocation;
	FVector SeekStartVelocity;
	FVector SeekTargetLocation;
	float SeekStartTime = 0.0;
	float SeekDuration = 0.0;

	const float FirstControlPointVelocitySampleSeconds = 0.2;
	const float SecondControlPointRaisedDistance = 1500.0;
	const float InwardStopThresholdBuffer = 100.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(UNiagaraComponent, Emitters);
		GetComponentsByClass(UStaticMeshComponent, Meshes);
	}

	void InitMissile(FAlienCruiserMissileInitParams InitParams)
	{
		MissileParams = InitParams;

		FVector OrbitPoint = GetOrbitPoint();
		DistanceFromCenter = ActorLocation.Distance(OrbitPoint);
	}

	void Explode()
	{
		FHazeTraceSettings OverlapTrace;
		OverlapTrace.IgnoreActor(this);
		OverlapTrace.UseSphereShape(MissileParams.ExplosionRadius);
		OverlapTrace.TraceWithChannel(ECollisionChannel::WeaponTraceEnemy);
		auto Overlaps = OverlapTrace.QueryOverlaps(ActorLocation);

		for(auto Overlap : Overlaps)
		{
			auto ResponseComp = UAlienCruiserMissileResponseComponent::Get(Overlap.Actor);
			if(ResponseComp == nullptr)
				continue;

			FAlienCruiserMissileExplosionResponseParams ExplosionParams;
			ExplosionParams.MissileLocationAtImpact = ActorLocation;
			ExplosionParams.MissileRotationAtImpact = ActorRotation;
			ExplosionParams.DistanceToMissileAtImpact = ActorLocation.Distance(ResponseComp.WorldLocation);
			ResponseComp.OnMissileExploded.Broadcast(ExplosionParams);
		}

		FAlienCruiserMissileHitParams EffectHitParams;
		EffectHitParams.MissileLocationAtImpact = ActorLocation;
		EffectHitParams.MissileRotationAtImpact = ActorRotation;
		UAlienCruiserEffectHandler::Trigger_OnMissileHit(this, EffectHitParams);

		// for(auto Emitter : Emitters)
		// {
		// 	Emitter.Deactivate();
		// }
		// for(auto Mesh : Meshes)
		// {
		// 	Mesh.AddComponentVisualsBlocker(this);
		// }
		
		SetActorTickEnabled(false);
		MissileMesh.SetHiddenInGame(true);
		Timer::SetTimer(this, n"DelayDeactivation", 1.0);
	}

	UFUNCTION()
	private void DelayDeactivation()
	{
		AddActorCollisionBlock(this);
		AddActorTickBlock(this);
		AddActorVisualsBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector OrbitPoint = GetOrbitPoint();
		if(!bHasReachedTargetInwardDistance)
		{
			MoveMissileForwards(DeltaSeconds);
			MoveMissileInwards(DeltaSeconds, OrbitPoint);
		}
		else
		{
			MoveTowardsTarget();
			ValidateDistanceToExplode();
		}

		OrbitMissileAroundPoint(DeltaSeconds, OrbitPoint);
		RotateMissileTowardsVelocity();
	
		CurrentVelocity = (ActorLocation - LastLocation) / DeltaSeconds;
		LastLocation = ActorLocation;

		TEMPORAL_LOG(this)
			.Value("OrbitSpeed", MissileParams.OrbitSpeed)
		;
	}

	void MoveMissileForwards(float DeltaTime)
	{
		FVector Velocity = MissileParams.CruiserRotationPivot.ForwardVector * MissileParams.MissileForwardSpeed * MissileParams.MissileSpeedMultiplier;

		AddActorWorldOffset(Velocity * DeltaTime);

		FVector DeltaToTarget = MissileParams.Target.ActorLocation - ActorLocation;
		float DeltaDotCruiserForward = DeltaToTarget.DotProduct(MissileParams.CruiserRotationAtLaunch.ForwardVector);

		if(DeltaDotCruiserForward < MissileParams.MissileDistanceFromTargetThreshold)
		{
			StartGoingTowardsTarget();
		}
	}

	void MoveMissileInwards(float DeltaTime, FVector OrbitPoint)
	{
		DistanceFromCenter = Math::FInterpTo(DistanceFromCenter, MissileParams.MissileDistanceFromCenterTarget, DeltaTime, MissileParams.MissileInwardSpeed * MissileParams.MissileSpeedMultiplier);

		FVector DirOrbitPointToMissile = (ActorLocation - OrbitPoint).GetSafeNormal();

		FVector Target = OrbitPoint + DirOrbitPointToMissile * DistanceFromCenter;
		FVector DeltaToTarget = Target - ActorLocation;

		AddActorWorldOffset(DeltaToTarget);

		// if(Math::IsNearlyEqual(DistanceFromCenter, MissileParams.MissileInwardStopDistanceThreshold, InwardStopThresholdBuffer))
		// 	StartGoingTowardsTarget();
	}

	void OrbitMissileAroundPoint(float DeltaTime, FVector OrbitPoint)
	{
		FTransform OrbitTransform = FTransform(MissileParams.CruiserRotationAtLaunch, OrbitPoint);
		FRotator DeltaRotation = FRotator(0, 0, MissileParams.OrbitSpeed * DeltaTime * MissileParams.MissileSpeedMultiplier);

		FVector PointToMissile = ActorLocation - OrbitPoint;
		FVector PointToMissileLocal = OrbitTransform.InverseTransformVector(PointToMissile);

		PointToMissileLocal = DeltaRotation.RotateVector(PointToMissileLocal);

		FVector OrbitedLocation = OrbitTransform.TransformVector(PointToMissileLocal) + OrbitPoint;
		FVector DeltaToOrbitedLocation = OrbitedLocation - ActorLocation;

		AddActorWorldOffset(DeltaToOrbitedLocation);

		MissileParams.OrbitSpeed = Math::FInterpTo(MissileParams.OrbitSpeed, 0, DeltaTime, MissileParams.OrbitSpeedSlowDown);

		TEMPORAL_LOG(this, "Orbit")
			.Sphere("Orbit Point", OrbitPoint, 50, FLinearColor::Blue, 20)
			.Arrow("Point to Missile", OrbitPoint,	OrbitPoint + PointToMissile, 40, 400, FLinearColor::Purple)
			.Sphere("Orbited Location", OrbitedLocation, 500, FLinearColor::Red, 100)
			.Arrow("Orbit Delta", ActorLocation, ActorLocation + DeltaToOrbitedLocation, 40, 400, FLinearColor::DPink)
		;
	}

	void StartGoingTowardsTarget()
	{
		bHasReachedTargetInwardDistance = true;
		SeekStartLocation = ActorLocation;
		SeekStartVelocity = CurrentVelocity;
		SeekTargetLocation = MissileParams.Target.ActorLocation;

		SeekStartTime = Time::GetGameTimeSeconds();

		float DistanceToTarget = SeekTargetLocation.Distance(ActorLocation);
		SeekDuration = DistanceToTarget / (MissileParams.MissileForwardSpeed * MissileParams.MissileSpeedMultiplier);
	}

	void MoveTowardsTarget()
	{
		float TimeSinceStartSeek = Time::GetGameTimeSince(SeekStartTime);
		float Alpha = TimeSinceStartSeek / SeekDuration;
		FVector TargetLocation = BezierCurve::GetLocation_2CP_ConstantSpeed(SeekStartLocation
			, SeekStartLocation + SeekStartVelocity * FirstControlPointVelocitySampleSeconds
			, SeekTargetLocation + FVector::UpVector * SecondControlPointRaisedDistance
			, MissileParams.Target.ActorLocation
			, Alpha);

		FVector DeltaToTarget = TargetLocation - ActorLocation;
		AddActorWorldOffset(DeltaToTarget);
	}

	void RotateMissileTowardsVelocity()
	{
		FVector DeltaLocation = ActorLocation - LastLocation;
		ActorRotation = FRotator::MakeFromX(DeltaLocation);
	}

	void ValidateDistanceToExplode()
	{
		if(ActorLocation.IsWithinDist(SeekTargetLocation, 200))
			Explode();
	}

	FVector GetOrbitPoint() const
	{
		return Math::ClosestPointOnInfiniteLine(MissileParams.CruiserRotationPivot.WorldLocation
			, MissileParams.CruiserRotationPivot.WorldLocation + MissileParams.CruiserRotationPivot.ForwardVector
			, ActorLocation);
	}
};