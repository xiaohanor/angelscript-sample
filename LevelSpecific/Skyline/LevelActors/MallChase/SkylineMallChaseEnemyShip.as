UCLASS(Abstract)
class USkylineMallChaseEnemyShipEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	ASkylineMallChaseEnemyShip AttackShip;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackShip = Cast<ASkylineMallChaseEnemyShip>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireProjectile(FGameplayWeaponParams GameplayWeaponParams)
	{

	}	
}

class ASkylineMallChaseEnemyShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USkylineHighwayFloatingComponent FloatingComp;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent MissilePivotLeft;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent MissilePivotRight;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent WeaponPivot;

	UPROPERTY(DefaultComponent, Attach = WeaponPivot)
	USceneComponent AttackPivot;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	FVector Offset = FVector::ZeroVector;

	UPROPERTY(EditAnywhere)
	float OffsetOnSpline = 12000.0;

	UPROPERTY(EditAnywhere)
	float MovementSpeed = 6000.0;

	UPROPERTY(EditAnywhere)
	float LerpSpeed = 1.0;

	UPROPERTY(EditAnywhere)
	bool bUseMovementPrediction = true;

	UPROPERTY(EditAnywhere)
	bool bTurretActivated = false;

	UPROPERTY(EditInstanceOnly)
	AActor MovementSpline;
	UHazeSplineComponent Spline;
	FSplinePosition SplinePosition;
	FSplinePosition LerpedSplinePosition;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineMallChaseEnemyShipTurretProjectile> TurretProjectileClass;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineMallChaseEnemyShipProjectile> ShipProjectileClass;

	float TurretFireInterval = 0.1;
	float TurretFireTime = 0.0;

	bool bFireFromLeftMissilePivot = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		if (MovementSpline != nullptr)
		{
			Spline = UHazeSplineComponent::Get(MovementSpline);
			if (Spline != nullptr)
			{
				SplinePosition = Spline.GetSplinePositionAtSplineDistance(0.0);
				LerpedSplinePosition = SplinePosition;
			}
		}
	
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		auto GlassRoofSegment = Cast<ASkylineBreakableGlassRoofSegment>(Caller);
		if (GlassRoofSegment == nullptr)
			return;

		auto MissileFirePivot = (GlassRoofSegment.bLeftFire ? MissilePivotLeft : MissilePivotRight);

		auto Missile = SpawnActor(ShipProjectileClass, bDeferredSpawn = true);
		Missile.SplineMissileComp.OnImpact.AddUFunction(GlassRoofSegment, n"Explode");
		Missile.Target = GlassRoofSegment.ImpactTargetPivot.WorldTransform;
		Missile.TimeToImpact = GlassRoofSegment.ProjectileTimeToImpact;
		FTransform SpawnTransform;
		SpawnTransform.Location = MissileFirePivot.WorldLocation;
		SpawnTransform.Rotation = MissileFirePivot.ComponentQuat;
		FinishSpawningActor(Missile, SpawnTransform);

		bFireFromLeftMissilePivot = !bFireFromLeftMissilePivot;

		BP_LaunchMissile(SpawnTransform.GetRelativeTransform(Pivot.WorldTransform));
	}

	UFUNCTION(BlueprintEvent)
	void BP_LaunchMissile(FTransform LaunchTransform)
	{

	}

	UFUNCTION()
	private void HandleFollowerStart()
	{
		RemoveActorDisable(this);
	}

	UFUNCTION()
	private void HandlePlayerBehindLine(AHazePlayerCharacter Player)
	{
		Player.KillPlayer();
	}

	UFUNCTION()
	void FireAtTarget(AActor AActor)
	{

	}

	UFUNCTION()
	void StopShooting(AActor AActor)
	{
		bTurretActivated = false;
	}	

	UFUNCTION()
	void ActivateAndFollowSpline(AActor Actor)
	{
		auto NewSpline = UHazeSplineComponent::Get(Actor);
		
		if (NewSpline == nullptr)
			return;

		Spline = NewSpline;

		SplinePosition = Spline.GetSplinePositionAtSplineDistance(0.0);
		LerpedSplinePosition = SplinePosition;

		RemoveActorDisable(this);
	}

	UFUNCTION()
	void ActivateAndSetAtEndOfSpline(AActor Actor)
	{
		auto NewSpline = UHazeSplineComponent::Get(Actor);
		
		if (NewSpline == nullptr)
			return;

		Spline = NewSpline;

		SplinePosition = Spline.GetSplinePositionAtSplineDistance(Spline.SplineLength);
		LerpedSplinePosition = SplinePosition;

		RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Spline != nullptr)
		{
			auto TargetSplinePosition = Spline.GetClosestSplinePositionToWorldLocation(Game::GetClosestPlayer(ActorLocation).ActorLocation);
//			Debug::DrawDebugPoint(TargetSplinePosition.WorldLocation, 100.0, FLinearColor::Green, 0.0);
		
			float DeltaMove = SplinePosition.DeltaToReachClosest(TargetSplinePosition);

			SplinePosition.Move(Math::Sign(DeltaMove) * MovementSpeed * DeltaSeconds);
		
			float LerpedDistance = Math::Lerp(LerpedSplinePosition.CurrentSplineDistance, SplinePosition.CurrentSplineDistance, LerpSpeed * DeltaSeconds);

			LerpedSplinePosition = Spline.GetSplinePositionAtSplineDistance(LerpedDistance);

//			Debug::DrawDebugPoint(LerpedSplinePosition.WorldLocation, 100.0, FLinearColor::Red, 0.0);

			auto OffsetSplinePosition = Spline.GetSplinePositionAtSplineDistance(LerpedDistance + OffsetOnSpline);

//			ActorLocation = LerpedSplinePosition.WorldTransformNoScale.TransformPosition(Offset);
			ActorLocation = OffsetSplinePosition.WorldTransformNoScale.TransformPosition(Offset);

			FVector ToTarget = TargetSplinePosition.WorldLocation - ActorLocation;
			ToTarget = ToTarget.VectorPlaneProject(FVector::UpVector);
			SetActorRotation(FQuat::Slerp(ActorQuat, ToTarget.ToOrientationQuat(), DeltaSeconds * 2.0));
		}
		else if (Spline != nullptr)
		{
			bool bEndOfSpline = !SplinePosition.Move(MovementSpeed * DeltaSeconds);
		
			float LerpedDistance = Math::Lerp(LerpedSplinePosition.CurrentSplineDistance, SplinePosition.CurrentSplineDistance, LerpSpeed * DeltaSeconds);

			LerpedSplinePosition = Spline.GetSplinePositionAtSplineDistance(LerpedDistance);

			auto OffsetSplinePosition = Spline.GetSplinePositionAtSplineDistance(LerpedDistance + OffsetOnSpline);

			ActorLocation = OffsetSplinePosition.WorldTransformNoScale.TransformPosition(Offset);

			SetActorRotation(FQuat::Slerp(ActorQuat, LerpedSplinePosition.WorldForwardVector.VectorPlaneProject(FVector::UpVector).ToOrientationQuat(), DeltaSeconds * 2.0));
		
			if (Math::IsNearlyEqual(LerpedSplinePosition.CurrentSplineDistance, LerpedSplinePosition.CurrentSpline.SplineLength))
				Spline = nullptr;
		}

		// Turret
		if (bTurretActivated && Time::GameTimeSeconds > TurretFireTime)
		{
			TurretFireTime = Time::GameTimeSeconds + TurretFireInterval;

			FVector ToFollowerTarget = Game::GetClosestPlayer(ActorLocation).ActorLocation - AttackPivot.WorldLocation;

//				Debug::DrawDebugLine(AttackPivot.WorldLocation, AttackPivot.WorldLocation + ToFollowerTarget * 10000.0, FLinearColor::Red, 10.0, 0.5);

			auto TurretProjectile = Cast<ASkylineMallChaseEnemyShipTurretProjectile>(SpawnActor(TurretProjectileClass, bDeferredSpawn = true, Level = GetLevel()));
			TurretProjectile.Instigator = this;
			TurretProjectile.SetLifeSpan(2.0);

			FVector RandomPoint = ((Math::GetRandomPointOnSquare() - (FVector::OneVector * 0.5))) * 2.0 * FVector(200.0, 500.0, 0.0);

			RandomPoint -= FVector::ForwardVector * 3000.0;

			RandomPoint = Game::GetClosestPlayer(ActorLocation).ActorTransform.TransformPositionNoScale(RandomPoint);

//				Debug::DrawDebugPoint(RandomPoint, 30.0, FLinearColor::Red, 0.5);

			ToFollowerTarget = RandomPoint - AttackPivot.WorldLocation;

//				FVector LaunchDirection = Math::VRandCone(WorldRotation.ForwardVector, Math::DegreesToRadians(SpreadAngle));

			WeaponPivot.SetWorldRotation(FQuat::Slerp(WeaponPivot.ComponentQuat, (Game::GetClosestPlayer(ActorLocation).ActorLocation - WeaponPivot.WorldLocation).ToOrientationQuat(), DeltaSeconds * 3.0));

			FTransform SpawnTransform;
			SpawnTransform.Location = AttackPivot.WorldLocation;
			SpawnTransform.Rotation = ToFollowerTarget.ToOrientationQuat();

			FinishSpawningActor(TurretProjectile, SpawnTransform);
		
			FGameplayWeaponParams WeaponParams;
			WeaponParams.ShotsFiredAmount = 1;
			TriggerOnShotFired(WeaponParams);
			USkylineMallChaseEnemyShipEventHandler::Trigger_OnFireProjectile(this, WeaponParams);			
		}

	}

	void Explode()
	{
		BP_Explode();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode() { }

	UFUNCTION(BlueprintEvent)
	void TriggerOnShotFired(FGameplayWeaponParams GameplayWeaponParams){}
};