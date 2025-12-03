UCLASS(Abstract)
class APigHangHandle : AHazeActor
{
	UPROPERTY(DefaultComponent,  RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent HangRoot;

	UPROPERTY(DefaultComponent, Attach = HangRoot)
	UFauxPhysicsWeightComponent WeightComp;

	UFUNCTION()
	void StartHanging()
	{
		WeightComp.MassScale = 0.1;
	}

	UFUNCTION()
	void StopHanging()
	{
		WeightComp.MassScale = 0.0;
	}
}