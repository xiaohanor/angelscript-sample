UCLASS(Abstract)
class AInBetweenJetBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsFreeRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsWeightComponent WeightComp;

	default WeightComp.AddDisabler(this);

	UFUNCTION(BlueprintCallable)
	void ApplyImpulse(FVector Origin, FVector Direction, float Force)
	{
		WeightComp.RemoveDisabler(this);
		TranslateComp.ApplyImpulse(Origin, Direction * Force);
		RotateComp.ApplyImpulse(Origin, Direction * Force);
	}
};
