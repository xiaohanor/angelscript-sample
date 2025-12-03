class ATelescopeRobotGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent GateRoot;

	UPROPERTY(DefaultComponent, Attach = GateRoot)
	UStaticMeshComponent GateMesh;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldComp;

	UPROPERTY(BlueprintReadOnly)
	float VelocityAlpha = 0.0;

	UPROPERTY(EditAnywhere)
	bool bSwapConstraintEvents = false;

	float PreviousYaw = 0.0;

	bool bWasMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PreviousYaw = GateRoot.RelativeRotation.Yaw;

		GateRoot.OnMinConstraintHit.AddUFunction(this, n"FullyClosed");
		GateRoot.OnMaxConstraintHit.AddUFunction(this, n"FullyOpened");

		MagneticFieldComp.OnStartBeingMagneticallyAffected.AddUFunction(this, n"StartMagnetizing");
		MagneticFieldComp.OnStopBeingMagneticallyAffected.AddUFunction(this, n"StopMagnetizing");
	}



	UFUNCTION()
	private void StartMagnetizing()
	{
		UTelescopeRobotGateEffectEventHandler::Trigger_StartMagnetizing(this);
	}

	UFUNCTION()
	private void StopMagnetizing()
	{
		UTelescopeRobotGateEffectEventHandler::Trigger_StopMagnetizing(this);
	}

	UFUNCTION()
	private void FullyClosed(float Strength)
	{
		if (bSwapConstraintEvents)
			UTelescopeRobotGateEffectEventHandler::Trigger_FullyOpened(this);
		else
			UTelescopeRobotGateEffectEventHandler::Trigger_FullyClosed(this);
	}

	UFUNCTION()
	private void FullyOpened(float Strength)
	{
		if (bSwapConstraintEvents)
			UTelescopeRobotGateEffectEventHandler::Trigger_FullyClosed(this);
		else
			UTelescopeRobotGateEffectEventHandler::Trigger_FullyOpened(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurrentYaw = GateRoot.RelativeRotation.Yaw;
		float YawDif = Math::Abs(CurrentYaw - PreviousYaw);

		VelocityAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.5), FVector2D(0.0, 1.0), YawDif);

		PreviousYaw = CurrentYaw;

		if (Math::IsNearlyEqual(YawDif, 0.0))
		{
			if (bWasMoving)
			{
				UTelescopeRobotGateEffectEventHandler::Trigger_StopMoving(this);
				bWasMoving = false;
			}
		}
		else
		{
			if (!bWasMoving)
			{
				UTelescopeRobotGateEffectEventHandler::Trigger_StartMoving(this);
				bWasMoving = true;
			}
		}

		float SpringStrength = Math::GetMappedRangeValueClamped(FVector2D(0.0, 85.0), FVector2D(10.0, 0.15), Math::Abs(GateRoot.RelativeRotation.Yaw));
		GateRoot.SpringStrength = SpringStrength;
	}
}