class AEvergreenWallMover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditAnywhere)
	AEvergreenLifeManager Manager;

	UPROPERTY(NotVisible)
	float CurrentAlpha;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedFloat;

	float Velocity;

	float TargetAlpha;
	float AccelerationSpeed = 0.01;
	float VelocityRetention = 1.5;
	FHazeAcceleratedFloat AccFloatAlpha;
	float LastInput = 0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Manager.LifeComp.OnInteractStartDuringLifeGive.AddUFunction(this, n"StartInteract");
		Manager.LifeComp.OnInteractStopDuringLifeGive.AddUFunction(this, n"StopInteract");
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			float Input = Math::Sign(Manager.LifeComp.RawHorizontalInput);
			if(SyncedFloat.Value <  0.2 && Input > 0)
				Input = 0;
			else if(SyncedFloat.Value > 0.8 && Input < 0)
				Input = 0;

			AccFloatAlpha.AccelerateTo(Input, VelocityRetention, DeltaSeconds);
			
			SyncedFloat.Value -= AccFloatAlpha.Value * AccelerationSpeed;
			SyncedFloat.Value = Math::Clamp(SyncedFloat.Value, 0, 1.0);
		}
			
		CurrentAlpha = SyncedFloat.Value;
	}

	UFUNCTION(BlueprintEvent)
	void StartInteract()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void StopInteract()
	{

		
	}
};