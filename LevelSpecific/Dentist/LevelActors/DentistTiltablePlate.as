UCLASS(Abstract)
class ADentistTiltablePlate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp1;

	UPROPERTY(DefaultComponent, Attach = RotateComp1)
	UFauxPhysicsAxisRotateComponent RotateComp2;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent FauxPhysicsPlayerWeightComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};