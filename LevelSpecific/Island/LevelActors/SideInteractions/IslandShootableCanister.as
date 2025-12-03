class AIslandShootableCanister : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CollisionCapsule;
	
	UPROPERTY(DefaultComponent, Attach = "CollisionCapsule")
	UIslandRedBlueImpactOverchargeResponseComponent RedShootingComponent;

	UPROPERTY(DefaultComponent, Attach = "CollisionCapsule")
	UIslandRedBlueImpactOverchargeResponseComponent BlueShootingComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 10000;
	default DisableComp.bAutoDisable = true;

	bool bIsExploded;

	UPROPERTY(EditAnywhere)
	bool bShouldRotate = false;

	UPROPERTY(EditAnywhere)
	bool bKeepCollisionOnExploded;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;
	float DistanceAlongSpline;
	FVector DestinationUpVector = FVector::UpVector;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 3.0;
	default MoveAnimation.UseLinearCurveZeroToOne();

	UPROPERTY()
	FRuntimeFloatCurve Speed;
	default Speed.AddDefaultKey(0.0, 0.0);
	default Speed.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);

	FRotator RotationSpeed = FRotator(0,-1,0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RedShootingComponent.OnImpactEvent.AddUFunction(this, n"HandleImpact");
		RedShootingComponent.OnFullCharge.AddUFunction(this, n"HandleFullAlpha");
		BlueShootingComponent.OnImpactEvent.AddUFunction(this, n"HandleImpact");
		BlueShootingComponent.OnFullCharge.AddUFunction(this, n"HandleFullAlpha");

		if(SplineActor == nullptr)
			return;

		Root.SetHiddenInGame(true, true);

		Spline = SplineActor.Spline;
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bShouldRotate)
			Root.AddLocalRotation(RotationSpeed);
	}

	UFUNCTION()
	void HandleFullAlpha(bool bWasOvercharged)
	{
		if (bIsExploded)
			return;

		ExplodeCanister();
	}

	UFUNCTION()
	void HandleImpact(FIslandRedBlueImpactResponseParams ImpactData)
	{
		if (bIsExploded)
			return;

		UIslandShootableCanisterEventHandler::Trigger_OnImpact(this);
	}

	UFUNCTION()
	void ExplodeCanister()
	{
		UIslandShootableCanisterEventHandler::Trigger_OnExploded(this);
		bIsExploded = true;
		BP_ExplodeCanister();
	}

	UFUNCTION()
	void ResetCanister()
	{
		bIsExploded = false;
		BP_ResetCanister();
	}

	UFUNCTION()
	void LaunchCanister()
	{
		RotationSpeed = FRotator(10,10,10);
		bShouldRotate = true;
		MoveAnimation.PlayFromStart();
		Root.SetHiddenInGame(false, true);
		CollisionCapsule.SetHiddenInGame(true,true);
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		
		DistanceAlongSpline = Spline.SplineLength * Speed.GetFloatValue(Alpha);

		FTransform TransformAtDistance = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector CurrentLocation = TransformAtDistance.Location;
		FQuat CurrentRotation = FQuat::Slerp(TransformAtDistance.Rotation, FQuat::MakeFromZX(DestinationUpVector, TransformAtDistance.Rotation.ForwardVector), Rotation.GetFloatValue(Alpha));
		
		SetActorLocationAndRotation(CurrentLocation, CurrentRotation);

	}

	UFUNCTION()
	void OnFinished()
	{
		ExplodeCanister();
		Root.SetHiddenInGame(true, true);
		bShouldRotate = false;
		OnUpdate(0);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ExplodeCanister() {}

	UFUNCTION(BlueprintEvent)
	void BP_ImpactCanister() {}

	UFUNCTION(BlueprintEvent)
	void BP_ResetCanister() {}

};