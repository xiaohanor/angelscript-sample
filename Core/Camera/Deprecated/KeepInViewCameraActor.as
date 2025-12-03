// DEPRECATED CLASS (Use the 'ReplaceDeprecatedCamera' button)
UCLASS(NotPlaceable, HideCategories = "InternalHiddenObjects CurrentCameraSettings CameraOptions Debug Camera Rendering Actor Collision Cooking")
class AKeepInViewCameraActor : AHazeCameraActor
{   
	UPROPERTY(OverrideComponent = Camera)
    UFocusTargetCamera Camera;
	default Camera.bSnapOnTeleport = false;

	UPROPERTY(DefaultComponent)
	UCameraWeightedTargetComponent FocusTargetComponent;

	// How long it will take to reach the wanted location
	UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	float LocationDuration = 5;

	// How much the camera is currently allowed to move towards the target value. Normally (1,1,1), if (0,0,0) it's locked in all axes, if (1,1,0) it's locked upwards/downwards.
    UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
    FVector AxisFreedomFactor = FVector::OneVector;

	// If set, the camera will use this focus target as it's center to lock axes relative to. If not set, camera will always be locked relative to current location.
	UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	FHazeCameraWeightedFocusTargetInfo AxisFreedomCenter;
	default AxisFreedomCenter.SetFocusToActor(nullptr);

	// If set, camera will not be able to leave this volume. Note that volume should be convex, if it's concave you can "trap" the camera in a nook.
    UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	AVolume ConstraintVolume = nullptr;

	// If > 0, camera will try to start with an initial velocity matching that of it's focus targets. This means it will also try to start at an appropriate lagged position. Use this value to tweak how far behind it will lag.
	UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	float MatchInitialVelocityFactor = 0.0;
	
	UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	protected bool bInternalUseFreedomFactor = false;

	// This will replace the camera with a 'AFocusCameraActor' and apply the settings of this camera
	UFUNCTION(CallInEditor, Category = "Replace")
	void ReplaceDeprecatedCamera()
	{
		auto NewCamera = SpawnActor(AFocusCameraActor);
		NewCamera.Camera.EditorCopyCameraSettings(Camera);
		NewCamera.SetActorTransform(GetActorTransform());
		
		CameraReplace::CopyTargets(FocusTargetComponent, NewCamera.FocusTargetComponent);
		
		NewCamera.FocusType = ECameraFocusMovementType::Location;
		NewCamera.LocationDuration = LocationDuration;
		NewCamera.AxisFreedomCenter = AxisFreedomCenter;
		NewCamera.ConstraintVolume = ConstraintVolume;
		NewCamera.AxisFreedomFactor = AxisFreedomFactor;
		NewCamera.MatchInitialVelocityFactor = MatchInitialVelocityFactor;
	
		CameraReplace::ReplaceCamera(this, NewCamera);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		AxisFreedomFactor.X = Math::Clamp(AxisFreedomFactor.X, 0.0, 1.0);
		AxisFreedomFactor.Y = Math::Clamp(AxisFreedomFactor.Y, 0.0, 1.0);
		AxisFreedomFactor.Z = Math::Clamp(AxisFreedomFactor.Z, 0.0, 1.0);
		bInternalUseFreedomFactor = !AxisFreedomFactor.Equals(FVector::OneVector);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devError(f"The 'KeepInViewCameraActor' {this} has been deprecated. Please use the 'ReplaceDeprecatedCamera' button on this actor");
	}

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto KeepInViewData = Cast<UCameraFocusTargetUpdater>(CameraData);
		auto& Settings = KeepInViewData.UpdaterSettings;
		Settings.Init(HazeUser, ConstraintVolume, MatchInitialVelocityFactor);
	
		#if EDITOR

		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			KeepInViewData.FocusTargets = FocusTargetComponent.GetEditorPreviewTargets();
			KeepInViewData.PrimaryTargets = FocusTargetComponent.GetEditorPreviewPrimaryTargets();

			if (AxisFreedomFactor != FVector::OneVector)
			{
				auto EditorAxisFreedomCenter = FocusTargetComponent.GetEditorPreviewFocus(AxisFreedomCenter);
				Settings.SetAxisFreedomFactor(AxisFreedomFactor, EditorAxisFreedomCenter.Location, Camera);
			}
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				KeepInViewData.FocusTargets = FocusTargetComponent.GetFocusTargets(PlayerOwner);
				KeepInViewData.PrimaryTargets = FocusTargetComponent.GetPrimaryTargetsOnly(PlayerOwner);

				if (AxisFreedomFactor != FVector::OneVector)
				{
					Settings.SetAxisFreedomFactor(AxisFreedomFactor, AxisFreedomCenter.GetFocusLocation(PlayerOwner), Camera);
				}
			}
		}

		KeepInViewData.UseFocusLocation(LocationDuration);		
	}	
}
