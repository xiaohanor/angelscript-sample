class AMagneticFieldTrashPile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent PileRoot;

	UPROPERTY(DefaultComponent, Attach = PileRoot)
	UStaticMeshComponent PileMesh;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 3500.0;

	UPROPERTY(BlueprintReadOnly)
	float VelocityAlpha = 0.0;

	float PreviousYaw = 0.0;

	bool bWasMoving = false;

	bool bBurstCooldownActive = false;
	bool bBurstSpamCounterForceActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		PreviousYaw = PileRoot.RelativeRotation.Yaw;

		PileRoot.OnMinConstraintHit.AddUFunction(this, n"FullyOpened");
		PileRoot.OnMaxConstraintHit.AddUFunction(this, n"Closed");

		MagneticFieldComp.OnStartBeingMagneticallyAffected.AddUFunction(this, n"StartMagnetizing");
		MagneticFieldComp.OnStopBeingMagneticallyAffected.AddUFunction(this, n"StopMagnetizing");

		MagneticFieldComp.OnBurst.AddUFunction(this, n"MagnetBurst");
	}

	UFUNCTION()
	private void MagnetBurst(FMagneticFieldData Data)
	{
		if (bBurstCooldownActive)
			bBurstSpamCounterForceActive = true;

		bBurstCooldownActive = true;

		Timer::SetTimer(this, n"ResetBurstCooldown", 2.0);
	}

	UFUNCTION()
	private void ResetBurstCooldown()
	{
		bBurstCooldownActive = false;
		bBurstSpamCounterForceActive = false;
	}

	UFUNCTION()
	private void StartMagnetizing()
	{
		UMagneticFieldTrashPileEffectEventHandler::Trigger_StartMagnetizing(this);
	}

	UFUNCTION()
	private void StopMagnetizing()
	{
		UMagneticFieldTrashPileEffectEventHandler::Trigger_StopMagnetizing(this);
	}

	UFUNCTION()
	private void Closed(float Strength)
	{
		UMagneticFieldTrashPileEffectEventHandler::Trigger_Closed(this);
	}

	UFUNCTION()
	private void FullyOpened(float Strength)
	{
		UMagneticFieldTrashPileEffectEventHandler::Trigger_FullyOpened(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurrentYaw = PileRoot.RelativeRotation.Yaw;
		float YawDif = Math::Abs(CurrentYaw - PreviousYaw);

		VelocityAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.5), FVector2D(0.0, 1.0), YawDif);

		PreviousYaw = CurrentYaw;

		if (Math::IsNearlyEqual(YawDif, 0.0))
		{
			if (bWasMoving)
			{
				UMagneticFieldTrashPileEffectEventHandler::Trigger_StopMoving(this);
				bWasMoving = false;
			}
		}
		else
		{
			if (!bWasMoving)
			{
				UMagneticFieldTrashPileEffectEventHandler::Trigger_StartMoving(this);
				bWasMoving = true;
			}
		}

		if (bBurstSpamCounterForceActive)
			PileRoot.ApplyAngularForce(-5.0);

		if (!MagneticFieldComp.WasMagneticallyAffectedThisFrame())
			PileRoot.ApplyAngularForce(-2.0);
	}
}