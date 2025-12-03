
/**
 * Grapple point for the coast train that can only be used when sufficiently upward.
 */
 UCLASS(Abstract)
 class ACoastTrainTwistableLaunchPoint : AHazeActor
 {
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGrappleLaunchPointComponent GrappleLaunchPoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent UpDirection;
	default UpDirection.RelativeRotation = FRotator(90.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent)
	UCoastTrainCartBasedDisableComponent CartDisableComp;
	default CartDisableComp.bAutoDisable = true;
	default CartDisableComp.AutoDisableRange = 15000.0;

	// How many degrees from upward the grapple point can be to be usable
	UPROPERTY(EditAnywhere)
	float MaximumUsableAngle = 15.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif

	private bool bWasUsable = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector TargetUp = UpDirection.WorldRotation.ForwardVector;
		float UpAngle = Math::RadiansToDegrees(TargetUp.AngularDistance(FVector::UpVector));

		bool bUsable = UpAngle <= MaximumUsableAngle;
		if (bUsable != bWasUsable)
		{
			if (bUsable)
				GrappleLaunchPoint.Enable(n"InvalidAngle");
			else
				GrappleLaunchPoint.Disable(n"InvalidAngle");
			bWasUsable = bUsable;
		}
	}
}