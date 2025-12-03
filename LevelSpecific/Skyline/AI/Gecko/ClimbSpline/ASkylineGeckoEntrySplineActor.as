
UCLASS(HideCategories = "HiddenSpline Rendering Debug Activation Collision HLOD Tags Physics DataLayers AssetUserData WorldPartition Actor LOD Cooking RayTracing TextureStreaming")
class ASkylineGeckoEntrySplineActor : AHazeActor
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
	UHazeSplineComponent Spline;
	default Spline.EditingSettings.bEnableVisualizeRoll = true;
	default Spline.EditingSettings.SplineColor = FLinearColor::Green;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegistrationComp;

	UPROPERTY(EditAnywhere)
	AActor Destination;

	UPROPERTY(EditAnywhere, Meta = (InlineEditConditionToggle))
	bool bUseCustomSpeed = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseCustomSpeed"))
	float CustomSpeed = 800.0;

	UPROPERTY(EditAnywhere)
	bool bDisabled;

	bool bLastUsedSpline = false;
	int NumUsages = 0;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if (Destination == nullptr)
			return;
		FVector Dest = Destination.ActorLocation;
		FVector SplineEnd = Spline.GetWorldLocationAtSplineFraction(1.0);		
		auto DestSpline = UHazeSplineComponent::Get(Destination);
		if (DestSpline != nullptr)
			Dest = DestSpline.GetClosestSplineWorldLocationToWorldLocation(SplineEnd);
		FVector Apex = (SplineEnd + Dest) * 0.5;
		Apex.Z = Math::Max(SplineEnd.Z, Dest.Z) + SplineEnd.Distance(Dest) * 0.5;
		BezierCurve::DebugDraw_1CP(SplineEnd, Apex, Dest, FLinearColor::Yellow, 2.0);
	}
#endif
}
