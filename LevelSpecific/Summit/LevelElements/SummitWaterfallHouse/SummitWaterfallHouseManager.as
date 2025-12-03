class ASummitWaterfallHouseManager : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditAnywhere)
	TArray<AKineticSplineFollowActor> Platforms;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Setup")
	void PlacePlatforms()
	{
		for(int i = 0; i < Platforms.Num(); i++)
		{
			float DistanceOffset = Spline.Spline.SplineLength/(Platforms.Num()) ;
			float PlatformDistance = DistanceOffset * (i);
			
			auto Platform = Platforms[i];

			FVector PlatformLocation = Spline.Spline.GetWorldLocationAtSplineDistance(PlatformDistance);
			Platform.SetActorLocation(PlatformLocation);
			Platform.EditorOnly_SetInitialSplinePosition(PlatformDistance);
		}
	}
#endif
}