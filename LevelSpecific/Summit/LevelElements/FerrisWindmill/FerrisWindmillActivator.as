class AFerrisWindmillActivator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent YawRotationPivot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"FerrisWindmillActivatorRotateCapability");

	UPROPERTY(DefaultComponent, Attach = YawRotationPivot)
	UStaticMeshComponent LeftRotateMeshComp;

	UPROPERTY(DefaultComponent, Attach = LeftRotateMeshComp)
	UTeenDragonTailAttackResponseComponent LeftRotateResponseComp;
	default LeftRotateResponseComp.bIsPrimitiveParentExclusive = true;
	default LeftRotateResponseComp.bShouldStopPlayer = true;

	UPROPERTY(DefaultComponent, Attach = YawRotationPivot)
	UStaticMeshComponent RightRotateMeshComp;

	UPROPERTY(DefaultComponent, Attach = RightRotateMeshComp)
	UTeenDragonTailAttackResponseComponent RightRotateResponseComp;
	default RightRotateResponseComp.bIsPrimitiveParentExclusive = true;
	default RightRotateResponseComp.bShouldStopPlayer = true;

	UPROPERTY(EditAnywhere, Category = "Roll Rotate")
	float TimeToCompleteRotation = 1.0;

	UPROPERTY(EditAnywhere, Category = "Roll Rotate")
	FRuntimeFloatCurve RollRotationCurve;
	default RollRotationCurve.AddDefaultKey(0.0, 0.0);
	default RollRotationCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditInstanceOnly)
	AFerrisWindmillBlades WindmillBlades; 

	float RotationAmountPerHit = 45.0;

	float TimeLastHitByRoll;

	FQuat TargetQuat;
	FQuat StartQuat;
	FQuat FireTargetQuat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftRotateResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRollLeft");
		RightRotateResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRollRight");
	}

	UFUNCTION()
	private void OnHitByRollLeft(FRollParams Params)
	{
		GetHitByRoll(false, Params.HitLocation, Params.PlayerInstigator);
	}

	UFUNCTION()
	private void OnHitByRollRight(FRollParams Params)
	{
		GetHitByRoll(true, Params.HitLocation, Params.PlayerInstigator);
	}

	private void GetHitByRoll(bool bRight, FVector HitLocation, AHazePlayerCharacter Player)
	{
		float Multplier = 1;

		if (!bRight)
			Multplier = -1;

		FVector FlatHitLocation = HitLocation.ConstrainToPlane(FVector::UpVector);
		FVector FlatPlayerLocation = Player.ActorLocation.ConstrainToPlane(FVector::UpVector);
		FVector DirToHit = (FlatPlayerLocation - FlatHitLocation).GetSafeNormal();

		FVector HitCompareVector = bRight ?
									   RightRotateMeshComp.ForwardVector :
									   LeftRotateMeshComp.ForwardVector;

		// Didn't hit it in the correct direction
		if (DirToHit.DotProduct(HitCompareVector) < 0.4)
			return;

		StartQuat = YawRotationPivot.RelativeRotation.Quaternion();
		TargetQuat *= FRotator(0, RotationAmountPerHit * Multplier, 0.0).Quaternion();

		auto TargetRotation = TargetQuat.Rotator();
		TargetQuat = TargetRotation.Quaternion();

		TimeLastHitByRoll = Time::GameTimeSeconds;

		WindmillBlades.AddRotationOnImpact(bRight);
	}


	// private void RotateTowardsTarget(float TimeSinceHit)
	// {
	// 	float AlphaTime = TimeSinceHit / TimeToCompleteRotation;
	// 	float AlphaToReachTarget = RollRotationCurve.GetFloatValue(AlphaTime);

	// 	if (Math::IsNearlyEqual(AlphaToReachTarget, 1.0))
	// 		AlphaToReachTarget = 1.0;

	// 	PitchRotationPivot.RelativeRotation = FQuat::Slerp(StartQuat, TargetQuat, AlphaToReachTarget).Rotator();
	// }
};