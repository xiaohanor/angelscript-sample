UCLASS(Abstract)
class USplitTraversalCarnivorousPlantGatekeeperEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivate() {}
}

class ASplitTraversalCarnivorousPlantGatekeeper : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent EyeRoot;

	UPROPERTY()
	FHazeTimeLike EyeTimeLike;
	default EyeTimeLike.UseSmoothCurveZeroToOne();
	default EyeTimeLike.Duration = 2.0;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalCarnivorousPlantTarget Target;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		EyeTimeLike.BindUpdate(this, n"EyeTimeLikeUpdate");
		EyeRoot.SetRelativeScale3D(FVector::ZeroVector);

		Target.OnReachedEnd.AddUFunction(this, n"HandleReachedEnd");
	}

	UFUNCTION()
	private void HandleReachedEnd()
	{
		EyeTimeLike.Play();
		BP_Activate();

		USplitTraversalCarnivorousPlantGatekeeperEventHandler::Trigger_OnActivate(this);
	}

	UFUNCTION()
	private void EyeTimeLikeUpdate(float CurrentValue)
	{
		EyeRoot.SetRelativeScale3D(FVector(1.0, 1.0, CurrentValue));
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate()
	{
	}
};