UCLASS(Abstract)
class ASketchBookSmallFloatBoat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TranslateComp.ApplyForce(GetActorLocation()+FVector(0,0,100),FVector(0,0,-25*Math::Abs(Math::Sin(Time::GameTimeSeconds))));
	}
};
