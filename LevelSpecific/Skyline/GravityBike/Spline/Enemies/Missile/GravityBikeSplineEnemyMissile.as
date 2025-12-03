enum EGravityBikeSplineEnemyMissileState
{
	FlyStraight,
	TurnAround,
	Homing,
	Dropped,
};

UCLASS(Abstract)
class AGravityBikeSplineEnemyMissile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionProfileName(CollisionProfile::NoCollision);

	UPROPERTY(DefaultComponent)
	UCapsuleComponent SweepComp;
	default SweepComp.SetCollisionProfileName(CollisionProfile::NoCollision);

	UPROPERTY(DefaultComponent)
	USphereComponent ExplosionRadiusComp;
	default ExplosionRadiusComp.SetCollisionProfileName(CollisionProfile::NoCollision);

	UPROPERTY(DefaultComponent)
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;
	default GrabTargetComp.GrabCategory = EGravityBikeWhipGrabCategory::Missile;

	UPROPERTY(DefaultComponent)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent HazeSphereComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(EditDefaultsOnly, Category = "Throw")
	float DroppedNoTargetLifeTime = 4;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLogComp;
#endif

#if EDITOR
	UPROPERTY(EditDefaultsOnly)
	bool bDebug = false;

	UPROPERTY(EditDefaultsOnly)
	float DebugInterval = 0.1;

	private float LastDebugTime;
	private FVector LastDebugLocation;
#endif

	UGravityBikeSplineEnemyMissileLauncherComponent LauncherComp;
	private EGravityBikeSplineEnemyMissileState State = EGravityBikeSplineEnemyMissileState::FlyStraight;
	FGravityBikeSplineEnemyMissileRelativeMovementData MovementData;
	private FVector WorldLastHomingTargetLocation;
	private AGravityBikeSplineActor Spline;

	private FTransform CachedSplineTransform;
	private uint CachedSplineTransformFrame;
	private bool bGravityBikeHasReachedEnd;

	FGravityBikeSplineEnemyMissileSettings MissileSettings;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> PlayerDamageEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(GravityBikeWhip::GetPlayer());
		GrabTargetComp.Disable(this);
	}

	void Launch()
	{
		GrabTargetComp.Enable(this);

		FGravityBikeWhipGrabTargetCondition Condition;
		Condition.BindUFunction(this, n"GrabCondition");
		GrabTargetComp.AddTargetCondition(this, Condition);

		GrabTargetComp.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		GrabTargetComp.OnDropped.AddUFunction(this, n"HandleDropped");

		State = EGravityBikeSplineEnemyMissileState::FlyStraight;

		Spline = GravityBikeSpline::GetGravityBikeSpline();

		MovementData = FGravityBikeSplineEnemyMissileRelativeMovementData(
			ActorTransform,
			GetSplineTransform(),
			MissileSettings.FlyStraightMoveSpeed
		);

		WorldLastHomingTargetLocation = FVector::ZeroVector;

		CachedSplineTransform = FTransform::Identity;
		CachedSplineTransformFrame = 0;
		bGravityBikeHasReachedEnd = false;

		HazeSphereComp.SetOpacityOverTime(1.0, MissileSettings.HazeSphereOpacity);

		UGravityBikeSplineEnemyMissileEventHandler::Trigger_OnSpawn(this);

#if EDITOR
		LastDebugTime = Time::GameTimeSeconds;
		LastDebugLocation = ActorLocation;
#endif
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("State", GetStateName());
		TemporalLog.Value("Move Speed", MovementData.AccMoveSpeed.Value);

		if(bDebug)
		{
			const float LineThickness = 10;
			const float LineDuration = 10;
			if(Time::GetGameTimeSince(LastDebugTime) > DebugInterval)
			{
				Debug::DrawDebugLine(LastDebugLocation, ActorLocation, GetStateColor(), LineThickness, LineDuration);
				LastDebugLocation = ActorLocation;
			}
			else
			{
				Debug::DrawDebugLine(LastDebugLocation, ActorLocation, GetStateColor(), LineThickness, 0);
			}

			Debug::DrawDebugString(ActorLocation, GetStateName(), GetStateColor());
		}
	}
#endif

	UFUNCTION()
	private void HandleGrabbed(UGravityBikeWhipComponent WhipComp,
	                           UGravityBikeWhipGrabTargetComponent GrabTarget)
	{
		HazeSphereComp.SetOpacityOverTime(1.0, 0.0);
	}

	UFUNCTION()
	private void HandleDropped(UGravityBikeWhipComponent WhipComp,
	                           UGravityBikeWhipGrabTargetComponent GrabTarget,
	                           EGravityBikeWhipGrabState GrabState,
	                           UGravityBikeWhipThrowTargetComponent ThrowAtTarget)
	{
		HazeSphereComp.SetOpacityOverTime(1.0, MissileSettings.HazeSphereOpacity);
	}

	void TraceForward(FVector TraceStart, FVector TraceEnd)
	{
		check(HasControl());

		if(TraceStart.Equals(TraceEnd))
			return;

		// Trace for movement impacts
		FHitResult HitResult;
		{
			FHazeTraceSettings TraceSettings;
			if(GrabTargetComp.IsGrabbed() || GrabTargetComp.HasThrowTarget())
				TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
			else
				TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);

			TraceSettings.UseCapsuleShape(SweepComp.CapsuleRadius, SweepComp.CapsuleHalfHeight, SweepComp.ComponentQuat);
			TraceSettings.UseShapeWorldOffset(SweepComp.WorldLocation - ActorLocation);


			HitResult = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

#if !RELEASE
			TEMPORAL_LOG(this).HitResults("TraceForward", HitResult, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
#endif
		}

		if (HitResult.bBlockingHit && HitResult.Actor != nullptr)
		{
			// We hit something, damage anything within an explosion radius
			bool bDamageDriver = false;
			TArray<UGravityBikeSplineEnemyHealthComponent> DamageEnemies;

			if(ActorDamagesDriver(HitResult.Actor))
			{
				bDamageDriver = true;
			}
			else
			{
				auto EnemyHealthComp = UGravityBikeSplineEnemyHealthComponent::Get(HitResult.Actor);
				if(EnemyHealthComp != nullptr)
					DamageEnemies.Add(EnemyHealthComp);
			}

			FHazeTraceSettings OverlapTraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Pawn);
			OverlapTraceSettings.UseSphereShape(ExplosionRadiusComp.SphereRadius);

			if(GrabTargetComp.IsGrabbed() || GrabTargetComp.HasThrowTarget())
			{
				OverlapTraceSettings.IgnorePlayers();
				OverlapTraceSettings.IgnoreActor(GravityBikeSpline::GetGravityBike());
			}
			else
			{
				OverlapTraceSettings.IgnoreActor(LauncherComp.Owner);
			}

			const FOverlapResultArray Overlaps = OverlapTraceSettings.QueryOverlaps(HitResult.ImpactPoint);

			for(auto Overlap : Overlaps)
			{
				if(ActorDamagesDriver(HitResult.Actor))
				{
					bDamageDriver = true;
					continue;
				}

				auto EnemyHealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Overlap.Actor);
				if(EnemyHealthComp != nullptr)
					DamageEnemies.AddUnique(EnemyHealthComp);
			}

			const FVector RelativeImpactPoint = HitResult.Component.WorldTransform.InverseTransformPosition(HitResult.ImpactPoint);
			const FVector RelativeImpactNormal = HitResult.Component.WorldTransform.InverseTransformVector(HitResult.ImpactNormal);
			CrumbOnHit(bDamageDriver, DamageEnemies, HitResult.Component, RelativeImpactPoint, RelativeImpactNormal);
		}
	}

	EGravityBikeSplineEnemyMissileState GetState() const
	{
		return State;
	}

	void ChangeState(EGravityBikeSplineEnemyMissileState NewState)
	{
		State = NewState;

		if (State == EGravityBikeSplineEnemyMissileState::Dropped)
		{
			HazeSphereComp.SetOpacityOverTime(1.0, 0.0);
		}

#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Event(f"Changed State: {GetStateName()}");
#endif
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnHit(
		bool bDamageDriver,
		TArray<UGravityBikeSplineEnemyHealthComponent> DamageEnemies,
		UPrimitiveComponent HitComponent,
		FVector RelativeImpactPoint,
		FVector RelativeImpactNormal)
	{
		if(bDamageDriver)
			GravityBikeSpline::DamagePlayer(MissileSettings.PlayerDamage);

		for(auto EnemyHealthComp : DamageEnemies)
		{
			FGravityBikeSplineEnemyTakeDamageData DamageData(
				EGravityBikeSplineEnemyDamageType::Missile,
				MissileSettings.EnemyDamage,
				MissileSettings.bEnemyDamageIsFraction,
				ActorVelocity.GetSafeNormal()
			);

			EnemyHealthComp.TakeDamage(DamageData);
		}

		Explode(
			HitComponent.Owner,
			HitComponent.WorldTransform.TransformPosition(RelativeImpactPoint),
			HitComponent.WorldTransform.TransformVector(RelativeImpactNormal)
		);
	}

	void Explode(AActor HitActor, FVector ExplodeLocation, FVector ExplodeNormal)
	{
		FGravityBikeSplineEnemyMissileOnHitEventData HitEventData;
		HitEventData.HitActor = HitActor;
		HitEventData.HitLocation = ExplodeLocation;
		HitEventData.HitNormal = ExplodeNormal;

		UGravityBikeSplineEnemyMissileEventHandler::Trigger_OnHit(this, HitEventData);
		UGravityBikeSplineEnemyMissileEventHandler::Trigger_OnDestroyed(this);
		DestroyActor();
	}

	bool ActorDamagesDriver(AActor Actor)
	{
		auto GravityBike = Cast<AGravityBikeSpline>(Actor);
		if(GravityBike != nullptr)
			return true;
		
		auto Player = Cast<AHazePlayerCharacter>(Actor);
		if(Player != nullptr)
			return true;

		return false;
	}
	
	FTransform GetSplineTransform()
	{
		check(Spline != nullptr);

		// Use cached transform
		if(Time::FrameNumber == CachedSplineTransformFrame)
			return CachedSplineTransform;

		// If we reached the end of the spline, pretend that the spline is infinite by keeping the previous transform
		if(bGravityBikeHasReachedEnd)
			return CachedSplineTransform;
		
		// If the bike has changed spline, we must continue on the previous spline
		if(GravityBikeSpline::GetGravityBikeSpline() != Spline)
			return CachedSplineTransform;

		// If we reached the end this frame, set a flag
		if(GravityBikeSpline::GetGravityBikeDistanceAlongSpline(Spline) > Spline.SplineComp.SplineLength)
		{
			bGravityBikeHasReachedEnd = true;
			return CachedSplineTransform;
		}

		// Cache the spline transform
		CachedSplineTransform = GravityBikeSpline::GetGravityBikeSplineTransform(Spline);
		CachedSplineTransformFrame = Time::FrameNumber;
		return CachedSplineTransform;
	}

	FVector GetPlayerLocation() const
	{
		return GravityBikeSpline::GetDriverPlayer().ActorLocation;
	}

	FVector GetPlayerRelativeToSplineLocation()
	{
		return GetSplineTransform().InverseTransformPositionNoScale(GravityBikeSpline::GetDriverPlayer().ActorLocation);
	}

	bool HasValidTarget() const
	{
		if(!IsValid(GrabTargetComp.GetThrowTarget()))
			return false;

		auto HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(GrabTargetComp.GetThrowTarget().Owner);
		if(HealthComp != nullptr && HealthComp.IsDead())
			return false;

		return true;
	}

	// UFUNCTION(BlueprintPure)
	// FVector GetPredictedTargetWorldLocation() const
	// {
	// 	const FVector HomingTargetLocation = GrabTargetComp.GetThrowTargetWorldLocation();
	// 	const FVector HomingTargetVelocity = GrabTargetComp.GetThrowTargetVelocity();

	// 	const float DistanceToTarget = HomingTargetLocation.Distance(ActorLocation);
	// 	const float TimeToImpact = DistanceToTarget / MovementData.AccMoveSpeed.Value;

	// 	FVector WorldHomingOffset = HomingTargetVelocity * TimeToImpact;

	// 	return HomingTargetLocation + WorldHomingOffset;
	// }

	UFUNCTION()
	private bool GrabCondition()
	{
		return State == EGravityBikeSplineEnemyMissileState::Homing;
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateVFX() {}

#if EDITOR
	private FLinearColor GetStateColor() const
	{
		switch(State)
		{
			case EGravityBikeSplineEnemyMissileState::FlyStraight:
				return FLinearColor::Green;

			case EGravityBikeSplineEnemyMissileState::TurnAround:
				return FLinearColor::Yellow;

			case EGravityBikeSplineEnemyMissileState::Homing:
				return FLinearColor::Red;

			case EGravityBikeSplineEnemyMissileState::Dropped:
				return FLinearColor::LucBlue;
		}
	}

	private FString GetStateName() const
	{
		if(GrabTargetComp.IsGrabbed())
			return "Grabbed";

		return f"{State:n}";
	}
#endif
};