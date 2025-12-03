UCLASS(Abstract)
class USplitTraversalFloatingPlatformGateEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpenGate() {}
}

class ASplitTraversalFloatingPlatformGate : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent GateRootFantasy;

	UPROPERTY(DefaultComponent, Attach = GateRootFantasy)
	UStaticMeshComponent SealHolesMeshComp;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent GateRootSciFi;

	UPROPERTY(EditAnywhere)
	float GateHeight = 1000.0;

	UPROPERTY()
	FHazeTimeLike GateTimeLike;
	default GateTimeLike.UseSmoothCurveZeroToOne();
	default GateTimeLike.Duration = 3.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		GateTimeLike.BindUpdate(this, n"GateTimeLikeUpdate");

		SealHolesMeshComp.SetHiddenInGame(true);
	}

	UFUNCTION()
	void OpenGate()
	{
		GateTimeLike.Play();
		USplitTraversalFloatingPlatformGateEventHandler::Trigger_OnOpenGate(this);
	}

	UFUNCTION()
	void CloseGate()
	{
		GateTimeLike.Reverse();
		SealHolesMeshComp.SetHiddenInGame(false);
	}

	UFUNCTION()
	private void GateTimeLikeUpdate(float CurrentValue)
	{
		FVector GateRelativeLocation = FVector::UpVector * -GateHeight * CurrentValue;
		GateRootFantasy.SetRelativeLocation(GateRelativeLocation);
		GateRootSciFi.SetRelativeLocation(GateRelativeLocation);
	}
};