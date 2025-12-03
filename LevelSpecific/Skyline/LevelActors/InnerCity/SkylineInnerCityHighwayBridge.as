UCLASS(Abstract)
class USkylineInnerCityHighwayBridgeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEdgeHit()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBridgeActivated()
	{
	}


};
class ASkylineInnerCityHighwayBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BridgeRoot1;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot1)
	USceneComponent BridgeRoot2;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot2)
	USceneComponent BridgeRoot3;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot3)
	USceneComponent BridgeRoot4;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot4)
	USceneComponent BridgeRoot5;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueComp;

	UPROPERTY()
	FRuntimeFloatCurve FloatCurve;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterFaceComp;

	UPROPERTY(DefaultComponent,Attach = BridgeRoot5)
	USceneComponent SceneComp;

	UPROPERTY(DefaultComponent, Attach = SceneComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterFaceComp.OnActivated.AddUFunction(this, n"HandleOnTriggerActivate");
	}

	UFUNCTION()
	private void HandleOnTriggerActivate(AActor Caller)
	{
		ActiveBridge();
		USkylineInnerCityHighwayBridgeEventHandler::Trigger_OnBridgeActivated(this);
	}

	void ActiveBridge()
	{
		ActionQueComp.Duration(1.5, this, n"UpdateBridgeExtend1");
		ActionQueComp.Event(this, n"EventConstrainHit");
		ActionQueComp.Idle(0.4);
		ActionQueComp.Duration(1.5, this, n"UpdateBridgeExtend2");
		ActionQueComp.Event(this, n"EventConstrainHit");
		ActionQueComp.Idle(0.4);
		ActionQueComp.Duration(1.5, this, n"UpdateBridgeExtend3");
		ActionQueComp.Event(this, n"EventConstrainHit");
		ActionQueComp.Idle(0.4);
		ActionQueComp.Duration(1.5, this, n"UpdateBridgeExtend4");
		ActionQueComp.Event(this, n"EventConstrainHit");
		ActionQueComp.Idle(0.4);
		ActionQueComp.Duration(1.5, this, n"UpdateBridgeExtend5");
		ActionQueComp.Event(this, n"EventConstrainHit");
	}

	UFUNCTION()
	private void EventConstrainHit()
	{
		USkylineInnerCityHighwayBridgeEventHandler::Trigger_OnEdgeHit(this);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	private void UpdateBridgeExtend1(float Alpha)
	{
		float AlphaRotation = FloatCurve.GetFloatValue(Alpha);
		BridgeRoot1.SetRelativeRotation(FRotator(Math::Lerp(0.0, -9, AlphaRotation), 0.0, 0.0));
	}

	UFUNCTION()
	private void UpdateBridgeExtend2(float Alpha)
	{
		float AlphaRotation = FloatCurve.GetFloatValue(Alpha);
		BridgeRoot2.SetRelativeRotation(FRotator(Math::Lerp(0.0, -9, AlphaRotation), 0.0, 0.0));
	}

		UFUNCTION()
	private void UpdateBridgeExtend3(float Alpha)
	{
		float AlphaRotation = FloatCurve.GetFloatValue(Alpha);
		BridgeRoot3.SetRelativeRotation(FRotator(Math::Lerp(0.0, -9, AlphaRotation), 0.0, 0.0));
	}

	
	UFUNCTION()
	private void UpdateBridgeExtend4(float Alpha)
	{
		float AlphaRotation = FloatCurve.GetFloatValue(Alpha);
		BridgeRoot4.SetRelativeRotation(FRotator(Math::Lerp(0.0, -9, AlphaRotation), 0.0, 0.0));
	}

	UFUNCTION()
	private void UpdateBridgeExtend5(float Alpha)
	{
		float AlphaRotation = FloatCurve.GetFloatValue(Alpha);
		BridgeRoot5.SetRelativeRotation(FRotator(Math::Lerp(0.0, -9, AlphaRotation), 0.0, 0.0));
	}

};