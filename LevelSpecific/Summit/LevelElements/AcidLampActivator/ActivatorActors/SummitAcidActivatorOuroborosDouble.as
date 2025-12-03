class ASummitAcidActivatorOuroborosDouble : ASummitAcidActivatorActor
{
	float TargetRotation;
	float RotationDifference;
	float CurrentRotation;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USummitAcidActivatorAttachComponent Attach1;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USummitAcidActivatorAttachComponent Attach2;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USpotLightComponent SpotLight1;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USpotLightComponent SpotLight2;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY()
	FRuntimeFloatCurve Curve;
	default Curve.AddDefaultKey(0.0, 0.25);
	default Curve.AddDefaultKey(0.5, 1.0);
	default Curve.AddDefaultKey(1.0, 0.25);

	UPROPERTY(EditAnywhere)
	float MaxRotateSpeed = 100.0;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedPitch;
	default SyncedPitch.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	bool bActionCompleted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SyncedPitch.SetValue(MeshRoot.RelativeRotation.Pitch);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			if (TargetRotation == 0.0)
				return;

			float CurveAlpha = 1 - ((TargetRotation - CurrentRotation) / RotationDifference);	
			float Speed = MaxRotateSpeed * Curve.GetFloatValue(CurveAlpha);
			CurrentRotation = Math::FInterpConstantTo(CurrentRotation, TargetRotation, DeltaSeconds, Speed);
			MeshRoot.RelativeRotation = FRotator(CurrentRotation, 0, 0);

			if (TargetRotation - CurrentRotation < 0.05 && !bActionCompleted)
			{
				bActionCompleted = true;
				CrumbFireCompletedAction();
			}

			SyncedPitch.SetValue(CurrentRotation);
		}
		else
		{
			MeshRoot.RelativeRotation = FRotator(SyncedPitch.Value, 0.0, 0.0); 
		}
	}

	void OnAcidActivatorStarted(AAcidActivator Activator) override
	{
		Super::OnAcidActivatorStarted(Activator);
		if(HasControl())
			SetRotationValues(TargetRotation + 180);
	}

	private void SetRotationValues(float NewTargetRotation)
	{
		TargetRotation = NewTargetRotation;
		RotationDifference = TargetRotation - CurrentRotation;
		bActionCompleted = false;
	}

	UFUNCTION(BlueprintPure)
	float GetRotateAlpha() const
	{
		if(RotationDifference == 0)
			return 0;

		if(HasControl())
			return ((TargetRotation - CurrentRotation) / RotationDifference);
		else
			return ((TargetRotation - SyncedPitch.Value) / RotationDifference);
	}
};