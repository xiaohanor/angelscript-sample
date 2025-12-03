class AMeltdownScreenWalkRaderPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsWeightComponent Weight;

	UPROPERTY(DefaultComponent, Attach = Weight)
	UStaticMeshComponent Platform;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DestroyPlatform;

	FHazeTimeLike BridgeDestruction;
	default BridgeDestruction.Duration = 5.0;
	default BridgeDestruction.UseLinearCurveZeroToOne();

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FX_Smoke;
	default FX_Smoke.bAutoActivate = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BridgeDestruction.BindUpdate(this, n"DestroyingBridge");
	}

	UFUNCTION()
	private void DestroyingBridge(float CurrentValue)
	{
		DestroyPlatform.SetScalarParameterValueOnMaterials(n"VAT_DisplayTime", Math::Lerp(0,1,CurrentValue));
		//Debug::DrawDebugSphere(FX_Smoke.GetWorldLocation());
		FX_Smoke.Activate();
	}

	UFUNCTION(BlueprintCallable)
	void StartFall()
	{
		BridgeDestruction.PlayFromStart();
		Platform.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}
};