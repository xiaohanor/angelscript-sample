class ASanctuaryLakeChandelier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetLocationComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	USceneComponent LowerChainRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent UpperChainRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent ArrowComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ChandelierRoot;

	UPROPERTY(DefaultComponent, Attach = ChandelierRoot)
	UFauxPhysicsConeRotateComponent ConeRotateComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UStaticMeshComponent ChandelierMesh;

	UPROPERTY(EditAnywhere)
	ASanctuaryHydraKillerBallistaProjectile Arrow;

	UPROPERTY(EditAnywhere)
	ASanctuaryHydraKillerBallista Ballista;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem WaterVFX;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SparksVFX;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditAnywhere)
	TArray<APerchPointActor> PerchPoints;

	UPROPERTY()
	FRuntimeFloatCurve LandBobFloatCurve;

	UPROPERTY(EditAnywhere)
	float DropTimer = 1.5;

	UPROPERTY(EditAnywhere)
	float FallDuration = 1.5;

	UPROPERTY(EditAnywhere)
	float ClampedAlpha = 0.35;

	UPROPERTY(EditAnywhere)
	float ImpulseStrength = 300.0;

	FVector OGLocation;
	bool bDoOnce = true;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Ballista != nullptr)
			Ballista.OnMashCompleted.AddUFunction(this, n"HandleOnMashCompleted");
		
		for(auto PerchPoint : PerchPoints)
		{
			PerchPoint.AddActorDisable(this);
		}

		OGLocation = ChandelierRoot.GetWorldLocation();
	}

	UFUNCTION()
	private void HandleOnMashCompleted()
	{
		QueueComp.Idle(DropTimer);
		QueueComp.Event(this, n"HandleChandelierFallDown");
		QueueComp.Duration(FallDuration, this, n"FallUpdate");
		QueueComp.Event(this, n"LightsOff");
		QueueComp.Duration(2.0, this, n"BobUpdate");
	}

	UFUNCTION()
	void HandleChandelierFallDown()
	{
		for(auto PerchPoint : PerchPoints)
		{
			PerchPoint.RemoveActorDisable(this);
		}
	
		SparksVFX.Activate();
		UpperChainRoot.ApplyImpulse(ArrowComp.WorldLocation, ArrowComp.ForwardVector * ImpulseStrength);
		ConeRotateComp.ApplyImpulse(ArrowComp.WorldLocation, ArrowComp.ForwardVector * ImpulseStrength);
		Game::Mio.PlayForceFeedback(ForceFeedback, false, true, this, 1.0);
		Game::Zoe.PlayForceFeedback(ForceFeedback, false, true, this, 1.0);

		USanctuaryLakeChandelierEventHandler::Trigger_OnFall(this);
	}

	UFUNCTION()
	private void FallUpdate(float Alpha)
	{
		float ChandelierLocationAlpha = Math::EaseIn(0.0, 1.0, Alpha, 2.0);
		float NewChainScaleAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, ClampedAlpha), FVector2D(1.0, 0.0), Alpha);
		float NewChainScale = Math::EaseIn(0.0, 1.0, NewChainScaleAlpha, 2.0);

		ChandelierRoot.SetWorldLocation(Math::Lerp(OGLocation, TargetLocationComp.WorldLocation, ChandelierLocationAlpha));
		LowerChainRoot.SetRelativeScale3D(FVector(1.0, 1.0, NewChainScale));
	}

	UFUNCTION()
	private void LightsOff()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(WaterVFX, ChandelierMesh.GetWorldLocation());
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		BP_LightsOff();

		ConeRotateComp.SpringStrength = 0.2;
		ConeRotateComp.Friction = 2.0;
	}

	UFUNCTION()
	private void BobUpdate(float Alpha)
	{
		FVector Location = TargetLocationComp.WorldLocation;
		Location += FVector::UpVector * (LandBobFloatCurve.GetFloatValue(Alpha) * 250.0);
		ChandelierRoot.SetWorldLocation(Location);
	}

	UFUNCTION(BlueprintEvent)
	void BP_LightsOff(){}
};

UCLASS(Abstract)
class USanctuaryLakeChandelierEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFall() {}
};