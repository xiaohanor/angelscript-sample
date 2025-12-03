class AIslandSidescrollerTimedOneWayPlatform : AIslandSidescrollerOneWayPlatform
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LeftProjectorMesh;
	default LeftProjectorMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent RightProjectorMesh;
	default RightProjectorMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ForceFieldMesh;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementCallbackComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlatformLength = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DisappearingDuration = 2.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GrowBackDuration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Force Field")
	UMaterialInterface SourceMaterial;

	UPROPERTY(EditAnywhere, Category = "Force Field")
	UMaterialInterface ProjectorActiveMaterial;

	UPROPERTY(EditAnywhere, Category = "Force Field")
	FLinearColor ForceFieldColor;

	UPROPERTY(EditAnywhere, Category = "Force Field")
	float DistortionIntensity = 0.05;

	UPROPERTY(EditAnywhere, Category = "Force Field")
	float EmissiveIntensity = 1.0;

	UPROPERTY(EditAnywhere, Category = "Force Field")
	float OpacityIntensity = 0.75;

	UPROPERTY(EditAnywhere, Category = "Force Field")
	FRuntimeFloatCurve DisappearingEmissiveIntensityCurve;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UMaterialInstanceDynamic ForceFieldMaterial;
	float TimeLastImpactedPlatform;
	float TimeLastDisappeared;
	float CurrentEmissiveIntensity;
	float CurrentOpacityIntensity;

	const float InitialLandFlickerDuration = 0.2;
	const float InitialLandFlickerAdditionalIntensity = 20.5;
	const float LandFlickerAdditionalIntensity = 15.5;
	const float MaxFlickerFrequency = 10.0;
	const float ThresholdForOpacityDisappear = 0.25;
	const float AlphaThresholdForPlatformCollisionTurnOff = 0.1;
	const float AlphaThresholdForPlatformCollisionTurnOn = 0.1;
	const float AlphaThresholdForGrowingBackOpacity = 0.7;

	bool bIsDisappearing = false;
	bool bIsGrowingBack = false;
	bool bIsVisible = true;
	bool bHasCollision = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		LeftProjectorMesh.WorldLocation = ActorLocation - ActorForwardVector * PlatformLength * 0.5;
		RightProjectorMesh.WorldLocation = ActorLocation + ActorForwardVector * PlatformLength * 0.5;
		FVector ForceFieldScale = ForceFieldMesh.WorldScale;
		ForceFieldScale.X = PlatformLength * 0.01;
		ForceFieldMesh.WorldScale3D = ForceFieldScale;

		Collision.BoxExtent = FVector(PlatformLength * 0.5, ForceFieldScale.Y * 50, 5);

		ForceFieldMaterial = ForceFieldMesh.CreateDynamicMaterialInstance(0, SourceMaterial);
		ForceFieldMaterial.SetVectorParameterValue(n"EmissiveColor", ForceFieldColor);
		ForceFieldMaterial.SetScalarParameterValue(n"DistortionIntensity", DistortionIntensity);
		ForceFieldMaterial.SetScalarParameterValue(n"EmissiveIntensity", EmissiveIntensity);
		ForceFieldMaterial.SetScalarParameterValue(n"OpacityIntensity", OpacityIntensity);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ForceFieldMaterial = ForceFieldMesh.CreateDynamicMaterialInstance(0, SourceMaterial);
		ForceFieldMaterial.SetVectorParameterValue(n"EmissiveColor", ForceFieldColor);
		ForceFieldMaterial.SetScalarParameterValue(n"DistortionIntensity", DistortionIntensity);
		ForceFieldMaterial.SetScalarParameterValue(n"EmissiveIntensity", EmissiveIntensity);
		ForceFieldMaterial.SetScalarParameterValue(n"OpacityIntensity", OpacityIntensity);

		CurrentEmissiveIntensity = EmissiveIntensity;
		CurrentOpacityIntensity = OpacityIntensity;
		MovementCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"StartPlatformTimer");
	}

	UFUNCTION(NotBlueprintCallable)
	private void StartPlatformTimer(AHazePlayerCharacter Player)
	{
		if(bIsDisappearing)
			return;

		TimeLastImpactedPlatform = Time::GameTimeSeconds;
		bIsDisappearing = true;

		Player.PlayForceFeedback(ForceFeedback, false, false, this);


		UIslandSidescrollerTimedOneWayPlatformEffectHandler::Trigger_OnPlayerLanded(this);
		BP_OnPlayerLanded();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Debug::DrawDebugString(ActorCenterLocation, f"{bHasCollision=}", bHasCollision ? FLinearColor::Green : FLinearColor::Red);
		if(bIsDisappearing)
			HandleDisappearingFlicker();
		if(bIsGrowingBack)
			HandleGrowBack();
	}

	void HandleDisappearingFlicker()
	{
		float TimeSinceImpact = Time::GetGameTimeSince(TimeLastImpactedPlatform);
		if(TimeSinceImpact > DisappearingDuration)
		{
			TogglePlatformVisuals(false);
			bIsDisappearing = false;
			TimeLastDisappeared = Time::GameTimeSeconds;
			bIsGrowingBack = true;
			ForceFieldMaterial.SetScalarParameterValue(n"EmissiveIntensity", EmissiveIntensity);
			UIslandSidescrollerTimedOneWayPlatformEffectHandler::Trigger_OnPlatformDisappear(this);
			BP_OnPlatformDisappear();

			if(bHasCollision)
				TogglePlatformCollision(false);
			return;
		}

		float AdditionalFlicker = 0.0;
		if(TimeSinceImpact < InitialLandFlickerDuration)
		{
			float Time = (TimeSinceImpact * PI) / InitialLandFlickerDuration;
			float Wave = Math::Sin(Time);
			AdditionalFlicker += Wave * InitialLandFlickerAdditionalIntensity;
		}
		float DisappearingAlpha = Math::GetPercentageBetweenClamped(DisappearingDuration, 0, TimeSinceImpact);
		float Time = TimeSinceImpact * MaxFlickerFrequency * (1 - DisappearingAlpha);
		float Wave = (Math::Sin(Time) + 1) * 0.5;
		AdditionalFlicker += Wave * LandFlickerAdditionalIntensity;

		if(DisappearingAlpha <= ThresholdForOpacityDisappear)
		{
			float OpacityDisappearAlpha = Math::GetPercentageBetweenClamped(0.0, ThresholdForOpacityDisappear, DisappearingAlpha);
			CurrentOpacityIntensity = OpacityIntensity * OpacityDisappearAlpha;
			ForceFieldMaterial.SetScalarParameterValue(n"OpacityIntensity", CurrentOpacityIntensity);	

			if(OpacityDisappearAlpha <= AlphaThresholdForPlatformCollisionTurnOff)
				TogglePlatformCollision(false);
		}
		CurrentEmissiveIntensity = EmissiveIntensity + AdditionalFlicker;
		ForceFieldMaterial.SetScalarParameterValue(n"EmissiveIntensity", CurrentEmissiveIntensity);
	}

	void HandleGrowBack()
	{
		float TimeSinceDisappeared = Time::GetGameTimeSince(TimeLastDisappeared);
		float GrowBackAlpha = Math::GetPercentageBetweenClamped(0, GrowBackDuration, TimeSinceDisappeared);
		float OpacityDisappearAlpha = Math::GetPercentageBetweenClamped(AlphaThresholdForGrowingBackOpacity, 1.0, GrowBackAlpha);
		if(GrowBackAlpha >= AlphaThresholdForGrowingBackOpacity)
		{
			TogglePlatformVisuals(true);
			CurrentOpacityIntensity = OpacityIntensity * OpacityDisappearAlpha;
			ForceFieldMaterial.SetScalarParameterValue(n"OpacityIntensity", CurrentOpacityIntensity);
			UIslandSidescrollerTimedOneWayPlatformEffectHandler::Trigger_OnPlatformAppear(this);	
			if(OpacityDisappearAlpha > AlphaThresholdForPlatformCollisionTurnOff)
				TogglePlatformCollision(true);
		}
		
		if(TimeSinceDisappeared > GrowBackDuration)
		{
			bIsGrowingBack = false;
			ForceFieldMaterial.SetScalarParameterValue(n"OpacityIntensity", OpacityIntensity);

			if(!bHasCollision)
				TogglePlatformCollision(true);
		}
	}


	void TogglePlatformCollision(bool bToggleOn)
	{
		if(bToggleOn)
		{
			if(bHasCollision)
				return;

			Collision.RemoveComponentCollisionBlocker(this);

			for(auto Player : Game::Players)
			{
				UIslandSidescrollerComponent::GetOrCreate(Player).OneWayPlatforms.Add(this);
			}
			bHasCollision = true;
		}
		else
		{
			if(!bHasCollision)
				return;

			Collision.AddComponentCollisionBlocker(this);

			for(auto Player : Game::Players)
			{
				UIslandSidescrollerComponent::GetOrCreate(Player).OneWayPlatforms.RemoveSingleSwap(this);
				Player.PlayForceFeedback(ForceFeedback, false, false, this);
			}
			bHasCollision = false;
		}
	}

	void TogglePlatformVisuals(bool bToggleOn)
	{
		if(bToggleOn)
		{
			if(bIsVisible)
				return;
			ForceFieldMesh.RemoveComponentVisualsBlocker(this);
			bIsVisible = true;
		}
		else
		{
			if(!bIsVisible)
				return;

			ForceFieldMesh.AddComponentVisualsBlocker(this);
			bIsVisible = false;		
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnPlayerLanded(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnPlatformDisappear(){}

};

UCLASS(Abstract)
class UIslandSidescrollerTimedOneWayPlatformEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerLanded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformDisappear() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformAppear() {}

};