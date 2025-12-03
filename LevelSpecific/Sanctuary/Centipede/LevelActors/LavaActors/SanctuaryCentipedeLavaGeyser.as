UCLASS(Abstract)
class USanctuaryLavaGeyserEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGeyser() {}
}

class ASanctuaryCentipedeLavaGeyser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GeyserRoot;

	UPROPERTY(DefaultComponent, Attach = GeyserRoot)
	UCapsuleComponent OverlapVolume;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent LightComp;

	UPROPERTY(Category = Settings, EditInstanceOnly)
	float IdleDuration = 2.0;

	UPROPERTY(Category = Settings, EditInstanceOnly)
	float StartDelay = 0.0;

	UPROPERTY(Category = Settings, EditInstanceOnly)
	float FireDuration = 4.0;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComponent;

	UPROPERTY()
	FRuntimeFloatCurve GeyserCurve;

	bool bIsManuallyApplyingLava = false;

	float SpotLightIntensity = 500.0;

	private float LastGeyserAlpha = 0;

	// Drive audio parameters
	UFUNCTION(BlueprintPure)
	float GetLastGeyserAlpha()
	{
		return LastGeyserAlpha;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActionQueueComponent.SetLooping(true);
		ActionQueueComponent.Duration(FireDuration, this, n"GeyserUpdate");
		ActionQueueComponent.Idle(IdleDuration);
		ActionQueueComponent.Event(this, n"StartGeyser");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActionQueueComponent.ScrubTo(Time::PredictedGlobalCrumbTrailTime - StartDelay);
	}

	UFUNCTION()
	private void StartGeyser()
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		USanctuaryLavaGeyserEventHandler::Trigger_OnStartGeyser(this);
		BP_StartGeyser();
	}

	UFUNCTION()
	void GeyserUpdate(float Alpha)
	{
		float GeyserAlpha = GeyserCurve.GetFloatValue(Alpha);
		GeyserRoot.SetRelativeLocation(FVector::UpVector * 2700.0 * GeyserAlpha);
		bIsManuallyApplyingLava = LavaComp.OverlapSingleFrame(OverlapVolume.WorldLocation, OverlapVolume.CapsuleRadius, true);
		LastGeyserAlpha = GeyserAlpha;

		LightComp.SetIntensity(Math::EaseOut(0.0, SpotLightIntensity, GeyserAlpha, 2.0));
	}

	UFUNCTION(BlueprintEvent)
	private void BP_StartGeyser(){}
};