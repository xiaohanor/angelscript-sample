UCLASS(Abstract)
class UMeltdownSplitSlideIntroGateEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartOpen() {}
}

class AMeltdownSplitSlideIntroGate : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent ScifiRightPivot;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent ScifiLeftPivot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent FantasyRightPivot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent FantasyLeftPivot;
	
	UPROPERTY(EditInstanceOnly)
	ADoubleInteractionActor DoubleInteractionActor;

	UPROPERTY()
	FHazeTimeLike OpenGateTimeLike;
	default OpenGateTimeLike.UseSmoothCurveZeroToOne();
	default OpenGateTimeLike.Duration = 2.0;

	UPROPERTY()
	float OpenGateAngle = 120.0;

	UPROPERTY()
	float OpenGateDelay = 2.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OpenGateTimeLike.BindUpdate(this, n"OpenGateTimeLikeUpdate");

		DoubleInteractionActor.OnDoubleInteractionCompleted.AddUFunction(this, n"OpenGate");
	}

	UFUNCTION()
	private void OpenGate()
	{
		DoubleInteractionActor.DisableDoubleInteraction(this);
		Timer::SetTimer(this, n"OpenGateDelayed", OpenGateDelay);
	}

	UFUNCTION()
	void OpenGateDelayed()
	{
		OpenGateTimeLike.Play();

		UMeltdownSplitSlideIntroGateEventHandler::Trigger_OnStartOpen(this);
	}

	UFUNCTION()
	private void OpenGateTimeLikeUpdate(float CurrentValue)
	{
		FRotator RightRot = FRotator(0.0, Math::Lerp(0.0, OpenGateAngle, CurrentValue), 0.0);
		FRotator LeftRot = FRotator(0.0, Math::Lerp(0.0, -OpenGateAngle, CurrentValue), 0.0);

		ScifiRightPivot.SetRelativeRotation(RightRot);
		FantasyRightPivot.SetRelativeRotation(RightRot);
		ScifiLeftPivot.SetRelativeRotation(LeftRot);
		FantasyLeftPivot.SetRelativeRotation(LeftRot);
	}
};