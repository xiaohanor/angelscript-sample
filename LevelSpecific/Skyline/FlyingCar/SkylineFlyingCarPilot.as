


struct FSkylineFlyingCarPilotCameraSettings
{
	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY()
	float CameraSettingsActivationBlend;

	UPROPERTY()
	USkylineFylingCarPilotCameraComposableSettings SplineSettings;

	int InternalId = -1;
}

struct FSkylineFlyingCarPilotCameraInternalData
{
	USkylineFylingCarPilotCameraComposableSettings PreviousCameraSettings;
	float ActiveAlpha = 1.0;
	float AlphaIncreaseSpeed = 1.0;


	private float InternalLookAheadAlpha = 0.0;
	private float InternalTargetLookAtLocationLookAheadDistance = 0.0;
	private float InternalTargetPitchOffset = 0.0;
	private float InternalForceCameraLookDirectionSpeed = 0.0;
	private float InternalHorizontalFollowCarPercentage = 0.0;
	private float InternalVerticalFollowCarPercentage = 0.0;

	void Init(USkylineFylingCarPilotCameraComposableSettings CurrentSettings)
	{
		PreviousCameraSettings = CurrentSettings;
		ActiveAlpha = 1.0;
		AlphaIncreaseSpeed = 0.0;
		//Update(0, CurrentSettings);
	}

	void Update(float DeltaTime, USkylineFylingCarPilotCameraComposableSettings CurrentSettings)
	{
		ActiveAlpha = Math::FInterpConstantTo(ActiveAlpha, 1.0, DeltaTime, AlphaIncreaseSpeed);

		// Update internals from the new alpha
		InternalLookAheadAlpha = Math::Lerp(PreviousCameraSettings.LookAheadAlpha, CurrentSettings.LookAheadAlpha, ActiveAlpha);
		InternalTargetLookAtLocationLookAheadDistance = Math::Lerp(PreviousCameraSettings.TargetLookAtLocationLookAheadDistance, CurrentSettings.TargetLookAtLocationLookAheadDistance, ActiveAlpha); 
		InternalTargetPitchOffset = Math::Lerp(PreviousCameraSettings.TargetPitchOffset, CurrentSettings.TargetPitchOffset, ActiveAlpha); 
		InternalForceCameraLookDirectionSpeed = Math::Lerp(PreviousCameraSettings.ForceCameraLookDirectionSpeed, CurrentSettings.ForceCameraLookDirectionSpeed, ActiveAlpha); 
		InternalHorizontalFollowCarPercentage = Math::Lerp(PreviousCameraSettings.HorizontalFollowCarPercentage, CurrentSettings.HorizontalFollowCarPercentage, ActiveAlpha); 
		InternalVerticalFollowCarPercentage = Math::Lerp(PreviousCameraSettings.VerticalFollowCarPercentage, CurrentSettings.VerticalFollowCarPercentage, ActiveAlpha); 
	}

	float GetLookAheadAlpha() const property
	{
		return InternalLookAheadAlpha;
	}

	float GetTargetLookAtLocationLookAheadDistance() const property
	{
		return InternalTargetLookAtLocationLookAheadDistance;
	}

	float GetTargetPitchOffset() const property
	{
		return InternalTargetPitchOffset;
	}

	float GetForceCameraLookDirectionSpeed() const property
	{
		return InternalForceCameraLookDirectionSpeed;
	}

	float GetHorizontalFollowCarPercentage() const property
	{
		return InternalHorizontalFollowCarPercentage;
	}

	float GetVerticalFollowCarPercentage() const property
	{
		return InternalVerticalFollowCarPercentage;
	}

	float GetFollowCarPercentageModifierFromSplineCenter(float Alpha, USkylineFylingCarPilotCameraComposableSettings CurrentSettings) const
	{
		const float PrevValue = PreviousCameraSettings.FollowCarPercentageModifierFromSplineCenter.GetFloatValue(Alpha, 1.0);
		const float CurrenValue = CurrentSettings.FollowCarPercentageModifierFromSplineCenter.GetFloatValue(Alpha, 1.0);
		return  Math::Lerp(PrevValue, CurrenValue, ActiveAlpha); 
	}
}

UCLASS(Abstract)
class USkylineFlyingCarPilotComponent : UActorComponent
{
#if EDITOR
	bool bSteeringOverridenByGunner;
#endif

	UPROPERTY()
	FSkylineFlyingCarPilotCameraSettings SplineFollowCamera;
	default SplineFollowCamera.InternalId = 0;
	
	UPROPERTY()
	FSkylineFlyingCarPilotCameraSettings FreeFlyCamera;
	default FreeFlyCamera.InternalId = 1;

	UPROPERTY()
	FSkylineFlyingCarPilotCameraSettings SplineTunnelCamera;
	default SplineTunnelCamera.InternalId = 2;

	UPROPERTY()
	FSkylineFlyingCarPilotCameraSettings SplineRampCamera;
	default SplineRampCamera.InternalId = 3;

	TInstigated<USkylineFylingCarPilotCameraComposableSettings> SplineFollowCameraSettings;
	FSkylineFlyingCarPilotCameraInternalData SplineFollowCameraSettingsData;

	TInstigated<USkylineFylingCarPilotCameraComposableSettings> FreeFlyCameraSettings;
	FSkylineFlyingCarPilotCameraInternalData FreeFlyCameraSettingsData;

	TInstigated<USkylineFylingCarPilotCameraComposableSettings> SplineTunnelCameraSettings;
	FSkylineFlyingCarPilotCameraInternalData SplineTunnelCameraSettingsSettingsData;

	TInstigated<USkylineFylingCarPilotCameraComposableSettings> SplineRampCameraSettings;
	FSkylineFlyingCarPilotCameraInternalData SplineRampCameraSettingsData;

	float FreeFlyPercentage = 0.0;
	float TunnelPercentage = 0.0;
	float RampPercentage = 0.0;

	const float BlendInSpeed = 2.0;
	const float HighwayTransitionDuration = 1.0;

	ASkylineFlyingCar Car;

	access GroundMovement = private, ASkylineFlyingCarGroundMovementTrigger, USkylineFlyingCarGotyGroundMovementCapability;
	access : GroundMovement
	bool bInsideGroundMovementZone;

	access : GroundMovement
	bool bWasGroundMoving;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineFollowCameraSettings.DefaultValue = SplineFollowCamera.SplineSettings; 
		SplineFollowCameraSettingsData.Init(SplineFollowCameraSettings.Get());

		FreeFlyCameraSettings.DefaultValue = FreeFlyCamera.SplineSettings;
		FreeFlyCameraSettingsData.Init(FreeFlyCameraSettings.Get());

		SplineTunnelCameraSettings.DefaultValue = SplineTunnelCamera.SplineSettings;
		SplineTunnelCameraSettingsSettingsData.Init(SplineTunnelCameraSettings.Get());

		SplineRampCameraSettings.DefaultValue = SplineRampCamera.SplineSettings;
		SplineRampCameraSettingsData.Init(SplineRampCameraSettings.Get());
	}

	void UpdateSettingsAlphas(float DeltaTime)
	{
		SplineFollowCameraSettingsData.Update(DeltaTime, SplineFollowCameraSettings.Get());
		FreeFlyCameraSettingsData.Update(DeltaTime, FreeFlyCameraSettings.Get());
		SplineTunnelCameraSettingsSettingsData.Update(DeltaTime, SplineTunnelCameraSettings.Get());

		SplineRampCameraSettingsData.ActiveAlpha = Math::Square(RampPercentage);
		SplineRampCameraSettingsData.Update(DeltaTime, SplineRampCameraSettings.Get());
	}

	void GetFlyingCarCameraSettings(UHazeCameraSettingsDataAsset& OutCameraSettings, float& OutCameraSettingsActivationBlend) const
	{
		if (Car.IsInSplineRamp() || Car.IsJumpingFromSplineRamp())
		{
			OutCameraSettings = SplineRampCamera.CameraSettings;
			OutCameraSettingsActivationBlend = SplineRampCamera.CameraSettingsActivationBlend;
		}
		else if (Car.IsFreeFlying() || Car.IsAnyCapabilityActive(FlyingCarTags::FlyingCarGroundMovement))
		{
			OutCameraSettings = FreeFlyCamera.CameraSettings;
			OutCameraSettingsActivationBlend = FreeFlyCamera.CameraSettingsActivationBlend;
		}
		else if (IsInTunnel())
		{
			OutCameraSettings = SplineTunnelCamera.CameraSettings;
			OutCameraSettingsActivationBlend = SplineTunnelCamera.CameraSettingsActivationBlend;
		}
		else
		{
			OutCameraSettings = SplineFollowCamera.CameraSettings;
			OutCameraSettingsActivationBlend = SplineFollowCamera.CameraSettingsActivationBlend;
		}
	}

	float GetLookAheadAlpha() const property
	{
		float Value = SplineFollowCameraSettingsData.LookAheadAlpha;
		Value = Math::Lerp(Value, FreeFlyCameraSettingsData.LookAheadAlpha, FreeFlyPercentage); 
		Value = Math::Lerp(Value, SplineTunnelCameraSettingsSettingsData.LookAheadAlpha, TunnelPercentage);
		Value = Math::Lerp(Value, SplineRampCameraSettingsData.LookAheadAlpha, RampPercentage);
		return Value;
	}

	float GetTargetLookAtLocationLookAheadDistance() const property
	{	
		float Value = SplineFollowCameraSettingsData.TargetLookAtLocationLookAheadDistance;
		Value = Math::Lerp(Value, FreeFlyCameraSettingsData.TargetLookAtLocationLookAheadDistance, FreeFlyPercentage); 
		Value = Math::Lerp(Value, SplineTunnelCameraSettingsSettingsData.TargetLookAtLocationLookAheadDistance, TunnelPercentage);
		Value = Math::Lerp(Value, SplineRampCameraSettingsData.TargetLookAtLocationLookAheadDistance, RampPercentage);
		return Value;
	}

	float GetTargetPitchOffset() const property
	{
		float Value = SplineFollowCameraSettingsData.TargetPitchOffset;
		Value = Math::Lerp(Value, FreeFlyCameraSettingsData.TargetPitchOffset, FreeFlyPercentage); 
		Value = Math::Lerp(Value, SplineTunnelCameraSettingsSettingsData.TargetPitchOffset, TunnelPercentage);
		Value = Math::Lerp(Value, SplineRampCameraSettingsData.TargetPitchOffset, RampPercentage);
		return Value;
	}

	float GetForceCameraLookDirectionSpeed() const property
	{
		float Value = SplineFollowCameraSettingsData.ForceCameraLookDirectionSpeed;
		Value = Math::Lerp(Value, FreeFlyCameraSettingsData.ForceCameraLookDirectionSpeed, FreeFlyPercentage); 
		Value = Math::Lerp(Value, SplineTunnelCameraSettingsSettingsData.ForceCameraLookDirectionSpeed, TunnelPercentage);
		Value = Math::Lerp(Value, SplineRampCameraSettingsData.ForceCameraLookDirectionSpeed, RampPercentage);
		return Value;
	}

	float GetHorizontalFollowCarPercentage() const property
	{
		float Value = SplineFollowCameraSettingsData.HorizontalFollowCarPercentage;
		Value = Math::Lerp(Value, FreeFlyCameraSettingsData.HorizontalFollowCarPercentage, FreeFlyPercentage); 
		Value = Math::Lerp(Value, SplineTunnelCameraSettingsSettingsData.HorizontalFollowCarPercentage, TunnelPercentage);
		Value = Math::Lerp(Value, SplineRampCameraSettingsData.HorizontalFollowCarPercentage, RampPercentage);
		return Value;
	}

	float GetVerticalFollowCarPercentage() const property
	{
		float Value = SplineFollowCameraSettingsData.VerticalFollowCarPercentage;
		Value = Math::Lerp(Value, FreeFlyCameraSettingsData.VerticalFollowCarPercentage, FreeFlyPercentage); 
		Value = Math::Lerp(Value, SplineTunnelCameraSettingsSettingsData.VerticalFollowCarPercentage, TunnelPercentage);
		Value = Math::Lerp(Value, SplineRampCameraSettingsData.VerticalFollowCarPercentage, RampPercentage);
		return Value;
	}

	float GetFollowCarPercentageModifierFromSplineCenter(float Alpha) const
	{
		USkylineFylingCarPilotCameraComposableSettings SplineFollow = SplineFollowCameraSettings.Get();
		USkylineFylingCarPilotCameraComposableSettings FreeFly = FreeFlyCameraSettings.Get();
		USkylineFylingCarPilotCameraComposableSettings Tunnel = SplineTunnelCameraSettings.Get();
		USkylineFylingCarPilotCameraComposableSettings Ramp = SplineRampCameraSettings.Get();

		float Value = SplineFollowCameraSettingsData.GetFollowCarPercentageModifierFromSplineCenter(Alpha, SplineFollow);
		Value = Math::Lerp(Value, FreeFlyCameraSettingsData.GetFollowCarPercentageModifierFromSplineCenter(Alpha, FreeFly), FreeFlyPercentage); 
		Value = Math::Lerp(Value, SplineTunnelCameraSettingsSettingsData.GetFollowCarPercentageModifierFromSplineCenter(Alpha, Tunnel), TunnelPercentage);
		Value = Math::Lerp(Value, SplineRampCameraSettingsData.GetFollowCarPercentageModifierFromSplineCenter(Alpha, Ramp), RampPercentage);
		return Value;
	}

	UFUNCTION()
	bool IsInsideGroundMovementZone()
	{
		return bInsideGroundMovementZone;
	}

	bool GetAndConsumeWasGroundMoving()
	{
		if (bWasGroundMoving)
		{
			bWasGroundMoving = false;
			return true;
		}

		return false;
	}

	bool IsInTunnel() const
	{
		if (Car == nullptr)
			return false;

		if (Car.ActiveHighway == nullptr)
			return false;

		if (Car.ActiveHighway.MovementConstraintType != ESkylineFlyingHighwayMovementConstraint::Tunnel)
			return false;

		return true;
	}
}

UFUNCTION(BlueprintPure)
ASkylineFlyingCar GetSkylineFlyingCar()
{
	USkylineFlyingCarPilotComponent PilotComp = USkylineFlyingCarPilotComponent::Get(Game::Zoe);
	if(PilotComp == nullptr)
		return nullptr;
	
	return PilotComp.Car;
}