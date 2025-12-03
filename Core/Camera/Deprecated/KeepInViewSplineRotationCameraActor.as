
// DEPRECATED CLASS! (Use the 'ReplaceDeprecatedCamera' button)
UCLASS(NotPlaceable, HideCategories = "InternalHiddenObjects CurrentCameraSettings CameraOptions Debug Camera Rendering Actor Collision Cooking")
class AKeepInViewSplineRotationCameraActor : AHazeCameraActor
{   
  	UPROPERTY(OverrideComponent = Camera)
	USplineFollowCamera Camera;
	default Camera.bSnapOnTeleport = false;
	default Camera.bHasKeepInViewSettings = true;

	// The spline the camera will follow rotation of
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent CameraSpline;

	UPROPERTY(DefaultComponent)
	UCameraWeightedTargetComponent FocusTargetComponent;

	UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	FCameraSplineFollowUserSettings SplineFollowSettings;

	// This will replace the camera with a 'SplineFollowCameraActor' and apply the settings of this camera
	UFUNCTION(CallInEditor, Category = "Replace")
	void ReplaceDeprecatedCamera()
	{
		auto NewCamera = SpawnActor(ASplineFollowCameraActor);
		NewCamera.Camera.EditorCopyCameraSettings(Camera);
		NewCamera.SetActorTransform(GetActorTransform());
		
		CameraReplace::CopySpline(CameraSpline, NewCamera.CameraSpline);
		CameraReplace::CopyTargets(FocusTargetComponent, NewCamera.FocusTargetComponent);
	
		NewCamera.SplineFollowSettings = SplineFollowSettings;
		NewCamera.LocationTargetType = ECameraSplineLocationTargetType::PlaceAtTargetSplineLocation;
		NewCamera.RotationTargetType = ECameraSplineRotationTargetType::SplineRotationAtFocusTargetSplineLocation;
		NewCamera.bApplyKeepInViewToLocation = true;

		CameraReplace::ReplaceCamera(this, NewCamera);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		#if EDITOR
		// We want to debug draw the focus locations on the spline
		FocusTargetComponent.EditorDebugSpline = CameraSpline;
		SplineFollowSettings.SetEditorEditConditions(ECameraSplineLocationTargetType::PlaceAtTargetSplineLocation, ECameraSplineRotationTargetType::SplineRotationAtFocusTargetSplineLocation, true);
		#endif

	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devError(f"The 'KeepInViewSplineRotationCameraActor' {this} has been deprecated. Please use the 'ReplaceDeprecatedCamera' button on this actor");
	}

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto SplineData = Cast<UCameraSplineUpdater>(CameraData);
	
		FFocusTargets FocusTargets;
		//FFocusTargets LocationTargets;

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

		SplineData.InitSettings(CameraSpline, SplineFollowSettings);

		// Location
		SplineData.PlaceAtTargetSplineLocation(FocusTargets);
		SplineData.ApplyKeepInViewToLocation(HazeUser);
		
		// Rotation
		SplineData.LookInSplineRotationAtFocusTargetSplineLocation(FocusTargets);

	}
}
