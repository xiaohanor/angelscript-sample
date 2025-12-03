
/**
 * A camera that follows a spline
 * The position on the spline is based on the closest position from the focus targets
 */
UCLASS(hideCategories="Hidden Rendering Cooking Input Actor LOD AssetUserData Debug Collision InternalHiddenObjects", Meta = (HighlightPlacement))
class ASplineFollowCameraActor : AHazeCameraActor
{
	// Where the camera should place itself
	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Spline Camera")
	ECameraSplineLocationTargetType LocationTargetType = ECameraSplineLocationTargetType::PlaceAtTargetSplineLocation;

	// What the camera should focus on
	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Spline Camera")
	ECameraSplineRotationTargetType RotationTargetType = ECameraSplineRotationTargetType::SplineRotationAtFocusTargetSplineLocation;

	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Spline Camera", meta = (EditCondition="RotationTargetType==ECameraSplineRotationTargetType::SideRotator", EditConditionHides))
	float SideScrollerCorridorWidth = 400.0;

	// Should we use "keep in view" settings when moving towards the target
	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Spline Camera", meta = (EditCondition="LocationTargetType!=ECameraSplineLocationTargetType::None"))
	bool bApplyKeepInViewToLocation = false;

	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Spline Camera", Meta = (ShowOnlyInnerProperties))
	FCameraSplineFollowUserSettings SplineFollowSettings;

	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Player Input", Meta = (ShowOnlyInnerProperties))
	FCameraSplineFollowUserInputSettings InputSettings;

	/*
	   Use a different spline (GuideSpline) to determine how far along CameraSpline the camera should be.
	   The camera will still use CameraSpline, but with GuideSpline's DistanceAlongSpline instead.
	   Hidden if set to false.
	*/
	UPROPERTY(EditAnywhere, Category = "Current Camera Settings|Spline Camera")
	bool bUseGuideSpline = false;

	// Use a custom camera spline instead of the internal one
	UPROPERTY(EditInstanceOnly, Category = "Current Camera Settings|Spline Camera")
	ASplineActor CustomCameraSpline;

	// The spline the camera will follow
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent CameraSpline;
	default CameraSpline.EditingSettings.bEnableVisualizeScale = true;
    default CameraSpline.EditingSettings.VisualizeScale = 20.0;

	// The spline we use to determine how far along the camera spline the camera should be. Hidden in editor until user sets the bUseGuideSpline option
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent GuideSpline;
	default GuideSpline.RelativeLocation = FVector(0,0,-100);
	default GuideSpline.EditingSettings.SplineColor = FLinearColor::Green;
	// Guide spline is only shown when selected and UseGuideSpline is true, see construction script
	default GuideSpline.bVisible = false;
	default GuideSpline.EditingSettings.bShowWhenSelected = false; 
	default GuideSpline.EditingSettings.bAllowEditing = false; 

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraWeightedTargetComponent FocusTargetComponent;

	UPROPERTY(DefaultComponent)
	USplineFollowCameraRuntimeSettingsComponent RuntimeSettingsComponent;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraWeightedTargetOptionalComponent LocationTargetComponent;

	UPROPERTY(OverrideComponent = Camera, ShowOnActor)
	USplineFollowCamera Camera;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Camera.bHasKeepInViewSettings = LocationTargetType != ECameraSplineLocationTargetType::None && bApplyKeepInViewToLocation;

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
		SplineFollowSettings.SetEditorEditConditions(LocationTargetType, RotationTargetType, bApplyKeepInViewToLocation);
		#endif
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
			FocusTargetComponent.EditorDebugSpline = GetSplineToUse();
			FocusTargets = FocusTargetComponent.GetEditorPreviewTargets();

			if(LocationTargetComponent.HasValidTargets())
				LocationTargets = LocationTargetComponent.GetEditorPreviewTargets();
			else
				LocationTargets = FocusTargets;

			SplineData.InitUserData(Editor::EditorViewRotation);
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				FocusTargets = FocusTargetComponent.GetFocusTargets(PlayerOwner);

				if(LocationTargetComponent.HasValidTargets())
					LocationTargets = LocationTargetComponent.GetFocusTargets(PlayerOwner);
				else
					LocationTargets = FocusTargets;
			}

			SplineData.InitUserData(HazeUser.GetActiveCameraRotation());
		}	

		// Apply settings
		SplineData.InitSettings(GetSplineToUse(), SplineFollowSettings);
		SplineData.InitUserInputSettings(InputSettings);
		SplineData.ApplyRuntimeOverrides(HazeUser, RuntimeSettingsComponent);

		if(bUseGuideSpline)
			SplineData.ApplyFractionDetectionSpline(GuideSpline);

		// Apply the location type
		if(LocationTargetType != ECameraSplineLocationTargetType::None)
		{
			if(LocationTargetType == ECameraSplineLocationTargetType::PlaceAtTargetLocation)
			{
				SplineData.PlaceAtTargetLocation(LocationTargets);
			}
			else if(LocationTargetType == ECameraSplineLocationTargetType::PlaceAtTargetSplineLocation)
			{
				SplineData.PlaceAtTargetSplineLocation(LocationTargets);	
			}
		
			// Should the location be used as a keep in view
			if(bApplyKeepInViewToLocation)
			{
				SplineData.ApplyKeepInViewToLocation(HazeUser);
			}
		}

		// Apply the rotation type
		if(RotationTargetType == ECameraSplineRotationTargetType::SplineRotationAtFocusTargetSplineLocation)
		{
			SplineData.LookInSplineRotationAtFocusTargetSplineLocation(FocusTargets, false);
		}
		else if(RotationTargetType == ECameraSplineRotationTargetType::HorizontalSplineRotationAtFocusTargetSplineLocation)
		{
			SplineData.LookInSplineRotationAtFocusTargetSplineLocation(FocusTargets, true);
		}
		else if(RotationTargetType == ECameraSplineRotationTargetType::LookAtFocusTarget)
		{
			SplineData.LookAtFocusTarget(FocusTargets);
		}
		else if(RotationTargetType == ECameraSplineRotationTargetType::LookAtFocusTargetSplineLocation)
		{
			SplineData.LookAtFocusTargetSplineLocation(FocusTargets);
		}
		else if(RotationTargetType == ECameraSplineRotationTargetType::SideRotator)
		{
			SplineData.UseAsSideRotator(FocusTargets, SideScrollerCorridorWidth);
		}
	}

	UHazeSplineComponent GetSplineToUse() const
	{
		if(CustomCameraSpline != nullptr)
			return CustomCameraSpline.Spline;
		return CameraSpline;
	}
};
