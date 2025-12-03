class ASkylineAllyPowerWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent FauxPhysicsAxisRotateComponent;
	default FauxPhysicsAxisRotateComponent.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsAxisRotateComponent)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY()
	float PowerLevel = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleWhipGrabbed");
		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleWhipReleased");
	}

	UFUNCTION()
	private void HandleWhipReleased(UGravityWhipUserComponent UserComponent,
	                                UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void HandleWhipGrabbed(UGravityWhipUserComponent UserComponent,
	                               UGravityWhipTargetComponent TargetComponent,
	                               TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PowerLevel = Math::GetMappedRangeValueClamped(
			FVector2D(FauxPhysicsAxisRotateComponent.ConstrainAngleMin, 
			FauxPhysicsAxisRotateComponent.ConstrainAngleMax), 
			FVector2D(0.0, 1.0),
			Math::RadiansToDegrees(FauxPhysicsAxisRotateComponent.CurrentRotation)
			);

		PrintToScreen("PowerLevel = " + PowerLevel);
	}
}