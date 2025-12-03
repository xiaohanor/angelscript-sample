class AMagnetDroneAttachFlipGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp, ShowOnActor)
	UDroneMagneticSocketComponent SocketComp;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor AttractionCamera;

	UPROPERTY(EditAnywhere)
	FVector AttractionCameraOffset;

	UPROPERTY(EditInstanceOnly, Category = Audio)
	AHazeActor SoundPositionActor = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SocketComp.OnMagnetDroneAttached.AddUFunction(this, n"OnMagnetDroneAttached");
		SocketComp.OnMagnetDroneDetached.AddUFunction(this, n"OnMagnetDroneDetached");
		SocketComp.OnMagnetDroneStartAttraction.AddUFunction(this, n"OnMagnetDroneStartAttraction");
		SocketComp.OnMagnetDroneEndAttraction.AddUFunction(this, n"OnMagnetDroneEndAttraction");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnMagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
		BP_OnMagnetDroneAttached(Params);
		UMagnetDroneSwitchEventHandler::Trigger_Attached(this, Params);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnMagnetDroneDetached(FOnMagnetDroneDetachedParams Params)
	{
		BP_OnMagnetDroneDetached(Params);
		UMagnetDroneSwitchEventHandler::Trigger_Detached(this, Params);
	}

	UFUNCTION()
	private void OnMagnetDroneStartAttraction(FOnMagnetDroneStartAttractionParams Params)
	{
		if(AttractionCamera != nullptr)
		{
			// AttractionCamera.SetActorLocation(Drone::GetMagnetDronePlayer().ActorLocation);
			// AttractionCamera.SetActorLocation(AttractionCamera.ActorLocation - AttractionCameraOffset);
			Drone::GetMagnetDronePlayer().ActivateCamera(AttractionCamera,0.3,this,EHazeCameraPriority::High);
		}
	}

	UFUNCTION()
	private void OnMagnetDroneEndAttraction(FOnMagnetDroneEndAttractionParams Params)
	{
		Drone::GetMagnetDronePlayer().DeactivateCameraByInstigator(this, 2);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnMagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnMagnetDroneDetached(FOnMagnetDroneDetachedParams Params)
	{
	}

	UFUNCTION()
	void SnapFlip()
	{
		BP_SnapFlip();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SnapFlip() {}
};