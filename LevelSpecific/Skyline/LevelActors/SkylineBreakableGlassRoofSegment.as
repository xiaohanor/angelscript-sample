event void FSkylineBreakableGlassRoofSegmentSignature();
class ASkylineBreakableGlassRoofSegment : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent StaticMesh;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	USceneComponent ImpactTargetPivot;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ExplosionVFX;

	UPROPERTY(DefaultComponent, Attach = ImpactTargetPivot)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY(EditAnywhere)
	UStaticMesh RuinMesh;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Animation;
	default Animation.Duration = 1.0;
	default Animation.bCurveUseNormalizedTime = true;
	default Animation.Curve.AddDefaultKey(0.0, 0.0);
	default Animation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	float ProjectileTimeToImpact = 3.0;

	UPROPERTY(EditAnywhere)
	bool bLeftFire = false;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AActor> ProjectileClass;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	float ProjectileSpinRadius = 300.0;

	UPROPERTY(EditAnywhere)
	float ProjectileSpinSpeed = 360.0;

	AActor Projectile;

	FSkylineBreakableGlassRoofSegmentSignature OnMissileHit;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (StaticMesh.StaticMesh != nullptr)
		{
			Spline.RelativeLocation = StaticMesh.StaticMesh.Bounds.Origin;
			ImpactTargetPivot.RelativeLocation = StaticMesh.StaticMesh.Bounds.Origin;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");

		Animation.BindUpdate(this, n"OnAnimationUpdate");
		Animation.BindFinished(this, n"OnAnimationFinished");
	
		Animation.PlayRate = 1.0 / ProjectileTimeToImpact;
	
		if (PlayerTrigger != nullptr)
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		Activate();
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		PlayerTrigger.OnPlayerEnter.Unbind(this, n"HandlePlayerEnter");

		Activate();
/*
		if (!Animation.IsPlaying())
			Activate();
*/
	}

	UFUNCTION()
	void OnAnimationUpdate(float Value)
	{
		FVector StartLocation = Projectile.ActorLocation;

		float Distance = Spline.SplineLength * (1.0 - Value);
		auto SplinePosition = Spline.GetSplinePositionAtSplineDistance(Distance);
		SplinePosition.ReverseFacing();
	
		FVector Offset = SplinePosition.WorldTransformNoScale.TransformVectorNoScale((FVector::RightVector * ProjectileSpinRadius).RotateAngleAxis(ProjectileSpinSpeed * Projectile.GameTimeSinceCreation, FVector::ForwardVector));

		FVector ProjectileLocation = SplinePosition.WorldLocation + Offset;
		FQuat ProjectileRotation = (ProjectileLocation - StartLocation).ToOrientationQuat();

		Projectile.SetActorLocationAndRotation(ProjectileLocation, ProjectileRotation);
	}

	UFUNCTION()
	void OnAnimationFinished()
	{
		Explode();
	}

	UFUNCTION(DevFunction)
	void DevActivateGlassSegmentDestruction()
	{
		Activate();
	}

	UFUNCTION()
	void Activate()
	{
		ActionQueueComp.Idle(ProjectileTimeToImpact * 0.6); // 0.8
		ActionQueueComp.Event(this, n"DelayedLaunch");

//		InterfaceComp.TriggerActivate();

/*
		auto SplinePosition = Spline.GetSplinePositionAtSplineDistance(Spline.SplineLength);
		FTransform SpawnTransform = SplinePosition.WorldTransformNoScale;
		Projectile = SpawnActor(ProjectileClass, SpawnTransform.Location, SpawnTransform.Rotator());
	
		Animation.Play();
*/
	}

	UFUNCTION()
	private void DelayedLaunch()
	{
		ProjectileTimeToImpact *= 0.4; // 0.2
		InterfaceComp.TriggerActivate();
	}

	UFUNCTION()
	void Explode()
	{
		BP_Explode();
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		if (Projectile != nullptr)
			Projectile.DestroyActor();

		FVector Origin = ActorTransform.TransformPosition(StaticMesh.StaticMesh.Bounds.Origin);

		for (auto Player : Game::Players)
			Player.PlayWorldCameraShake(CameraShakeClass, this, Origin, 5000.0, 10000.0);
		
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, Origin, ActorRotation, ActorScale3D);
		USkylineBreakableGlassRoofSegmentEffectEventHandler::Trigger_Destroyed(this);
		OnMissileHit.Broadcast();

		StaticMesh.SetStaticMesh(RuinMesh);
//		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode()
	{

	}
}

class USkylineBreakableGlassRoofSegmentEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Destroyed() {}
	
}