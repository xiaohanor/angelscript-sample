class AMagneticFieldGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent DoorRoot;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldComp;

	UPROPERTY(EditAnywhere)
	bool bLockOnMinConstraint = false;

	UPROPERTY(EditAnywhere)
	bool bLockOnMaxConstraint = false;

	UPROPERTY(BlueprintReadOnly)
	float VelocityAlpha = 0.0;

	UPROPERTY(EditAnywhere)
	bool bFullyOpenWhenAffectedByMagnet = false;
	bool bAutomaticOpenStarted = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> HitConstraintCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HitConstraintFF;

	float PreviousYaw = 0.0;

	bool bWasMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PreviousYaw = DoorRoot.RelativeRotation.Yaw;

		DoorRoot.OnMinConstraintHit.AddUFunction(this, n"MinConstraintHit");
		DoorRoot.OnMaxConstraintHit.AddUFunction(this, n"MaxConstraintHit");

		MagneticFieldComp.OnStartBeingMagneticallyAffected.AddUFunction(this, n"StartMagnetizing");
		MagneticFieldComp.OnStopBeingMagneticallyAffected.AddUFunction(this, n"StopMagnetizing");
	}

	UFUNCTION()
	private void MinConstraintHit(float Strength)
	{
		if (bLockOnMinConstraint)
			DoorRoot.AddDisabler(this);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(HitConstraintCamShake, this, DoorRoot.WorldLocation, 1600.0, 2400.0);

		ForceFeedback::PlayWorldForceFeedback(HitConstraintFF, DoorRoot.WorldLocation, true, this, 1600.0, 800.0);

		UMagneticFieldGateEffectEventHandler::Trigger_FullyOpened(this);
	}

	UFUNCTION()
	private void MaxConstraintHit(float Strength)
	{
		if (bLockOnMaxConstraint)
			DoorRoot.AddDisabler(this);

		UMagneticFieldGateEffectEventHandler::Trigger_FullyOpened(this);
	}

	UFUNCTION()
	private void StartMagnetizing()
	{
		if (bFullyOpenWhenAffectedByMagnet)
		{
			bAutomaticOpenStarted = true;
			MagneticFieldComp.bMagnetized = false;
		}

		UMagneticFieldGateEffectEventHandler::Trigger_StartMagnetizing(this);
	}

	UFUNCTION()
	private void StopMagnetizing()
	{
		UMagneticFieldGateEffectEventHandler::Trigger_StopMagnetizing(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bAutomaticOpenStarted)
		{
			DoorRoot.ApplyAngularForce(-10.0);
		}

		float CurrentYaw = DoorRoot.RelativeRotation.Yaw;
		float YawDif = Math::Abs(CurrentYaw - PreviousYaw);

		VelocityAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.5), FVector2D(0.0, 1.0), YawDif);

		PreviousYaw = CurrentYaw;

		if (Math::IsNearlyEqual(YawDif, 0.0))
		{
			if (bWasMoving)
			{
				UMagneticFieldGateEffectEventHandler::Trigger_StopMoving(this);
				bWasMoving = false;
			}
		}
		else
		{
			if (!bWasMoving)
			{
				UMagneticFieldGateEffectEventHandler::Trigger_StartMoving(this);
				bWasMoving = true;
			}
		}
	}
}