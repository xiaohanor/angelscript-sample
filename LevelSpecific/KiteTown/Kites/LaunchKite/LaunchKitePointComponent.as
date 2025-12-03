class ULaunchKitePointComponent : UGrappleLaunchPointComponent
{
	UPROPERTY(EditAnywhere, Category = "Settings")
	float FlightVelocity = 2400.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float FlightCameraPitchOffset = 12.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"GrappleInitiated");
	}

	UFUNCTION()
	private void GrappleInitiated(AHazePlayerCharacter Player, UGrapplePointBaseComponent GrapplePoint)
	{
		ULaunchKitePlayerComponent KitePlayerComp = ULaunchKitePlayerComponent::Get(Player);
		KitePlayerComp.LaunchKitePointComp = this;
	}
}