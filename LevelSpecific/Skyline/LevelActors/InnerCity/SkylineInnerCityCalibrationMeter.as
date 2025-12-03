class ASkylineInnerCityCalibrationMeter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent HandleMesh;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UGravityWhipTargetComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY(DefaultComponent, Attach = TargetComp)
	UTargetableOutlineComponent OutlineComp;

	float StartingConstrainMaxZ;
	float StartingConstrainMinZ;
	bool bIsLocked = false;
	bool bIsCorrectValue = true;
	UPROPERTY(EditAnywhere)
	float CorrectValueMinRange;
	UPROPERTY(EditAnywhere)
	float CorrectValueMaxRange;
	
	bool bDoOnce = true;
	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingConstrainMaxZ = TranslateComp.MaxZ;
		StartingConstrainMinZ = TranslateComp.MinZ;
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleOnGrabbed");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleOnReleased");

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandleDeactivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
		if(TranslateComp.GetRelativeLocation().Z > CorrectValueMinRange && TranslateComp.GetRelativeLocation().Z < CorrectValueMaxRange)
			{
				
				bIsCorrectValue = true;
				BP_ChangeMaterialEnabled();
				if(bIsLocked && bIsCorrectValue && bDoOnce)
				{	
					bDoOnce = false;
					InterfaceComp.TriggerActivate();
					
					}else{
					InterfaceComp.TriggerDeactivate();
					
				}
			}else{
				bIsCorrectValue = false;
				BP_ChangeMaterialDisabled();
			}
		
	}


	UFUNCTION()
	private void HandleDeactivated(AActor Caller)
	{
		
		bIsLocked = false;
		
		
		TranslateComp.MaxZ = StartingConstrainMaxZ; 
		TranslateComp.MinZ = StartingConstrainMinZ;
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		
		TranslateComp.MaxZ = 10.0;
		TranslateComp.MinZ = 10.0;
		ForceComp.AddDisabler(this);
		
		bIsLocked = true;
	}

	UFUNCTION()
	private void HandleOnReleased(UGravityWhipUserComponent UserComponent,
	                              UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		ForceComp.RemoveDisabler(this);
		TranslateComp.Friction = 2.4;
	}

	UFUNCTION()
	private void HandleOnGrabbed(UGravityWhipUserComponent UserComponent,
	                             UGravityWhipTargetComponent TargetComponent,
	                             TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		TranslateComp.Friction = 20.0;
		ForceComp.AddDisabler(this);
	}

	UFUNCTION()
	void DisableCalibration()
	{
		TargetComp.Disable(this);
		ForceComp.AddDisabler(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ChangeMaterialEnabled()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_ChangeMaterialDisabled()
	{}
};