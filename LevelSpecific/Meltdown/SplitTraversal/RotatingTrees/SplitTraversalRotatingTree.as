UCLASS(Abstract)
class USplitTraversalRotatingTreeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Activated() {}
}

class ASplitTraversalRotatingTree : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UFauxPhysicsAxisRotateComponent RotateCompFantasy;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SecondFantasyRotateRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ThirdFantasyRotateRoot;

	UPROPERTY(DefaultComponent, Attach = RotateCompFantasy)
	UFauxPhysicsForceComponent ForceCompFantasy;

	UPROPERTY(DefaultComponent, Attach = RotateCompFantasy)
	USwingPointComponent SwingCompFantasy;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent RotateCompScifi;

	UPROPERTY(DefaultComponent, Attach = RotateCompScifi)
	USwingPointComponent SwingCompScifi;

	UPROPERTY(DefaultComponent)
	USplitTraversalButtonResponseComponent ResponseComp;

	UPROPERTY(EditAnywhere)
	float Force = 100.0;

	UPROPERTY(EditAnywhere)
	float RotationDegrees = 120.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SwingCompFantasy.Disable(this);
		SwingCompScifi.Disable(this);

		ResponseComp.OnPulseArrived.AddUFunction(this, n"HandleActivated");
	}

	UFUNCTION()
	private void HandleActivated()
	{
		ForceCompFantasy.Force = FVector::ForwardVector * Force;
		USplitTraversalRotatingTreeEventHandler::Trigger_Activated(this);
	}

	UFUNCTION()
	void BackTrackHandleActivated()
	{
		ForceCompFantasy.Force = FVector::ForwardVector * Force * 10;
		USplitTraversalRotatingTreeEventHandler::Trigger_Activated(this);
	}

	UFUNCTION()
	void EnableSwingPoints()
	{
		SwingCompFantasy.Enable(this);
		SwingCompScifi.Enable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RotateCompScifi.SetRelativeRotation(RotateCompFantasy.RelativeRotation);
	}
};