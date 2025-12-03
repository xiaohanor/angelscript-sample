class AMagnetDroneSocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UDroneMagneticSocketComponent Socket;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = "Socket")
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(Category = "Magnet Drone Socket")
	FOnMagnetDroneStartAttraction OnMagnetDroneStartAttraction;
	
	UPROPERTY(Category = "Magnet Drone Socket")
	FOnMagnetDroneEndAttraction OnMagnetDroneEndAttraction;

	/* Executed when the player attaches to this component. */
    UPROPERTY(Category = "Magnet Drone Socket")
    FOnMagnetDroneAttached OnMagnetDroneAttached;

	/* Executed when the player detaches from this component. */
    UPROPERTY(Category = "Magnet Drone Socket")
    FOnMagnetDroneDetached OnMagnetDroneDetached;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Socket.OnMagnetDroneStartAttraction.AddUFunction(this, n"MagnetDroneStartAttraction");
		Socket.OnMagnetDroneEndAttraction.AddUFunction(this, n"MagnetDroneEndAttraction");
		Socket.OnMagnetDroneAttached.AddUFunction(this, n"MagnetDroneAttached");
		Socket.OnMagnetDroneDetached.AddUFunction(this, n"MagnetDroneDetached");
	}

	UFUNCTION()
	private void MagnetDroneStartAttraction(FOnMagnetDroneStartAttractionParams Params)
	{
		OnMagnetDroneStartAttraction.Broadcast(Params);
	}

	UFUNCTION()
	private void MagnetDroneEndAttraction(FOnMagnetDroneEndAttractionParams Params)
	{
		OnMagnetDroneEndAttraction.Broadcast(Params);
	}

	UFUNCTION()
	private void MagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
		OnMagnetDroneAttached.Broadcast(Params);
	}

	UFUNCTION()
	private void MagnetDroneDetached(FOnMagnetDroneDetachedParams Params)
	{
		OnMagnetDroneDetached.Broadcast(Params);
	}
};