class ASlingshotKite : AKiteBase
{
	default bUseRope = false;

	UPROPERTY(DefaultComponent, Attach = KiteHoverRoot)
	USceneComponent RotorRoot;

	UPROPERTY(DefaultComponent, Attach = RotorRoot)
	USceneComponent GrappleRoot;

	UPROPERTY(DefaultComponent, Attach = GrappleRoot)
	USlingshotKiteGrapplePointComponent GrapplePointComp;

	UPROPERTY(DefaultComponent, Attach = KiteHoverRoot)
	USpringArmCamera CameraComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(EditDefaultsOnly)
	FText TutorialText;

	UPROPERTY(EditAnywhere)
	bool bAlwaysLaunchForward = false;

	UPROPERTY(EditAnywhere)
	float LaunchForce = 8000.0;

	float RotationSpeed = 420.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);
		
		RotorRoot.AddLocalRotation(FRotator(0.0, RotationSpeed * DeltaTime, 0.0));
	}
}