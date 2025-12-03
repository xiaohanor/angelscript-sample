event void FOnBreak();

class AOilRigForceFieldSpinnerBattery : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent InteractionRoot;

	UPROPERTY(DefaultComponent, Attach = InteractionRoot)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BatteryBase;

	UPROPERTY(DefaultComponent, Attach = BatteryBase)
	USceneComponent BatteryRoot;

	UPROPERTY(DefaultComponent, Attach = BatteryRoot)
	USceneComponent ButtonMashAttachmentComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;
	default CapabilityRequestComp.PlayerCapabilities.Add(n"OilRigForceFieldSpinnerBatteryPlayerCapability");

	UPROPERTY(EditInstanceOnly)
	AOilRigForceFieldSpinner ForceField;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureForceFieldSpinnerBattery FeatureMio;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureForceFieldSpinnerBattery FeatureZoe;

	UPROPERTY()
	FOnBreak OnBreak;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter InteractingPlayer = nullptr;
	bool bBroken = false;

	float PullOutAlpha = 0.0;

	bool bResetting = false;

	bool bFullyIn = true;
	bool bFullyOut = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
	}

	UFUNCTION()
	private void InteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		UOilRigForceFieldSpinnerBatteryPlayerComponent Comp = UOilRigForceFieldSpinnerBatteryPlayerComponent::GetOrCreate(Player);
		Comp.Battery = this;

		InteractionComp.Disable(this);
	}

	void InteractionStopped()
	{
		InteractionComp.Enable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PullOutAlpha = Math::GetMappedRangeValueClamped(FVector2D(1.0, 50.0), FVector2D(0.0, 1.0), BatteryRoot.WorldLocation.Dist2D(BatteryBase.WorldLocation, FVector::UpVector));
		ForceField.RotationSpeed = Math::Lerp(ForceField.MaxSpeed, ForceField.MinSpeed, PullOutAlpha);

		if (bResetting)
		{
			float Offset = Math::FInterpConstantTo(BatteryRoot.RelativeLocation.X, 0.0, DeltaTime, 100.0);
			BatteryRoot.SetRelativeLocation(FVector(Offset, 0.0, 0.0));
			if (Math::IsNearlyEqual(Offset, 0.0))
			{
				bResetting = false;
			}
		}

		if (!bBroken)
		{
			if (PullOutAlpha == 1.0 && !bFullyOut)
			{
				bFullyOut = true;
				UOilRigForceFieldSpinnerBatteryEffectEventHandler::Trigger_FullyOut(this);
			}

			if (PullOutAlpha == 0.0 && !bFullyIn)
			{
				bFullyIn = true;
				UOilRigForceFieldSpinnerBatteryEffectEventHandler::Trigger_FullyIn(this);
			}

			if (bFullyOut && PullOutAlpha != 1.0)
			{
				bFullyOut = false;
				UOilRigForceFieldSpinnerBatteryEffectEventHandler::Trigger_StopPulling(this);
			}

			if (bFullyIn && PullOutAlpha != 0.0)
			{
				bFullyIn = false;
				UOilRigForceFieldSpinnerBatteryEffectEventHandler::Trigger_StartPulling(this);
			}
		}
	}

	UFUNCTION()
	void Break()
	{
		if (bBroken)
			return;
			
		bBroken = true;
		Timer::SetTimer(this, n"DelayedBreak", 0.3);
	}

	UFUNCTION()
	private void DelayedBreak()
	{
		InteractionComp.KickAnyPlayerOutOfInteraction();
		InteractionComp.Disable(ForceField);

		OnBreak.Broadcast();

		UOilRigForceFieldSpinnerBatteryEffectEventHandler::Trigger_Break(this);
	}

	void ReleaseBattery()
	{
		BatteryRoot.AttachToComponent(BatteryBase, NAME_None, EAttachmentRule::KeepWorld);

		bResetting = true;
	}
}

class UOilRigForceFieldSpinnerBatteryEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartPulling() {}
	UFUNCTION(BlueprintEvent)
	void StopPulling() {}
	UFUNCTION(BlueprintEvent)
	void FullyOut() {}
	UFUNCTION(BlueprintEvent)
	void FullyIn() {}
	UFUNCTION(BlueprintEvent)
	void Break() {}
}