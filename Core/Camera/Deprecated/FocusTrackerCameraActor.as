
// DEPRECATED CLASS (Use the 'ReplaceDeprecatedCamera' button)
UCLASS(NotPlaceable, HideCategories = "InternalHiddenObjects CurrentCameraSettings CameraOptions Debug Camera Rendering Actor Collision Cooking")
class AFocusTrackerCameraActor : AHazeCameraActor
{
	UPROPERTY(OverrideComponent = Camera)
	UFocusTargetCamera Camera;

	UPROPERTY(DefaultComponent)
	UCameraWeightedTargetComponent FocusTargetComponent;

	UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	float RotationDuration = 0.0;

	// This will replace the camera with a 'AFocusCameraActor' and apply the settings of this camera
	UFUNCTION(CallInEditor, Category = "Replace")
	void ReplaceDeprecatedCamera()
	{
		auto NewCamera = SpawnActor(AFocusCameraActor);
		NewCamera.Camera.EditorCopyCameraSettings(Camera);
		NewCamera.SetActorTransform(GetActorTransform());
		
		CameraReplace::CopyTargets(FocusTargetComponent, NewCamera.FocusTargetComponent);
		NewCamera.FocusType = ECameraFocusMovementType::Rotation;
		NewCamera.RotationDuration = RotationDuration;
		CameraReplace::ReplaceCamera(this, NewCamera);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devError(f"The 'FocusTrackerCameraActor' {this} has been deprecated. Please use the 'ReplaceDeprecatedCamera' button on this actor");
	}

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto FocusTrackerData = Cast<UCameraFocusTargetUpdater>(CameraData);

		#if EDITOR
		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			FocusTrackerData.FocusTargets = FocusTargetComponent.GetEditorPreviewTargets();
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				FocusTrackerData.FocusTargets = FocusTargetComponent.GetFocusTargets(PlayerOwner);
			}
		}	

		FocusTrackerData.UseFocusRotation(RotationDuration);
	}
}




// DEPRECATED CLASS! (Use the 'ReplaceDeprecatedCamera' button)
UCLASS(NotPlaceable, HideCategories = "InternalHiddenObjects CurrentCameraSettings CameraOptions Debug Camera Rendering Actor Collision Cooking")
class AKeepFocusInViewCameraActor : AKeepInViewCameraActor
{
	// How long it will take to reach the wanted location
	UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	float RotationDuration = 2;

	// This will replace the camera with a 'AFocusCameraActor' and apply the settings of this camera
	void ReplaceDeprecatedCamera() override
	{
		auto NewCamera = SpawnActor(AFocusCameraActor);
		NewCamera.Camera.EditorCopyCameraSettings(Camera);
		NewCamera.SetActorTransform(GetActorTransform());
		
		CameraReplace::CopyTargets(FocusTargetComponent, NewCamera.FocusTargetComponent);
		NewCamera.FocusType = ECameraFocusMovementType::LocationAndRotation;
		NewCamera.LocationDuration = LocationDuration;
		NewCamera.AxisFreedomCenter = AxisFreedomCenter;
		NewCamera.ConstraintVolume = ConstraintVolume;
		NewCamera.AxisFreedomFactor = AxisFreedomFactor;
		NewCamera.MatchInitialVelocityFactor = MatchInitialVelocityFactor;
		NewCamera.RotationDuration = RotationDuration;
	
		CameraReplace::ReplaceCamera(this, NewCamera);
	}
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript() override
	{
		Super::ConstructionScript();
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void BeginPlay() override
	{
		devError(f"The 'KeepFocusInViewCameraActor' {this} has been deprecated. Please use the 'ReplaceDeprecatedCamera' button on this actor");
	}
}