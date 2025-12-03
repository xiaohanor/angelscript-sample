// DEPRECATED CLASS (Use the spline follow camera actor instead!)
UCLASS(Deprecated, HideCategories = "InternalHiddenObjects CurrentCameraSettings CameraOptions Debug Camera Rendering Actor Collision Cooking")
class ASideRotatorKeepInViewCameraActor : AHazeCameraActor
{
	UPROPERTY(OverrideComponent = Camera)
	USplineFollowCamera Camera;

	UPROPERTY(DefaultComponent)
	UCameraWeightedTargetComponent FocusTargetComponent;
	default FocusTargetComponent.EmptyTargetDefaultType = ECameraWeightedTargetEmptyInitType::DefaultToBothUsers;

	// How many seconds we will need to reach target rotation
	UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	float RotationDuration = 5.0;

	UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	float CorridorWidth = 400.0;

	// If set, this spline will be used to control which side of focus targets camera is supposed keep to.
	UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	ASplineActor GuideSpline;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Camera.bHasKeepInViewSettings = true;

		// We want to debug draw the focus locations on the spline
		if(GuideSpline != nullptr)
		{
			#if EDITOR
			FocusTargetComponent.EditorDebugSpline = GuideSpline.Spline;
			#endif
		}
		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devError(f"The 'SideRotatorKeepInViewCameraActor' {this} has been deprecated. Please use the 'ReplaceDeprecatedCamera' button on this actor");
	}


	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto SplineData = Cast<UCameraSplineUpdater>(CameraData);
	
		FFocusTargets FocusTargets;

		#if EDITOR
		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			FocusTargets = FocusTargetComponent.GetEditorPreviewTargets();
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				FocusTargets = FocusTargetComponent.GetFocusTargets(PlayerOwner);
			}
		}	


		// Apply settings
		if(GuideSpline != nullptr)
		{
			FCameraSplineFollowUserSettings SplineFollowSettings;
			SplineFollowSettings.ClearLocationUpdateDuration();
			SplineData.InitSettings(GuideSpline.Spline, SplineFollowSettings);
		}

		SplineData.PlaceAtTargetSplineLocation(FocusTargets);
		SplineData.ApplyKeepInViewToLocation(HazeUser);
		SplineData.UseAsSideRotator(FocusTargets, CorridorWidth);
	}
}
