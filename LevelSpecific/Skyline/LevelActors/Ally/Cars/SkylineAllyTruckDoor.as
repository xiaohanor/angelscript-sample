class ASkylineAllyTruckDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateCompDoor1;

	UPROPERTY(DefaultComponent, Attach = RotateCompDoor1)
	UFauxPhysicsForceComponent ForceCompDoor1;

	UPROPERTY(DefaultComponent, Attach = RotateCompDoor1)
	UFauxPhysicsAxisRotateComponent RotateCompLever;
	default RotateCompLever.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = RotateCompLever)
	UFauxPhysicsForceComponent ForceCompLever;

	UPROPERTY(DefaultComponent, Attach = RotateCompLever)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = RotateCompDoor1)
	USceneComponent SprintRootComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateCompDoor2;

	UPROPERTY(DefaultComponent, Attach = RotateCompDoor2)
	UFauxPhysicsForceComponent ForceCompDoor2;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(EditInstanceOnly)
	APoleClimbActor PoleActor;

	bool bOpen = false;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");
		RotateCompLever.OnMaxConstraintHit.AddUFunction(this, n"HandleMaxConstraintHit");
		PoleActor.bAllowPerchOnTop = false;
	}

	UFUNCTION()
	private void HandleMaxConstraintHit(float Strength)
	{
		RotateCompDoor1.ConstrainAngleMin = -165.0;
		RotateCompDoor2.ConstrainAngleMax = 130.0;
		GravityWhipTargetComponent.Disable(this);
		ForceCompLever.Force = FVector::UpVector * -1000.0;
		bOpen = true;
		PoleActor.bAllowPerchOnTop = true;
		USkylineAllyTruckDoorEventHandler::Trigger_TruckDoorOpen(this);
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent,
	                           UGravityWhipTargetComponent TargetComponent,
	                           TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		USkylineAllyTruckDoorEventHandler::Trigger_OnGravityWhipGrabbed(this);

		if (!bOpen)
			ForceCompLever.Force = FVector::RightVector * 600.0;
	}
	
	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent,
	                            UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		USkylineAllyTruckDoorEventHandler::Trigger_OnGravityWhipReleased(this);
		
		if (!bOpen)
			ForceCompLever.Force = FVector::RightVector * -500.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SprintRootComp.SetRelativeLocation(FVector(SprintRootComp.RelativeLocation.X, 
													SprintRootComp.RelativeLocation.Y,
													RotateCompLever.CurrentRotation * 20.0));
	}
};