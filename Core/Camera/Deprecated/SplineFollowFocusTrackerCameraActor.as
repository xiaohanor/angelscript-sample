
// DEPRECATED CLASS! (Use the 'ReplaceDeprecatedCamera' button)
UCLASS(NotPlaceable, HideCategories = "InternalHiddenObjects CurrentCameraSettings CameraOptions Debug Camera Rendering Actor Collision Cooking")
class ASplineFollowFocusTrackerCameraActor : AHazeCameraActor
{
	// The spline the camera will follow
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent CameraSpline;
	default CameraSpline.EditingSettings.bEnableVisualizeScale = true;
    default CameraSpline.EditingSettings.VisualizeScale = 20.0;

	// If true, the guide spline will be shown and used, otherwise it remains hidden.
	UPROPERTY(Category = "InternalHiddenObjects")
	bool bUseGuideSpline = false;

	// The spline we use to determine how far along the camera spline the camera should be. Hidden in editor until user sets the bUseGuideSpline option
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent GuideSpline;
	default GuideSpline.RelativeLocation = FVector(0,0,-100);
	default GuideSpline.EditingSettings.SplineColor = FLinearColor::Green;
	// Guide spline is only shown when selected and UseGuideSpline is true, see construction script
	default GuideSpline.bVisible = false;
	default GuideSpline.EditingSettings.bShowWhenSelected = false; 
	default GuideSpline.EditingSettings.bAllowEditing = false; 

	UPROPERTY(DefaultComponent)
	UCameraWeightedTargetComponent FocusTargetComponent;

	UPROPERTY(DefaultComponent)
	UCameraWeightedTargetOptionalComponent OptionalTransformTargetComponent;

	UPROPERTY(OverrideComponent = Camera)
	USplineFollowCamera Camera;

	UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	FCameraSplineFollowUserSettings SplineFollowSettings;

	// This will replace the camera with a 'SplineFollowCameraActor' and apply the settings of this camera'
	UFUNCTION(CallInEditor, Category = "Replace")
	void ReplaceDeprecatedCamera()
	{
		auto NewCamera = SpawnActor(ASplineFollowCameraActor);
		NewCamera.Camera.EditorCopyCameraSettings(Camera);
		NewCamera.SetActorTransform(GetActorTransform());
		
		CameraReplace::CopySpline(CameraSpline, NewCamera.CameraSpline);
		CameraReplace::CopySpline(GuideSpline, NewCamera.GuideSpline);
		NewCamera.bUseGuideSpline = bUseGuideSpline;

		CameraReplace::CopyTargets(FocusTargetComponent, NewCamera.FocusTargetComponent);
		CameraReplace::CopyOptionalTargets(OptionalTransformTargetComponent, NewCamera.LocationTargetComponent);

		NewCamera.SplineFollowSettings = SplineFollowSettings;
		NewCamera.LocationTargetType = ECameraSplineLocationTargetType::PlaceAtTargetSplineLocation;
		NewCamera.RotationTargetType = ECameraSplineRotationTargetType::LookAtFocusTarget;
		
		CameraReplace::ReplaceCamera(this, NewCamera);
	}
	
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		if (bUseGuideSpline)
		{
			GuideSpline.EditingSettings.bShowWhenSelected = true;
			GuideSpline.EditingSettings.bAllowEditing = true;
			
			// Guide spline should always match camera spline closed loop property
			GuideSpline.SplineSettings.bClosedLoop = CameraSpline.IsClosedLoop();
		}
		else
		{
			GuideSpline.EditingSettings.bShowWhenSelected = false;
			GuideSpline.EditingSettings.bAllowEditing = false;
		}


		#if EDITOR
		// We want to debug draw the focus locations on the spline
		FocusTargetComponent.EditorDebugSpline = CameraSpline;
		SplineFollowSettings.SetEditorEditConditions(ECameraSplineLocationTargetType::PlaceAtTargetSplineLocation, ECameraSplineRotationTargetType::LookAtFocusTarget);
		#endif
    }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devError(f"The 'SplineFollowFocusTrackerCameraActor' {this} has been deprecated. Please use the 'ReplaceDeprecatedCamera' button on this actor");
	}

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto SplineData = Cast<UCameraSplineUpdater>(CameraData);
	
		FFocusTargets FocusTargets;
		FFocusTargets LocationTargets;

		#if EDITOR
		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			FocusTargets = FocusTargetComponent.GetEditorPreviewTargets();

			if(OptionalTransformTargetComponent.HasValidTargets())
				LocationTargets = OptionalTransformTargetComponent.GetEditorPreviewTargets();
			else
				LocationTargets = FocusTargets;
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				FocusTargets = FocusTargetComponent.GetFocusTargets(PlayerOwner);

				if(OptionalTransformTargetComponent.HasValidTargets())
					LocationTargets = OptionalTransformTargetComponent.GetFocusTargets(PlayerOwner);
				else
					LocationTargets = FocusTargets;
			}
		}	

		SplineData.InitSettings(CameraSpline, SplineFollowSettings);
		if(bUseGuideSpline)
			SplineData.ApplyFractionDetectionSpline(GuideSpline);

		SplineData.PlaceAtTargetSplineLocation(LocationTargets);
		SplineData.LookAtFocusTarget(FocusTargets);
	}
};
