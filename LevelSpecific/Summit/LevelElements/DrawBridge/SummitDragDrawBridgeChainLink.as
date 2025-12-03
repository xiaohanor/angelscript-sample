class ASummitDragDrawBridgeChainLink : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float LinkLength = 300.0;

	UPROPERTY(BlueprintHidden, NotVisible)
	FSplinePosition SplinePos;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugLine(ActorLocation + ActorForwardVector * LinkLength * 0.5
			, ActorLocation - ActorForwardVector * LinkLength * 0.5, FLinearColor::Red, 10);	
	}
#endif
};