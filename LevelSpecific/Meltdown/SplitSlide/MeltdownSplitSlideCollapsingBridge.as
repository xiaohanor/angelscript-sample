class AMeltdownSplitSlideCollapsingBridge : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent BridgeRootScifi;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent BridgeRootFantasy;

	UPROPERTY(EditInstanceOnly)
	APlayerForceSlideVolume SlideVolume;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraVolume CameraVolume;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BridgeRootFantasy.SetRelativeRotation(RotateComp.RelativeRotation);
	}

	UFUNCTION()
	void Break()
	{
		RotateComp.ConstrainAngleMax = 20.0;
		SlideVolume.SetVolumeEnabled(true);
		CameraVolume.Enable();
		BP_Break();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Break()
	{
	}
};