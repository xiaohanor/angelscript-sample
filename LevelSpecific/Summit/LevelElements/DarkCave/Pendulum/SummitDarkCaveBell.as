class ASummitDarkCaveBell : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent ConeRotateComp;
	default ConeRotateComp.ConeAngle = 160.0;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UFauxPhysicsWeightComponent WeightComp;
	default WeightComp.MassScale = 0.5;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UStaticMeshComponent BellConnector;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UFauxPhysicsConeRotateComponent BellConeRotateComp;
	default BellConeRotateComp.SpringStrength = 0.2;
	default BellConeRotateComp.ConeAngle = 80.0;

	UPROPERTY(DefaultComponent, Attach = BellConeRotateComp)
	UStaticMeshComponent BellMesh;

	UPROPERTY(DefaultComponent, Attach = BellMesh)
	UTeenDragonTailAttackResponseComponent ResponseComp;
	default ResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASummitDarkCavePlatform> DarkCavePlatformClass;

	FHazeAcceleratedVector AccelAxis;

	FVector SaveHitLocation;
	FVector SaveRollDirection;

	float AngleTarget;
	FHazeAcceleratedFloat AccelFloat;
	FVector TargetRotationAxis;
	FVector CurrentRotationAxis;
	FVector CurrentForceDirection;

	FHazeAcceleratedFloat AccelWeightScale;
	float TargetWeightScale = 0.1;

	float LastDot;
	float Dot;

	bool bGonePastPoint;
	bool bHasRung = true;

	//Bell Data
	FVector SavedHitPoint;
	float BellVerticalDistance = 900.0;
	float BellHorizontalDistance = 1500.0;

	UHazeActorNetworkedSpawnPoolComponent SpawnPoolComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		SetActorControlSide(Game::Zoe);
	
		SpawnPoolComp = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(DarkCavePlatformClass, Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ConeRotateComp.Friction = 1.8;
		ConeRotateComp.TorqueBounds = 100.0;
		ConeRotateComp.SpringStrength = 0.0;

		Dot = BellMesh.UpVector.DotProduct(FVector::UpVector);
		float Difference = (Dot - LastDot) * 1.0;

		if (Dot < 0.4 && !bHasRung)
		{
			bHasRung = true;
			RingaDingDing();
		}

		if (Dot < 0.65 && !bGonePastPoint)
			bGonePastPoint = true;
		
		if (bGonePastPoint)
			AccelWeightScale.AccelerateTo(TargetWeightScale, 5.0, DeltaSeconds);
		
		WeightComp.MassScale = AccelWeightScale.Value;
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		bGonePastPoint = false;
		bHasRung = false;
		AccelWeightScale.SnapTo(0.0);
		ConeRotateComp.ResetPhysics();
		ConeRotateComp.ApplyImpulse(Params.HitLocation, Params.RollDirection * 280.0);

		SaveHitLocation = BellMesh.WorldTransform.InverseTransformPosition(Params.HitLocation);
		SaveRollDirection = Params.RollDirection;
		
		SavedHitPoint = Params.HitLocation;
		USummitDarkCaveBellEffectHandler::Trigger_OnBellImpactByRoll(this);
	}

	void RingaDingDing()
	{
		if (HasControl())
			SpawnPlatform();
		
		SaveHitLocation = BellMesh.WorldTransform.TransformPosition(SaveHitLocation);
		// Debug::DrawDebugSphere(SaveHitLocation, 200.0, LineColor = FLinearColor::Green, Thickness = 10.0, Duration = 20.0);
		USummitDarkCaveBellEffectHandler::Trigger_OnBellRing(this, FDarkCaveBellParams(ActorLocation));
		BellConeRotateComp.ApplyImpulse(SaveHitLocation, FVector::UpVector * 600.0);

		//Spawn effect
	}

	private void SpawnPlatform()
	{
		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Location = BellMesh.WorldLocation;
		SpawnParams.Rotation = FRotator::ZeroRotator;
		auto PlatformActor = SpawnPoolComp.SpawnControl(SpawnParams);
		auto Platform = Cast<ASummitDarkCavePlatform>(PlatformActor);

		FVector HitDirection = (BellMesh.WorldLocation - SavedHitPoint).GetSafeNormal();
		FVector HitHorizontal = HitDirection.ConstrainToPlane(FVector::UpVector).GetSafeNormal() * BellHorizontalDistance;
		FVector HitVertical = FVector::UpVector * BellVerticalDistance;
		FVector TargetLoc = BellMesh.WorldLocation + (HitHorizontal + HitVertical);
		FVector HorizontalDir = HitDirection.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		Platform.CrumbActivatePlatform(BellMesh.WorldLocation + (HorizontalDir * 1150.0) + (FVector::UpVector * 200.0), TargetLoc, this);
	}
};