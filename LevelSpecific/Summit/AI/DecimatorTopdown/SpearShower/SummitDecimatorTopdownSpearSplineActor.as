
UCLASS(HideCategories = "HiddenSpline Rendering Debug Activation Collision HLOD Tags Physics DataLayers AssetUserData WorldPartition Actor LOD Cooking RayTracing TextureStreaming")
class ASummitDecimatorTopdownSpearSplineActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	bool bVisualizeSpawnLocations = true;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);
	default Billboard.SpriteName = "T_Loft_Spline";
#endif

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UHazeSplineComponent Spline;
	default Spline.EditingSettings.HeightIndicators = ESplineHeightIndicatorMode::None;

	UPROPERTY(DefaultComponent)
	USummitDecicmatorTopdownSpearVisualizerComponent VisualizerComp;

	// Sort by name FString
	int opCmp(ASummitDecimatorTopdownSpearSplineActor Other) const
	{
		if(this.GetActorNameOrLabel() > Other.GetActorNameOrLabel())
			return 1;
		else
			return -1;
	}
	
}

class USummitDecicmatorTopdownSpearVisualizerComponent : UActorComponent
{
}

class USummitDecimatorTopdownSpearSplineVisuzalizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitDecicmatorTopdownSpearVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{		
		USummitDecicmatorTopdownSpearVisualizerComponent DummyComp = Cast<USummitDecicmatorTopdownSpearVisualizerComponent>(Component);
		UHazeSplineComponent Spline =  UHazeSplineComponent::Get(DummyComp.Owner);
		auto SplineActor = Cast<ASummitDecimatorTopdownSpearSplineActor>(DummyComp.Owner);

		if (!SplineActor.bVisualizeSpawnLocations)
			return;

		if (Spline.SplineLength == 0)
			return;

		// Find the minimum plane below the spline
		FTransform Transform = Spline.WorldTransform;
		float SplinePlaneHeight = -100000.0;

		// Draw the height indicator line
		ASummitDecimatorTopdownSpearPatternGroup SplineGroup = Cast<ASummitDecimatorTopdownSpearPatternGroup>(DummyComp.Owner.GetAttachParentActor());
		float FractionInterval = SplineGroup.GroupFractionInterval;
		if (FractionInterval == 0)
		{
			if (SplineGroup.GroupDistanceInterval == 0)
				return;
			
			FractionInterval = SplineGroup.GroupDistanceInterval / Spline.SplineLength;
		}

		if (FractionInterval < 0.001)
			return;

		int NumSpears = Math::FloorToInt(1.0 / FractionInterval);
		for (int i = 0; i < NumSpears; ++i)
		{			
			FVector Location = Spline.GetWorldLocationAtSplineFraction(i * FractionInterval);			
			DrawWireSphere(Location, 40, FLinearColor::LucBlue, 10);

			if (!Math::IsNearlyEqual(Location.Z, SplinePlaneHeight, 1.0))
			{
				FVector PointSplinePlanePosition = Location;
				PointSplinePlanePosition.Z = SplinePlaneHeight;
				float PointScale = 0.1 * (EditorViewLocation.Distance(Location) / 400.0);

				FVector AttachPosition = Location;
				if (Location.Z > SplinePlaneHeight)
					AttachPosition.Z -= PointScale * 50.0;
				else
					AttachPosition.Z += PointScale * 50.0;

				SetRenderForeground(false);
				DrawLine(
					AttachPosition,
					PointSplinePlanePosition,
					FLinearColor(0.81, 0.26, 0.09),
					5.0, true
				);
				SetRenderForeground(true);
			}

		}


	}

}