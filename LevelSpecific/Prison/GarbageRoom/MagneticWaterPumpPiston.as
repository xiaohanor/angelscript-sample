event void FMagneticWaterPumpPiston();

class AMagneticWaterPumpPiston : AMagneticFieldTranslateActor
{
	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USquishTriggerBoxComponent SquishBox;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USceneComponent ImpactPointComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 3000.0;

	UPROPERTY(BlueprintReadOnly)
	float VelocityAlpha = 0.0;

	UPROPERTY()
	FMagneticWaterPumpPiston OnBurstActivated;

	UPROPERTY()
	FMagneticWaterPumpPiston OnStartMagnetizing;

	UPROPERTY()
	FMagneticWaterPumpPiston OnStopMagnetizing;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> HitConstraintCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect HitConstraintFF;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FX_Splash;
	default FX_Splash.SetAutoActivate(false);

	bool bWasMoving = false;

	bool bBurstCooldownActive = false;
	bool bBurstSpamCounterForceActive = false;

	float VelocityThreshold = 150.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TranslateComp.OnConstraintHit.AddUFunction(this, n"ConstraintHit");

		MagneticFieldComp.OnBurst.AddUFunction(this, n"BurstActivated");

		MagneticFieldComp.OnStartBeingMagneticallyAffected.AddUFunction(this, n"StartMagnetizing");
		MagneticFieldComp.OnStopBeingMagneticallyAffected.AddUFunction(this, n"StopMagnetizing");
	}
	
	UFUNCTION()
	private void StartMagnetizing()
	{
		UMagneticWaterPumpPistonEffectEventHandler::Trigger_StartMagnetizing(this);
		OnStartMagnetizing.Broadcast();
	}

	UFUNCTION()
	private void StopMagnetizing()
	{
		UMagneticWaterPumpPistonEffectEventHandler::Trigger_StopMagnetizing(this);
		OnStopMagnetizing.Broadcast();
	}

	UFUNCTION()
	private void BurstActivated(FMagneticFieldData Data)
	{
		UMagneticWaterPumpPistonEffectEventHandler::Trigger_MagnetBurstActivated(this);
		OnBurstActivated.Broadcast();

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
	private void ConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Min)
			UMagneticWaterPumpPistonEffectEventHandler::Trigger_HitBottom(this);
		else if (Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Max)
			UMagneticWaterPumpPistonEffectEventHandler::Trigger_HitTop(this);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(HitConstraintCamShake, this, TranslateComp.WorldLocation, 600.0, 1000.0);

		ForceFeedback::PlayWorldForceFeedback(HitConstraintFF, TranslateComp.WorldLocation, true, this, 600.0, 400.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		VelocityAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1000.0), FVector2D(0.0, 1.0), Math::Abs(TranslateComp.GetVelocity().Z));

		if (TranslateComp.GetVelocity().IsNearlyZero(VelocityThreshold))
		{
			if (bWasMoving)
			{
				UMagneticWaterPumpPistonEffectEventHandler::Trigger_StopMoving(this);
				bWasMoving = false;
			}
		}
		else
		{
			if (!bWasMoving)
			{
				UMagneticWaterPumpPistonEffectEventHandler::Trigger_StartMoving(this);
				bWasMoving = true;
			}
		}

		if (MagneticFieldComp.WasMagneticallyAffectedThisFrame())
		{
			float WobbleModifier =  Math::Sin(Time::GameTimeSeconds * 5.0) * 50.0;
			TranslateComp.ApplyForce(TranslateComp.WorldLocation, FVector::UpVector * WobbleModifier);
		}
		else
		{
			float UpForce = bBurstSpamCounterForceActive ? 5000.0 : 1000.0;
			TranslateComp.ApplyForce(TranslateComp.WorldLocation, FVector::UpVector * UpForce);
		}
	}
}