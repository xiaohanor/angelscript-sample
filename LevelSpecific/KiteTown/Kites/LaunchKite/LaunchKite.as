event void FLaunchKiteEvent(AHazePlayerCharacter Player);

class ALaunchKite : AKiteBase
{
	UPROPERTY(DefaultComponent, Attach = KiteHoverRoot)
	USceneComponent LaunchKiteRoot;

	UPROPERTY(DefaultComponent, Attach = LaunchKiteRoot, ShowOnActor)
	ULaunchKitePointComponent LaunchPointComp;
	default LaunchPointComp.RelativeLocation = FVector(-300.0, 0.0, 0.0);
	default LaunchPointComp.LaunchVelocity = 3000.0;
	default LaunchPointComp.LaunchHeightOffset = -20.0;
	default LaunchPointComp.bRestrictToForwardVector = true;
	default LaunchPointComp.PreferredDirection = FVector(1.0, 0.0, 0.1);
	default LaunchPointComp.AcceptanceDegrees = 90.0;
	default LaunchPointComp.ActivationRange = 2000.0;
	default LaunchPointComp.AdditionalVisibleRange = 1500.0;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY()
	FLaunchKiteEvent OnGrappleStarted;

	UPROPERTY()
	FLaunchKiteEvent OnPlayerEnter;

	UPROPERTY()
	FLaunchKiteEvent OnPlayerExit;

	UPROPERTY(EditAnywhere)
	float Pitch = 15.0;

	UPROPERTY(EditAnywhere)
	bool bFlipDirection = false;

	UPROPERTY(EditAnywhere)
	float LaunchDirectionModifier = 1.0;

	UPROPERTY(EditAnywhere)
	float PoiBlendTime = 2.0;

	default HoverValues.HoverOffsetRange = FVector(50.0, 100.0, 100.0);
	default HoverValues.HoverOffsetSpeed = FVector(1.2, 0.8, 1.5);

	default bUseSpiralRope = true;

	UPROPERTY(EditAnywhere)
	bool bTriggerFlight = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		
		LaunchKiteRoot.SetRelativeRotation(FRotator(Pitch, 0.0, 0.0));

		float ForwardDir = bFlipDirection ? -100.0 : 100.0;
		float UpDir = bFlipDirection ? Pitch * -2.0 : Pitch * 2.0;
		LaunchPointComp.PreferredDirection = (FVector(ForwardDir, 0.0, UpDir * LaunchDirectionModifier));

		float LaunchPointOffset = bFlipDirection ? 900.0 : -300.0;
		float LaunchPointRotation = bFlipDirection ? 180.0 : 0.0;
		LaunchPointComp.SetRelativeLocationAndRotation(FVector(LaunchPointOffset, 0.0, 0.0), FRotator(0.0, LaunchPointRotation, 0.0));
	}
}