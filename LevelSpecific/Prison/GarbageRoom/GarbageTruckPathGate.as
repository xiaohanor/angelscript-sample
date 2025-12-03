class AGarbageTruckPathGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent GateRoot;

	UPROPERTY(DefaultComponent, Attach = GateRoot)
	UStaticMeshComponent GateMesh;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenGateTimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenGateTimeLike.BindUpdate(this, n"UpdateOpenGate");
		OpenGateTimeLike.BindFinished(this, n"FinishOpenGate");
	}

	UFUNCTION(BlueprintCallable)
	void OpenGate()
	{
		OpenGateTimeLike.PlayFromStart();
	}

	UFUNCTION(BlueprintCallable)
	void CloseGate()
	{
		OpenGateTimeLike.ReverseFromEnd();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOpenGate(float CurValue)
	{
		float CurOffset = Math::Lerp(0.0, 1500.0, CurValue);
		GateRoot.SetRelativeLocation(FVector(0.0, 0.0, CurOffset));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishOpenGate()
	{

	}
}