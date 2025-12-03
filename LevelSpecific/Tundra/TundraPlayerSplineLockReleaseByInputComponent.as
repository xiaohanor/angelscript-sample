class UTundraPlayerSplineLockReleaseByInputComponent : UActorComponent
{
	//Mostly used to hold a reference to the Current Spline Lock Zone for disabling Splinelock via capability

	ATundraConditionalPlayerSplineLockZone ActiveSplineLockZone;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};