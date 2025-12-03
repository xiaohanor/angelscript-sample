class ASkylinePhoneProgressSpline : ASplineActor
{

#if EDITOR
	default Spline.EditingSettings.SplineColor = FLinearColor::Yellow;
#endif 

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	TArray<AActor> ActorsToRenderFaceRecognition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};