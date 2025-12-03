class ASummitSuspendedLog : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;
	default	AxisRotateComp.Friction = 1.8;
	default	AxisRotateComp.TorqueBounds = 100.0;
	default	AxisRotateComp.SpringStrength = 0.0;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	UFauxPhysicsWeightComponent WeightComp;
	default WeightComp.MassScale = 1.0;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	UStaticMeshComponent LogConnector;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	UStaticMeshComponent LogMesh;

	UPROPERTY(DefaultComponent, Attach = LogMesh)
	UStaticMeshComponent RollSymbol;

	UPROPERTY(DefaultComponent, Attach = RollSymbol)
	UTeenDragonTailAttackResponseComponent ResponseComp;
	default ResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(EditInstanceOnly)
	ASummitTailFallingPillar Pillar;

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

	float CurrentDot = 0.0;

	bool bGonePastPoint;
	bool bHasRung = true;

	bool bHasHitPillar;

	//Bell Data
	FVector SavedHitPoint;
	float BellTravelDistance = 1400.0;

	FRotator LogMeshRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		SetActorControlSide(Game::Zoe);
		LogMeshRotation = LogMesh.WorldRotation;
		AxisRotateComp.OnMinConstraintHit.AddUFunction(this, n"OnMinConstraintHit");
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LogMesh.WorldRotation = LogMeshRotation;

		if (LogConnector.WorldRotation.Pitch > 51.0 && !bHasHitPillar)
		{
			Pillar.Start();
			bHasHitPillar = true;
		}

		if (CurrentDot < 0.65 && !bGonePastPoint)
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
		AxisRotateComp.ResetPhysics();
		AxisRotateComp.ApplyImpulse(Params.HitLocation, Params.RollDirection * 320.0);

		SaveHitLocation = LogMesh.WorldTransform.InverseTransformPosition(Params.HitLocation);
		SaveRollDirection = Params.RollDirection;
		
		SavedHitPoint = Params.HitLocation;
	}

	UFUNCTION()
	private void OnMinConstraintHit(float Strength)
	{
		Pillar.Start();
	}
};