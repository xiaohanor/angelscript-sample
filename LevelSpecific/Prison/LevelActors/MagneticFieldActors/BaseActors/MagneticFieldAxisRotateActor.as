class AMagneticFieldAxisRotateActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(3.0);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	private bool bWasRotating = false;
	private bool bWasMagneticallyAffected = false;

	const float RotationSpeedThreshold = 0.01;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"OnMagneticAffected");
		MagneticFieldResponseComp.OnPush.AddUFunction(this, n"OnMagneticAffected");

		AxisRotateComp.OnMinConstraintHit.AddUFunction(this, n"OnConstraintHit");
		AxisRotateComp.OnMaxConstraintHit.AddUFunction(this, n"OnConstraintHit");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnMagneticAffected(FMagneticFieldData Data)
	{
		if(!IsActorTickEnabled())
		{
			SetActorTickEnabled(true);
			bWasRotating = IsRotating(RotationSpeedThreshold);
			bWasMagneticallyAffected = false;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnConstraintHit(float Strength)
	{
		FMagneticFieldAxisRotateImpactEventData EventData;
		EventData.Strength = Strength;
		UMagneticFieldAxisRotateEventHandler::Trigger_Impact(this, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const bool bIsRotating = IsRotating(RotationSpeedThreshold);

		if(bIsRotating && !bWasRotating)
		{
			UMagneticFieldAxisRotateEventHandler::Trigger_StartMoving(this);
		}

		const bool bIsMagneticallyAffected = MagneticFieldResponseComp.WasMagneticallyAffectedThisFrame();

		if(bIsMagneticallyAffected && !bWasMagneticallyAffected)
		{
			FMagneticFieldAxisRotateStartMagneticPushEventData EventData;
			EventData.bWasBurst = MagneticFieldResponseComp.WasBurstThisFrame();
			UMagneticFieldAxisRotateEventHandler::Trigger_StartMagneticPush(this, EventData);
		}
		else if(!bIsMagneticallyAffected && bWasMagneticallyAffected)
		{
			UMagneticFieldAxisRotateEventHandler::Trigger_StopMagneticPush(this);
		}

		if(AxisRotateComp.IsSleeping())
		{
			SetActorTickEnabled(false);

			if(bWasRotating)
			{
				UMagneticFieldAxisRotateEventHandler::Trigger_StopMoving(this);
				bWasRotating = false;
			}
		}
		else
		{
			if(!bIsRotating && bWasRotating)
			{
				UMagneticFieldAxisRotateEventHandler::Trigger_StopMoving(this);
			}

			bWasRotating = bIsRotating;
		}

		bWasMagneticallyAffected = bIsMagneticallyAffected;
	}

	UFUNCTION(BlueprintPure)
	bool IsRotating(float Threshold = 0.01) const
	{
		// If we are replicating, we are rotating
		if (AxisRotateComp.HasFauxPhysicsControl())
		{
			// If we have velocity, we are rotating
			if (!Math::IsNearlyZero(AxisRotateComp.Velocity, Threshold))
				return true;
			
			if(AxisRotateComp.bConstrain)
			{
				// If we have hit a constraint and are being pushed against it (and we don't have velocity), we have stopped
				float CurrentAngle = Math::RadiansToDegrees(AxisRotateComp.CurrentRotation);
				if(CurrentAngle > AxisRotateComp.ConstrainAngleMax - KINDA_SMALL_NUMBER && AxisRotateComp.PendingForces > KINDA_SMALL_NUMBER)
					return false;
				else if(CurrentAngle < AxisRotateComp.ConstrainAngleMin + KINDA_SMALL_NUMBER && AxisRotateComp.PendingForces < KINDA_SMALL_NUMBER)
					return false;
			}

			// Don't sleep if we can still spring back
			if (AxisRotateComp.SpringStrength > SMALL_NUMBER && Math::Abs(AxisRotateComp.CurrentRotation) > Threshold)
				return true;
		}
		else
		{
			if (!AxisRotateComp.SyncedRotation.IsSleeping())
				return true;
			if (!Math::IsNearlyEqual(AxisRotateComp.SyncedRotation.Value, AxisRotateComp.CurrentRotation, Threshold))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	float GetRotationSpeed() const
	{
		return Math::Abs(AxisRotateComp.Velocity);
	}
}