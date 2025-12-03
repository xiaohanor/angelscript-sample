class AGreenhouseEntranceDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	// UPROPERTY(DefaultComponent)
	// UHazeCapabilityComponent CapabilityComp;
	// default CapabilityComp.DefaultCapabilities.Add(n"GreenhouseDoorOpenPOICapability");

	UPROPERTY(EditAnywhere)
	AButtonGrapplePoint Button1;
	UPROPERTY(EditAnywhere)
	AButtonGrapplePoint Button2;
	UPROPERTY(EditAnywhere)
	float DoorMoveDistance = 400.0;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

 	ASolarFlareVOManager VOManager;

	bool bOpenedDoor;
	bool bOneButtonActive;

	int FailedAttempts;
	int MaxFailedAttempts = 3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VOManager = TListedActors<ASolarFlareVOManager>().GetSingle();
	}


//////////// USE THE COMMENTED SECTION IF WANTING TO CONTROL ON WHICH NUMBER OF FAILS THE VO-TRIGGER SHOULD TRIG. /Viktor
/* 	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bOpenedDoor)
			return;
		
		if (Button1.IsButtonActive() || Button2.IsButtonActive())
		{
				bOneButtonActive = true;
		}

		if (Button1.IsButtonActive() && Button2.IsButtonActive())
		{
			bOpenedDoor = true;
			bOneButtonActive = false;
			BP_OpenDoor();
		}

		if (!Button1.IsButtonActive() && !Button2.IsButtonActive())
		{
			if (bOneButtonActive)
			{
				bOneButtonActive = false;
				FailedAttempts++;

				if (FailedAttempts == MaxFailedAttempts)
					VOManager.TriggerGrappleFailedAttempt();
			}
		}
	} */


//////////// USE THIS SECTION FOR A VO-TRIGGER ON EACH FAIL
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!HasControl())
			return;

		if (bOpenedDoor)
			return;
		
		if (Button1.IsButtonActive() || Button2.IsButtonActive())
		{
			bOneButtonActive = true;
		}

		if (Button1.IsButtonActive() && Button2.IsButtonActive())
		{
			bOpenedDoor = true;
			bOneButtonActive = false;
			CrumbOpenDoor();
		}

		if (!Button1.IsButtonActive() && !Button2.IsButtonActive())
		{
			if (bOneButtonActive)
			{
				bOneButtonActive = false;
				VOManager.TriggerGrappleFailedAttempt();
			}
		}
	}

	UFUNCTION()
	void CloseDoor()
	{
		if (!HasControl())
			return;

		CrumbCloseDoor();
	}

	UFUNCTION(CrumbFunction)
	void CrumbOpenDoor()
	{
		Button1.GrappleLaunchPoint.AddActorDisable(this);
		Button2.GrappleLaunchPoint.AddActorDisable(this);
		Button1.SetPermaOn();
		Button2.SetPermaOn();
		BP_OpenDoor();
	}

	UFUNCTION(CrumbFunction)
	void CrumbCloseDoor()
	{
		BP_CloseDoor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenDoor() {}

	UFUNCTION(BlueprintEvent)
	void BP_CloseDoor() {}
}