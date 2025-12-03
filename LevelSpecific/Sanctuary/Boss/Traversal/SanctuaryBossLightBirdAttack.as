class ASanctuaryBossLightBirdAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossHydraHead HydraHead;
	USceneComponent HydraHeadComp;

	UPROPERTY(EditAnywhere)
	float TargetScale = 70.0;

	FHazeRuntimeSpline RuntimeSpline;

	bool bIsAttacking = false;
	bool bReturning = false;

	float Distance = 0.0;

	FTransform InitialRelativeTransform;
	FVector Offset = FVector::UpVector * 2000.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike AttackTimeLike;
	default AttackTimeLike.Duration = 1.0;
	default AttackTimeLike.bCurveUseNormalizedTime = true;
	default AttackTimeLike.Curve.AddDefaultKey(0.0, 0.0);
	default AttackTimeLike.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ExitTimeLike;
	default AttackTimeLike.Duration = 1.0;
	default AttackTimeLike.bCurveUseNormalizedTime = true;	
	default ExitTimeLike.Curve.AddDefaultKey(0.0, 0.0);
	default ExitTimeLike.Curve.AddDefaultKey(1.0, 1.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		if (HydraHead != nullptr)
			HydraHeadComp = HydraHead.HeadPivot;

		AttackTimeLike.BindUpdate(this, n"AttackUpdate");
		AttackTimeLike.BindFinished(this, n"AttackFinished");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsAttacking)
			return;

//		Distance += 2500.0 * DeltaSeconds;

		UpdateSpline();

		FVector Location;
		FRotator Rotation;
		RuntimeSpline.GetLocationAndRotationAtDistance(RuntimeSpline.Length * AttackTimeLike.Value, Location, Rotation);

		FTransform NewTransform;
		NewTransform.Location = Location;
		NewTransform.Rotation = Rotation.Quaternion();
		NewTransform.Scale3D = Math::VLerp(ActorScale3D, FVector::OneVector * TargetScale, FVector::OneVector * 0.5 * DeltaSeconds);

		ActorTransform = NewTransform;
/*
		SetActorLocationAndRotation(
			Location,
			Rotation
		);
*/
	}

	UFUNCTION()
	void AttackUpdate(float Value)
	{

	}

	UFUNCTION()
	void AttackFinished()
	{
		InitialRelativeTransform = Root.RelativeTransform;
		BP_AttackFinished();
		if (!bReturning)
		{
			HydraHead.BlockCapabilities(n"HydraHeadMovement", this);
			HydraHeadComp.AttachToComponent(Root, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			AttackTimeLike.PlayFromStart();
		}

		if (bReturning)
			HydraHead.AddActorDisable(this);

		bReturning = true;
	}

	void UpdateSpline()
	{
		if (bReturning)
		{
			FVector TargetLocation = FVector::UpVector * 20000.0 + FVector::ForwardVector * -40000.0;

			RuntimeSpline = FHazeRuntimeSpline();
			RuntimeSpline.AddPoint(InitialRelativeTransform.Location);
			RuntimeSpline.AddPoint(InitialRelativeTransform.Location + InitialRelativeTransform.Rotation.ForwardVector * 3000.0 + FVector::UpVector * 3000.0);
			RuntimeSpline.AddPoint(TargetLocation);

			TArray<FVector> UpDirections;
			UpDirections.Add(InitialRelativeTransform.Rotation.UpVector);
			UpDirections.Add(InitialRelativeTransform.Rotation.UpVector);
			UpDirections.Add(InitialRelativeTransform.Rotation.UpVector);
			RuntimeSpline.UpDirections = UpDirections;
			RuntimeSpline.SetCustomEnterTangentPoint(InitialRelativeTransform.Location - InitialRelativeTransform.Rotation.ForwardVector);
			RuntimeSpline.SetCustomExitTangentPoint(TargetLocation - FVector::UpVector);

		}
		else
		{
			FVector TargetLocation = HydraHeadComp.WorldTransform.TransformPositionNoScale(Offset);

			RuntimeSpline = FHazeRuntimeSpline();
			RuntimeSpline.AddPoint(InitialRelativeTransform.Location);
			RuntimeSpline.AddPoint(TargetLocation + HydraHeadComp.UpVector * 1000.0 - HydraHeadComp.RightVector * 3000.0);
			RuntimeSpline.AddPoint(TargetLocation);

			TArray<FVector> UpDirections;
			UpDirections.Add(InitialRelativeTransform.Rotation.UpVector);
			UpDirections.Add(InitialRelativeTransform.Rotation.UpVector);
			UpDirections.Add(HydraHeadComp.UpVector);
			RuntimeSpline.UpDirections = UpDirections;
			RuntimeSpline.SetCustomEnterTangentPoint(InitialRelativeTransform.Location - InitialRelativeTransform.Rotation.ForwardVector);
			RuntimeSpline.SetCustomExitTangentPoint(TargetLocation + HydraHeadComp.RightVector);
		}
	}

	UFUNCTION()
	void Attack()
	{
		InitialRelativeTransform = Root.RelativeTransform;
		RemoveActorDisable(this);		
		bIsAttacking = true;
		AttackTimeLike.Play();
	}

	UFUNCTION(BlueprintEvent)
	void BP_AttackFinished() { }
};