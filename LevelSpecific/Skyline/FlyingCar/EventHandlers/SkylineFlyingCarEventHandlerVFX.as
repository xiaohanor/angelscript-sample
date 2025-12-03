	
class USkylineFlyingCarEventHandlerVFX : USkylineFlyingCarEventHandler
{
	UPROPERTY(Category = "EngineLight")
	const float HoverEngineLightMultiplier = 4.0;

	UPROPERTY(Category = "EngineLight")
	const float HoverEngineHueAccelerationDuration = 0.2;


	UPROPERTY(NotEditable, BlueprintReadOnly)
	FHazeAcceleratedFloat HoverEngineRightFraction;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FHazeAcceleratedFloat HoverEngineLeftFraction;


	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bRampBoost;


	UHazeCrumbSyncedFloatComponent CrumbedYawInput;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CrumbedYawInput = UHazeCrumbSyncedFloatComponent::GetOrCreate(Owner, n"EventHandlerVFXYawInput");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		if (HasControl())
			CrumbedYawInput.Value = FlyingCarOwner.YawInput;

		// Handle engine lighting juice
		const float DurationDecreaseMultiplier = 0.7;
		if (bRampBoost)
		{
			float LeftInput = CrumbedYawInput.Value > 0 ? Math::Abs(CrumbedYawInput.Value) * HoverEngineLightMultiplier : 0.0;
			HoverEngineLeftFraction.AccelerateTo(LeftInput + HoverEngineLightMultiplier * 0.5, HoverEngineHueAccelerationDuration, DeltaTime);

			float RightInput = CrumbedYawInput.Value < 0 ? Math::Abs(CrumbedYawInput.Value) * HoverEngineLightMultiplier : 0.0;
			HoverEngineRightFraction.AccelerateTo(RightInput + HoverEngineLightMultiplier * 0.5, HoverEngineHueAccelerationDuration, DeltaTime);
		}
		else if (Math::IsNearlyZero(CrumbedYawInput.Value, 0.05))
		{
			HoverEngineLeftFraction.AccelerateTo(0.0, HoverEngineHueAccelerationDuration * DurationDecreaseMultiplier, DeltaTime);
			HoverEngineRightFraction.AccelerateTo(0.0, HoverEngineHueAccelerationDuration * DurationDecreaseMultiplier, DeltaTime);
		}
		else if (CrumbedYawInput.Value > 0)
		{
			HoverEngineLeftFraction.AccelerateTo(Math::Abs(CrumbedYawInput.Value) * HoverEngineLightMultiplier, HoverEngineHueAccelerationDuration, DeltaTime);
			HoverEngineRightFraction.AccelerateTo(0.0, HoverEngineHueAccelerationDuration * DurationDecreaseMultiplier, DeltaTime);
		}
		else
		{
			HoverEngineRightFraction.AccelerateTo(Math::Abs(CrumbedYawInput.Value * HoverEngineLightMultiplier), HoverEngineHueAccelerationDuration, DeltaTime);
			HoverEngineLeftFraction.AccelerateTo(0.0, HoverEngineHueAccelerationDuration * DurationDecreaseMultiplier, DeltaTime);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDash()
	{
		Super::OnDash();

	}

	UFUNCTION(BlueprintOverride)
	void OnCollision(FSkylineFlyingCarCollision Collision)
	{
		Super::OnCollision(Collision);

	}

	UFUNCTION(BlueprintOverride)
	void OnTurretGunShot(FSkylineFlyingCarTurretGunshot TurretGunshot)
	{
		Super::OnTurretGunShot(TurretGunshot);

	}

	UFUNCTION(BlueprintOverride)
	void OnCloseToEdgeStart()
	{
		Super::OnCloseToEdgeStart();

	}

	UFUNCTION(BlueprintOverride)
	void OnCloseToEdgeEnd()
	{
		Super::OnCloseToEdgeEnd();

	}

	UFUNCTION(BlueprintOverride)
	void OnSplineHopStart()
	{
		Super::OnSplineHopStart();

	}

	UFUNCTION(BlueprintOverride)
	void OnSplineHopEnd()
	{
		Super::OnSplineHopEnd();

	}

	UFUNCTION(BlueprintOverride)
	void OnStartGroundedMovement()
	{
		Super::OnStartGroundedMovement();

	}

	UFUNCTION(BlueprintOverride)
	void OnStopGroundedMovement()
	{
		Super::OnStopGroundedMovement();

	}

	UFUNCTION(BlueprintOverride)
	void OnRampBoostStart()
	{
		Super::OnRampBoostStart();

		bRampBoost = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnRampBoostEnd()
	{
		Super::OnRampBoostEnd();

		bRampBoost = false;
	}
}