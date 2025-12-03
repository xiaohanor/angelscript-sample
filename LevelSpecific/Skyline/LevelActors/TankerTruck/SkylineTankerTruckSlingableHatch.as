class ASkylineTankerTruckSlingableHatch : AWhipSlingableObject
{
	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		InterfaceComp.TriggerActivate();
	}
};