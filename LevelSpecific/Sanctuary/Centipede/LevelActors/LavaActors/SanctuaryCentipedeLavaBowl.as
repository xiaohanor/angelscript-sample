UCLASS(Abstract)
class USanctuaryCentipedeLavaBowlEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartPouring() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopPouring() {}
}

class ASanctuaryCentipedeLavaBowl : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LavaRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BowlLavaRoot;

	UPROPERTY(DefaultComponent, Attach = LavaRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent LightComp;

	UPROPERTY(DefaultComponent, Attach = LavaRoot)
	UBoxComponent TriggerComp;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueFallingLava;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueBowlLava;

	UPROPERTY()
	FRuntimeFloatCurve BowlCurve;

	UPROPERTY(EditInstanceOnly)
	float Offset = 0.0;

	float XYScale = 0.2;
	float ZScale = 0.0;

	bool bFalling = false;
	float FallSpeed = 0.0;

	float SpotLightIntensity = 500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActionQueueFallingLava.SetLooping(true);
		ActionQueueFallingLava.Event(this, n"StartPouring");
		ActionQueueFallingLava.Duration(3.0, this, n"UpdateStartPouring");
		ActionQueueFallingLava.Event(this, n"StopPouring");
		ActionQueueFallingLava.Duration(2.0, this, n"UpdateStopPouring");
		ActionQueueFallingLava.Idle(2.0);

		ActionQueueBowlLava.SetLooping(true);
		ActionQueueBowlLava.Duration(7.0, this, n"UpdateBowlLava");
		//ActionQueueBowlLava.ScrubTo(1.5);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActionQueueFallingLava.ScrubTo(Time::PredictedGlobalCrumbTrailTime - Offset);
		ActionQueueBowlLava.ScrubTo(Time::PredictedGlobalCrumbTrailTime - 3.0 - Offset);

		if (!bFalling)
			return;

		FallSpeed += -1500.0 * DeltaSeconds;
		LavaRoot.AddRelativeLocation(FVector::UpVector * FallSpeed * DeltaSeconds);
	}

	UFUNCTION()
	private void StartPouring()
	{
		bFalling = false;
		FallSpeed = 0.0;
		LavaRoot.SetRelativeLocation(FVector(0.0));
		USanctuaryCentipedeLavaBowlEventHandler::Trigger_OnStartPouring(this);
		BP_StartPouring();
	}

	UFUNCTION()
	private void UpdateStartPouring(float Alpha)
	{
		float FallValue = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha);
		float ScaleValue = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha);

		ZScale = Math::Lerp(0.0, 1.0, FallValue);
		XYScale = Math::Lerp(0.2, 1.0, ScaleValue);

		LavaRoot.SetRelativeScale3D(FVector(XYScale, XYScale, ZScale));

		LightComp.SetIntensity(Math::EaseOut(0.0, SpotLightIntensity, Alpha, 2.0));
	}

	UFUNCTION()
	private void StopPouring()
	{
		bFalling = true;
		USanctuaryCentipedeLavaBowlEventHandler::Trigger_OnStopPouring(this);
		BP_StopPouring();
	}

	UFUNCTION()
	private void UpdateStopPouring(float Alpha)
	{
		float ScaleValue = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha);
	
		XYScale = Math::Lerp(1.0, 0.2, ScaleValue);

		LavaRoot.SetRelativeScale3D(FVector(XYScale, XYScale, ZScale));

		LightComp.SetIntensity(Math::EaseOut(SpotLightIntensity, 0.0, Alpha, 2.0));
	}

	UFUNCTION()
	private void UpdateBowlLava(float Alpha)
	{
		float ScaleValue = BowlCurve.GetFloatValue(Alpha);

		BowlLavaRoot.SetRelativeScale3D(FVector(Math::Lerp(0.5, 1.0, ScaleValue)));
	}

	UFUNCTION(BlueprintEvent)
	private void BP_StartPouring(){}

	UFUNCTION(BlueprintEvent)
	private void BP_StopPouring(){}
};