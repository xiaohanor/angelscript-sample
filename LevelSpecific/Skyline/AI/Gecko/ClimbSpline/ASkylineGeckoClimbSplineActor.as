
UCLASS(HideCategories = "HiddenSpline Rendering Debug Activation Collision HLOD Tags Physics DataLayers AssetUserData WorldPartition Actor LOD Cooking RayTracing TextureStreaming")
class ASkylineGeckoClimbSplineActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);
	default Billboard.SpriteName = "T_Loft_Spline";
#endif

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UHazeSplineComponent ClimbSpline;
	default ClimbSpline.EditingSettings.bEnableVisualizeRoll = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegistrationComp;

	FVector Start;
	FVector End;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Start = ClimbSpline.GetWorldLocationAtSplineFraction(0.0);
		End = ClimbSpline.GetWorldLocationAtSplineFraction(1.0);
	}

	FSplinePosition GetSplinePositionNearWorldLocation(FVector Location) const
	{
		// All climb splines are currently fairly linear, so approximate by closest point along line from start to end.
		// We now have lots of geckos, so efficiency > precision.
		FVector Dummy;
		float Fraction = 0.0;
		Math::ProjectPositionOnLineSegment(Start, End, Location, Dummy, Fraction);
		return ClimbSpline.GetSplinePositionAtSplineDistance(ClimbSpline.SplineLength * Fraction);
	}
}
