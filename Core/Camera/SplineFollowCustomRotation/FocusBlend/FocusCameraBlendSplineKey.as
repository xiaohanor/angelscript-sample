USTRUCT()
struct FFocusCameraBlendSplineKeySettings
{
	// Generic camera settings
	UPROPERTY()
	FBlendSplineKeyCameraSettings CameraSettings;

	// Focus camera settings
	UPROPERTY()
	FHazeCameraKeepInViewSettings KeepInViewSettings;

	// Clamps!
	UPROPERTY()
	FBlendSplineKeyCameraClampSettings ClampSettings;
}

USTRUCT()
struct FFocusCameraBlendSplineKeyVisualizerSettings
{
	// Visualizer color
	UPROPERTY()
	FLinearColor EditorColor = FLinearColor::MakeRandomColor();
}

UCLASS(HideCategories = "Activation Navigation Hidden Rendering Cooking Input Actor LOD AssetUserData Debug Collision InternalHiddenObjects", Meta = (HighlightPlacement))
class UFocusCameraBlendSplineKey : USceneComponent
{
	// Where in the spline is this little guy located
	UPROPERTY(EditAnywhere)
	float DistanceAlongSpline;

	UPROPERTY(EditAnywhere)
	FFocusCameraBlendSplineKeySettings BlendKeySettings;

	// Focus targets used by this key
	UPROPERTY(EditAnywhere)
	TArray<FHazeCameraWeightedFocusTargetInfo> FocusTargets;

	UPROPERTY(EditAnywhere)
	FFocusCameraBlendSplineKeyVisualizerSettings VisualizerSettings;

	// Holds master spline
	UHazeSplineComponent SplineComponent;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Owner != nullptr)
		{
			// Try get spline from specific actor
			ASplineFollowCustomRotationCameraActor SplineFollowCustomRotationCameraOwner = Cast<ASplineFollowCustomRotationCameraActor>(Owner);
			if (SplineFollowCustomRotationCameraOwner != nullptr)
				SplineComponent = SplineFollowCustomRotationCameraOwner.SplineComponent;

			// Try get generic if null
			if (SplineComponent == nullptr)
				SplineComponent = UHazeSplineComponent::Get(Owner);
		}

		if (SplineComponent != nullptr)
		{
			DistanceAlongSpline = Math::Clamp(DistanceAlongSpline, 0.0, SplineComponent.SplineLength);

			FVector Location = SplineComponent.GetWorldLocationAtSplineDistance(DistanceAlongSpline);
			SetWorldLocation(Location);
			// Editor::SelectComponent(this, true);
		}
	}

	int opCmp(UFocusCameraBlendSplineKey Other) const
	{
		return DistanceAlongSpline > Other.DistanceAlongSpline ? 1 : -1;
	}

	void CopyFrom(const UFocusCameraBlendSplineKey& OtherSplineKey)
	{
		WorldTransform = OtherSplineKey.WorldTransform;
		DistanceAlongSpline = OtherSplineKey.DistanceAlongSpline;
		BlendKeySettings = OtherSplineKey.BlendKeySettings;
		FocusTargets = OtherSplineKey.FocusTargets;
		VisualizerSettings = OtherSplineKey.VisualizerSettings;
		SplineComponent = OtherSplineKey.SplineComponent;
	}
}