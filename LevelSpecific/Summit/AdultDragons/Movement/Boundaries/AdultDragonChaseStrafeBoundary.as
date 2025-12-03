class AAdultDragonChaseStrafeBoundary : AVolume
{
	default BrushComponent.LineThickness = 2;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComp;
	default ArrowComp.SetWorldScale3D(FVector(5.0));

	UPROPERTY(EditAnywhere, Category = "Level Boundary")
	bool bStartDisabled = false;

	UPROPERTY(EditAnywhere, Category = "Level Boundary")
	bool bEnterChaseMode = true;

	// How much it influences the steering towards the center of the boundary
	// Measured in times normal steering strength
	UPROPERTY(EditAnywhere, Category = "Level Boundary")
	float SteeringWeight = 1.4;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bStartDisabled)
			AddActorDisable(this);
	}
}