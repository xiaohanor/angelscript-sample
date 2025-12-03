UCLASS(Abstract)
class AMagnetDroneSwitch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UDroneMagneticSocketComponent SocketComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditInstanceOnly, Category = Audio)
	AHazeActor SoundPositionActor = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SocketComp.OnMagnetDroneAttached.AddUFunction(this, n"OnMagnetDroneAttached");
		SocketComp.OnMagnetDroneDetached.AddUFunction(this, n"OnMagnetDroneDetached");
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

	UFUNCTION(BlueprintEvent)
	void BP_OnMagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnMagnetDroneDetached(FOnMagnetDroneDetachedParams Params)
	{
	}
};