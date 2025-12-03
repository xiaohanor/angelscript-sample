class ASolarFlareSwingWeightPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent EmissiveMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent EmissiveMeshComp2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SwingRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SolarFlareSwingPlatformActivatedCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SolarFlareSwingPlatformReturnCapability");

	UPROPERTY(EditAnywhere)
	ASolarFlareBatteryPerch BatteryPerch;

	UPROPERTY()
	UMaterialInterface OnMaterial;
	UMaterialInterface OffMaterial;

	float PlatformCurrentOffset;
	float PlatformFwdOffsetTarget = 650.0;
	float ZOffsetTarget = 180.0;
	float ZOffsetCurrent;

	FVector StartingLoc;
	FHazeAcceleratedQuat AccelRot;

	bool bPerching;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingLoc = PlatformRoot.RelativeLocation;
		// SwingActor.OnPlayerAttachedToSwingPointEvent.AddUFunction(this, n"OnPlayerAttachedToSwingPointEvent");
		// SwingActor.OnPlayerDetachedFromSwingPointEvent.AddUFunction(this, n"OnPlayerDetachedFromSwingPointEvent");

		AccelRot.Value = PlatformRoot.RelativeRotation.Quaternion();
		// SwingActor.AttachToComponent(SwingRoot, NAME_None, EAttachmentRule::KeepWorld);
		BatteryPerch.OnSolarFlareBatteryPerchActivated.AddUFunction(this, n"OnSolarFlareBatteryPerchActivated");
		BatteryPerch.OnSolarFlareBatteryPerchDeactivated.AddUFunction(this, n"OnSolarFlareBatteryPerchDeactivated");
		BatteryPerch.AttachToComponent(SwingRoot, NAME_None, EAttachmentRule::KeepWorld);
		OffMaterial = EmissiveMeshComp.GetMaterial(0);
	}

	UFUNCTION()
	private void OnSolarFlareBatteryPerchActivated(AHazePlayerCharacter Player)
	{
		bPerching = true;
		EmissiveMeshComp.SetMaterial(0, OnMaterial);
		EmissiveMeshComp2.SetMaterial(0, OnMaterial);
		FSolarFlareSwingWeightedPlatformParams Params;
		Params.Location = ActorLocation;
		USolarFlareSwingWeightPlatformEffectHandler::Trigger_OnWeightedPlatformTurnedOn(this, Params);
	}

	UFUNCTION()
	private void OnSolarFlareBatteryPerchDeactivated()
	{
		bPerching = false;
		EmissiveMeshComp.SetMaterial(0, OffMaterial);
		EmissiveMeshComp2.SetMaterial(0, OffMaterial);
		FSolarFlareSwingWeightedPlatformParams Params;
		Params.Location = ActorLocation;
		USolarFlareSwingWeightPlatformEffectHandler::Trigger_OnWeightedPlatformTurnedOff(this, Params);
	}

	// UFUNCTION()
	// private void OnPlayerAttachedToSwingPointEvent(AHazePlayerCharacter Player,
	//                                                USwingPointComponent SwingPoint)
	// {
	// 	SwingPoint.DisableForPlayer(Player.OtherPlayer, this);
	// }

	// UFUNCTION()
	// private void OnPlayerDetachedFromSwingPointEvent(AHazePlayerCharacter Player,
	//                                                  USwingPointComponent SwingPoint)
	// {
	// 	SwingPoint.EnableForPlayer(Player.OtherPlayer, this);
	// }
}