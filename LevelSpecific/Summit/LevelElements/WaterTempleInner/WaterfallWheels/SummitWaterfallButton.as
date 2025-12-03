event void ESummitWaterfallButtonEvent();

class ASummitWaterfallButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ButtonMesh;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitWaterfallButtonPressCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(USummitWaterfallButtonUnPressCapability);

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent SpotLight;
	default SpotLight.SetCastShadows(false);
	default SpotLight.OuterConeAngle = 30.0;
	default SpotLight.bUseInverseSquaredFalloff = false;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogComp;

	UPROPERTY(DefaultComponent, Attach = ButtonMesh)
	UPerchPointComponent PerchPointComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface EmissiveMat;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PressedOffset = 15.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveLerpDuration = 0.1;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartPressed = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UForceFeedbackEffect PressedRumble;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitWaterfallButton SiblingButton;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AHazeNiagaraActor WaterfallToActivate;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	ESummitWaterfallButtonEvent OnPressed;
	ESummitWaterfallButtonEvent OnUnPressed;

	bool bIsPressed = false;
	bool bIsActive = false;

	AHazePlayerCharacter PlayerOnButton;

	UMaterialInstanceDynamic DynamicMat;
	FLinearColor Color;
	float DefaultLightIntensity;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bStartPressed)
			ButtonMesh.RelativeLocation = RelativePressedLocation;
		else
			ButtonMesh.RelativeLocation = RelativeUnPressedLocation;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		
		if(HasControl())
		{
			PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerStartedPerching");
			PerchPointComp.OnPlayerInitiatedJumpToEvent.AddUFunction(this, n"OnPlayerInitiatedJumpToEvent");
			PerchPointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerchingEvent");

			if(bStartPressed)
				Press();
			else
				UnPress();
		}

		if(WaterfallToActivate != nullptr)
			WaterfallToActivate.NiagaraComponent0.DeactivateImmediately();

		DefaultLightIntensity = SpotLight.Intensity;
	}

	UFUNCTION()
	private void OnPlayerStartedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		PlayerOnButton = Player;
		if(!bIsPressed)
			Press();
	}

	UFUNCTION()
	private void OnPlayerInitiatedJumpToEvent(AHazePlayerCharacter Player,
	                                          UPerchPointComponent PerchPoint)
	{
		Player.ApplyCameraSettings(CameraSettings, 1.5, this);
		Player.ApplyPerchIdleBlocker(this);
	}

	UFUNCTION()
	private void OnPlayerStoppedPerchingEvent(AHazePlayerCharacter Player,
	                                          UPerchPointComponent PerchPoint)
	{
		Player.ClearCameraSettingsByInstigator(this, 2.5);
		Player.ClearPerchIdleBlocker(this);
	}

	FVector GetRelativePressedLocation() const property
	{
		return FVector::ZeroVector + FVector::DownVector * PressedOffset;
	}

	FVector GetRelativeUnPressedLocation() const property
	{
		return FVector::ZeroVector;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FBox LocalBounds = ButtonMesh.ComponentLocalBoundingBox;
		FVector BoxExtent = LocalBounds.Extent;
		FVector BoundsCenter = ButtonMesh.WorldTransform.TransformVector(LocalBounds.Center);

		if(bStartPressed)
		{
			FVector DrawLocation = ActorLocation + BoundsCenter;
			Debug::DrawDebugBox(DrawLocation, BoxExtent * ButtonMesh.WorldScale, ButtonMesh.WorldRotation, FLinearColor::Blue);
			Debug::DrawDebugString(DrawLocation, "UnPressed Location", FLinearColor::Blue);
		}
		else
		{
			FVector DrawLocation = ActorLocation + BoundsCenter + RelativePressedLocation;
			Debug::DrawDebugBox(DrawLocation, BoxExtent * ButtonMesh.WorldScale, ButtonMesh.WorldRotation, FLinearColor::Red);
			Debug::DrawDebugString(DrawLocation, "Pressed Location", FLinearColor::Red);
		}	
	}
#endif

	void Press()
	{
		bIsPressed = true;
		if(SiblingButton != nullptr)
		{
			SiblingButton.bIsPressed = false;
		}
	} 

	void UnPress()
	{
		bIsPressed = false;
	}

	UFUNCTION()
	void SetEmissiveMaterial(UStaticMeshComponent MeshComp, bool bIsOn)
	{
		if (DynamicMat == nullptr)
		{
			DynamicMat = MeshComp.CreateDynamicMaterialInstance(0);
			Color = DynamicMat.GetVectorParameterValue(n"Tint_D_Emissive");
		}

		if (bIsOn)
		{
			DynamicMat.SetVectorParameterValue(n"Tint_D_Emissive", Color * 15.0);
			SpotLight.SetIntensity(DefaultLightIntensity);
		}
		else
		{
			DynamicMat.SetVectorParameterValue(n"Tint_D_Emissive", Color * 0.05);
			SpotLight.SetIntensity(0.0);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_Press(){}

	UFUNCTION(BlueprintEvent)
	void BP_Unpress(){}
};