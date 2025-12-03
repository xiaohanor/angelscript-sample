
enum ESplineFollowerType
{
	// Follow weighted middle point of all follow targets
	Weighted, 

	// Weight each target along the spline instead of the middle point
	IndividuallyWeighted,

	// Follow only the follow target which is furthest along the (guide) spline. Will ignore targets with weight 0.
	Foremost, 
	
	// Follow only the follow target which closest to the start of the (guide) spline. Will ignore targets with weight 0.
	Rearmost, 
}

/**
 * 
 */
struct FCameraSplineFollowUserSettings
{
	// Using a duration will instead use a time to reach the target
	UPROPERTY(Category = "Current Camera Settings|Spline Camera")
	bool bUseDurationInsteadOfSpeed = false;

	// How fast we move along the spline  
	UPROPERTY(Category = "Current Camera Settings|Spline Camera", Meta = (EditCondition = "!bUseDurationInsteadOfSpeed", EditConditionHides))
	float FollowSpeed = 1.0;

	// How long time it will take to reach the target
	UPROPERTY(Category = "Current Camera Settings|Spline Camera", Meta = (EditCondition = "bUseDurationInsteadOfSpeed", EditConditionHides))
	float MoveDuration = 2.0;

	// How many seconds will be needed to reach target rotation
	UPROPERTY(Category = "Current Camera Settings|Spline Camera")
	float RotationDuration = 0.0;

	// Camera moves freely if true. Won't move backwards if false.
	UPROPERTY(Category = "Current Camera Settings|Spline Camera")
	bool bCanMoveBackwardsOnSpline = true;

	// Camera's yaw axis will follow spline up vector
	UPROPERTY(Category = "Current Camera Settings|Spline Camera")
	bool bUseSplineUpToRollCamera = false;

	// How do we choose which location we should follow?
	UPROPERTY(Category = "Current Camera Settings|Spline Camera")
	ESplineFollowerType FollowType = ESplineFollowerType::Weighted;

	// The camera is offset this many units behind the follow target along the camera spline. 
	UPROPERTY(Category = "Current Camera Settings|Spline Camera", Meta = (EditCondition="bEditorShowLocationSplineBackwardsOffset"))
	float LocationSplineBackwardsOffset = 0.0;

	// The camera is offset this many units behind the follow target along the camera spline. 
	UPROPERTY(Category = "Current Camera Settings|Spline Camera", Meta = (EditCondition="bEditorShowRotationSplineBackwardsOffset"))
	float RotationSplineBackwardsOffset = 0.0;

	// Use for a spline you should be able to follow in both directions. If true, this will invert backwards offset if that aligns better with view direction when activating camera.
	UPROPERTY(Category = "Current Camera Settings|Spline Camera")
	bool bAlignBackwardsOffsetWithView = false;

	// The higher the angle the more inclined we are to align with spline forward at start and backward at end. 
	UPROPERTY(Category = "Current Camera Settings|Spline Camera", Meta = (EditCondition = "bAlignBackwardsOffsetWithView && bEditorShowBackwardsOffsetAlignAngle"))
	float BackwardsOffsetAlignAngle = 120.0;

	// Location offset from the wanted location
	UPROPERTY(Category = "Current Camera Settings|Spline Camera", Meta = (EditCondition = "!bEditorHasKeepInView && bEditorHasLocationOffset"))
	FVector LocationOffset = FVector::ZeroVector;

	// Rotational offset from the wanted rotation
	UPROPERTY(Category = "Current Camera Settings|Spline Camera", Meta = (EditCondition = "bEditorHasRotationOffset"))
	FRotator RotationOffset = FRotator::ZeroRotator;

	#if EDITOR

	UPROPERTY(EditConst, Category = "Hidden")
	private bool bEditorHasLocationOffset = true;

	UPROPERTY(EditConst, Category = "Hidden")
	private bool bEditorHasRotationOffset = true;

	UPROPERTY(EditConst, Category = "Hidden")
	private bool bEditorShowLocationSplineBackwardsOffset = false;

	UPROPERTY(EditConst, Category = "Hidden")
	private bool bEditorShowRotationSplineBackwardsOffset = false;

	UPROPERTY(EditConst, Category = "Hidden")
	private bool bEditorShowBackwardsOffsetAlignAngle = false;

	UPROPERTY(EditConst, Category = "Hidden")
	private bool bEditorHasKeepInView = false;

	#endif

	void SetEditorEditConditions(ECameraSplineLocationTargetType LocationTargetType, ECameraSplineRotationTargetType RotationTargetType, bool bUseKeepInView = false)
	{
		#if EDITOR
		bEditorHasLocationOffset = LocationTargetType != ECameraSplineLocationTargetType::None;
		bEditorHasRotationOffset = RotationTargetType != ECameraSplineRotationTargetType::None;
		bEditorShowLocationSplineBackwardsOffset = LocationTargetType == ECameraSplineLocationTargetType::PlaceAtTargetSplineLocation;
		bEditorShowRotationSplineBackwardsOffset = RotationTargetType == ECameraSplineRotationTargetType::SplineRotationAtFocusTargetSplineLocation || RotationTargetType == ECameraSplineRotationTargetType::SideRotator || RotationTargetType == ECameraSplineRotationTargetType::LookAtFocusTargetSplineLocation;
		bEditorShowBackwardsOffsetAlignAngle = bEditorShowLocationSplineBackwardsOffset || bEditorShowRotationSplineBackwardsOffset;
		bEditorHasKeepInView = bUseKeepInView;
		#endif
	}

	void ClearLocationUpdateDuration()
	{
		bUseDurationInsteadOfSpeed = true;
		MoveDuration = 0;
	}

	float GetLocationUpdateDuration() const
	{
		if(bUseDurationInsteadOfSpeed)
		{
			return MoveDuration;  
		}
		else
		{
			if (FollowSpeed > 0.0)
		 		return 1.0 / FollowSpeed;
			else
				return 0;
		}
	}
}

struct FCameraSplineFollowUserInputSettings
{
	// Should player input affect camera rotation
	UPROPERTY(Category = "Current Camera Settings|Player Input")
	bool bAllowPlayerCameraInput = false;

	// How fast should we accelerate to desired rotation
	UPROPERTY(Category = "Current Camera Settings|Player Input", Meta = (EditCondition = "bAllowPlayerCameraInput", EditConditionHides))
	float RotationSpeed = 2.0;

	UPROPERTY(Category = "Current Camera Settings|Player Input", Meta = (EditCondition = "bAllowPlayerCameraInput", EditConditionHides))
	FCameraSplineFollowUserInputClampSettings ClampSettings;

	// Interp back to default spline follow view rotation if there is no player input
	UPROPERTY(Category = "Current Camera Settings|Player Input", Meta = (EditCondition = "bAllowPlayerCameraInput", EditConditionHides))
	bool bShouldResetAfterNoInput = false;

	// After how many secs without player input should camera reset
	UPROPERTY(Category = "Current Camera Settings|Player Input", Meta = (EditCondition = "bAllowPlayerCameraInput && bShouldResetAfterNoInput", EditConditionHides, ClampMin = "0.0"))
	float SecsWithNoInput = 2.0;

	// How fast to accelerate back to default spline follow view rotation (in seconds)
	UPROPERTY(Category = "Current Camera Settings|Player Input", Meta = (EditCondition = "bAllowPlayerCameraInput && bShouldResetAfterNoInput", EditConditionHides, ClampMin = "0.0"))
	float ResetAccelerationDuration = 3.0;

	// Eman TODO: restitution mode enum? (i.e. linear, curve, acceleration, etc)

	// Eman TODO: Regain input time?
}

struct FCameraSplineFollowUserInputClampSettings
{
	UPROPERTY(Meta = (InlineEditConditionToggle))
	bool bClampYawLeft;
	UPROPERTY(Meta = (EditCondition = "bClampYawLeft", ClampMin = "0.0", ClampMax = "180.0"))
	float YawLeft = 180.0;

	UPROPERTY(Meta = (InlineEditConditionToggle))
	bool bClampYawRight;
	UPROPERTY(Meta = (EditCondition = "bClampYawRight", ClampMin = "0.0", ClampMax = "180.0"))
	float YawRight = 180.0;

	UPROPERTY(Meta = (InlineEditConditionToggle))
	bool bClampPitchDown;
	UPROPERTY(Meta = (EditCondition = "bClampPitchDown", ClampMin = "0.0", ClampMax = "89.9"))
	float PitchDown = 89.9;

	UPROPERTY(Meta = (InlineEditConditionToggle))
	bool bClampPitchUp;
	UPROPERTY(Meta = (EditCondition = "bClampPitchUp", ClampMin = "0.0", ClampMax = "89.9"))
	float PitchUp = 89.9;

	void ClampRotation(FRotator& OutRotation)
	{
		// Clamp yaw
		float LeftClamp = bClampYawLeft ? YawLeft : 180.0;
		float RightClamp = bClampYawRight ? YawRight : 180.0;
		float Yaw = Math::ClampAngle(OutRotation.Yaw, -Math::Min(LeftClamp, 179.9), Math::Min(RightClamp, 179.9));

		// Clamp pitch
		float DownClamp = bClampPitchDown ? PitchDown : 89.9;
		float UpClamp = bClampPitchUp ? PitchUp : 89.9;
		float Pitch = Math::ClampAngle(OutRotation.Pitch, -Math::Min(DownClamp, 179.9), Math::Min(UpClamp, 179.9));

		OutRotation = FRotator(Pitch, Yaw, 0.0);
	}
}

class USplineFollowCameraRuntimeSettingsComponent : UHazeCameraResponseComponent
{
	private FHazeCameraRuntimeFloat LocationSplineBackwardsOffset;
	private FHazeCameraRuntimeFloat RotationSplineBackwardsOffset;

	UFUNCTION(BlueprintOverride)
	protected void OnCameraUpdateForUser(const UHazeCameraUserComponent HazeUser, float DeltaTime)
	{
		LocationSplineBackwardsOffset.Update(HazeUser, DeltaTime);
		RotationSplineBackwardsOffset.Update(HazeUser, DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	protected void OnCameraSnapForUser(const UHazeCameraUserComponent HazeUser)
	{
		LocationSplineBackwardsOffset.Snap(HazeUser);
		RotationSplineBackwardsOffset.Snap(HazeUser);
	}

	UFUNCTION(Meta = (AdvancedDisplay = "Priority"))
	void ApplySplineBackwardsOffsetOverride(AHazePlayerCharacter Player, float Amount, FInstigator Instigator, EHazeCameraPriority Priority = EHazeCameraPriority::Minimum)
	{
		if(Player == nullptr)
			return;

		auto User = UHazeCameraUserComponent::Get(Player);
		LocationSplineBackwardsOffset.Apply(User, Amount, Instigator, Priority = Priority);
		RotationSplineBackwardsOffset.Apply(User, Amount, Instigator, Priority = Priority);
	}


	UFUNCTION(Meta = (AdvancedDisplay = "Priority"))
	void ApplyLocationSplineBackwardsOffsetOverride(AHazePlayerCharacter Player, float Amount, FInstigator Instigator, EHazeCameraPriority Priority = EHazeCameraPriority::Minimum)
	{
		if(Player == nullptr)
			return;

		auto User = UHazeCameraUserComponent::Get(Player);
		LocationSplineBackwardsOffset.Apply(User, Amount, Instigator, Priority = Priority);
	}


	UFUNCTION(Meta = (AdvancedDisplay = "Priority"))
	void ApplyRotationSplineBackwardsOffsetOverride(AHazePlayerCharacter Player, float Amount, FInstigator Instigator, EHazeCameraPriority Priority = EHazeCameraPriority::Minimum)
	{
		if(Player == nullptr)
			return;

		auto User = UHazeCameraUserComponent::Get(Player);
		RotationSplineBackwardsOffset.Apply(User, Amount, Instigator, Priority = Priority);
	}
	
	UFUNCTION()
	void ClearSplineBackwardsOffsetOverride(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto User = UHazeCameraUserComponent::Get(Player);
		LocationSplineBackwardsOffset.Clear(User, Instigator, 0);
	}

	void GetLocationBackwardsOffsetOverride(const UHazeCameraUserComponent User, float& OutValue) const
	{
		LocationSplineBackwardsOffset.GetValue(User, OutValue, false);
	}

	void GetRotationBackwardsOffsetOverride(const UHazeCameraUserComponent User, float& OutValue) const
	{
		RotationSplineBackwardsOffset.GetValue(User, OutValue, false);
	}
}

struct FCameraSplineFollowSplineData
{
	UHazeSplineComponent ActiveSpline;
	UHazeSplineComponent OptionalFractionSpline;
	FRotator CurrentViewRotation = FRotator::ZeroRotator;
	float ManualFollowFraction = -1;
	bool bWantsToAlignWithBackwardsOffset = false;
	float AlignBackwardsOffsetAngle = -1;
	bool bCanMoveBackwards = true;
}

struct FCameraSplineFollowUserData
{
	FHazeAcceleratedFloat PreviousSplinePositionDistance;
	FHazeAcceleratedFloat PreviousSplineRotationDistance;
	FHazeAcceleratedVector PreviousViewLocation;
	FHazeAcceleratedRotator PreviousViewRotation;
}

struct FCameraSplineFollowUserInputData
{
	FHazeAcceleratedRotator ViewRotationInput;
	float TimeSinceLastInput = -1;
	bool bIsUsingGamepad = false;
}

enum ECameraSplineLocationTargetType
{
	// Don't move the camera
	None,

	// Place the camera on the focus target
	PlaceAtTargetLocation,

	// Place the camera on the spline, closest to the focus target
	PlaceAtTargetSplineLocation,
}

struct FCameraSplineLocation
{
	ECameraSplineLocationTargetType Type = ECameraSplineLocationTargetType::None;
	ESplineFollowerType FollowType = ESplineFollowerType::Weighted;
	FFocusTargets Targets;
	FFocusTargets PrimaryTargets;
	FVector LocationOffset = FVector::ZeroVector;
	float MoveDuration = 0;
	float SplineBackwardsOffset = 0;
	bool bKeepInView = false;
}

enum ECameraSplineRotationTargetType
{
	// Don't rotate the camera
	None,

	// Use the spline rotation closest to the camera position
	SplineRotationAtFocusTargetSplineLocation,

	// Use the spline rotation closest to the camera position but only use the XY plane
	HorizontalSplineRotationAtFocusTargetSplineLocation,

	// Focus on the targets
	LookAtFocusTarget,

	// Focus on the spline position closest to the focus targets 
	LookAtFocusTargetSplineLocation,

	// Use the camera as a side scroll camera
	SideRotator
}

struct FCameraSplineRotation
{
	ECameraSplineRotationTargetType Type = ECameraSplineRotationTargetType::None;
	ESplineFollowerType FollowType = ESplineFollowerType::Weighted;
	FFocusTargets Targets;
	FFocusTargets PrimaryTargets;
	float RotationDuration = 0;
	float SplineBackwardsOffset = 0;
	FRotator RotationOffset = FRotator::ZeroRotator;
	float SideRotatorCorridorWidth = -1;
	bool bUseSplineUpToRollCamera = false;
}

/**
 * 
 */
UCLASS(NotBlueprintable)
class USplineFollowCamera : UHazeCameraComponent
{
	default CameraUpdaterType = UCameraSplineUpdater;
	default bWantsCameraInput = true;

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		UCameraSplineUpdater CameraUpdater = Cast<UCameraSplineUpdater>(CameraData);
		if (CameraUpdater == nullptr)
			return;

		CameraUpdater.SetUsingGamepad(HazeUser.IsUsingGamepad());
	}
}

/**
 * 
 */
#if EDITOR
class USplineFollowCameraVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USplineFollowCamera;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto Camera = Cast<USplineFollowCamera>(Component);
		Camera.VisualizeCameraEditorPreviewLocation(this);
	}
}

#endif


/**
 * A regular spline follow camera
 */
UCLASS(NotBlueprintable)
class UCameraSplineUpdater : UHazeCameraUpdater
{
	protected FCameraSplineFollowSplineData SplineSettings;
	protected FCameraSplineFollowUserData SplineUserData;

	protected FCameraSplineFollowUserInputSettings InputSettings;
	protected FCameraSplineFollowUserInputData InputData;

	protected FCameraFocusTargetData KeepInViewSettings;
	protected FCameraSplineLocation LocationSettings;
	protected FCameraSplineRotation RotationSettings;

	// Keep outside so we only override when we need to
	protected float BackwardsOffsetDirection = 1;

	#if !RELEASE
	float DebugLocationSplineDistance = 0;
	float DebugRotationSplineDistance = 0;
	#endif

	#if EDITOR
	bool bEditorHasUpdatedBackwardsViewOffset = false;
	#endif

	UFUNCTION(BlueprintOverride)
	void Copy(const UHazeCameraUpdater SourceBase)
	{
		auto Source = Cast<UCameraSplineUpdater>(SourceBase);

		SplineSettings = Source.SplineSettings;	
		SplineUserData = Source.SplineUserData;
		
		//KeepInViewUserData = Source.KeepInViewUserData;
		KeepInViewSettings = Source.KeepInViewSettings;
		
		LocationSettings = Source.LocationSettings;
		RotationSettings = Source.RotationSettings;

		BackwardsOffsetDirection = Source.BackwardsOffsetDirection;
	}

	UFUNCTION(BlueprintOverride)
	void PrepareForUser()
	{
		// Every frame we start with this as false
		// so the camera can setup what it wants to apply from a fresh start
		SplineSettings = FCameraSplineFollowSplineData();
		KeepInViewSettings = FCameraFocusTargetData();
		LocationSettings = FCameraSplineLocation();
		RotationSettings = FCameraSplineRotation();

		// This should be kept between frames
		// BackwardsOffsetDirection
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraSnap(FHazeCameraTransform& OutResult)
	{
		if(MainSpline == nullptr)
			return;

		const float SplineLength = MainSpline.SplineLength;
		if(SplineLength <= KINDA_SMALL_NUMBER)
			return;
	
	
		FTransform TargetView = OutResult.ViewTransform;

		if(LocationSettings.Targets.Num() > 0)
			TargetView.Location = UpdateViewLocation(SplineLength, 0, TargetView);
		else if(FunctionType != EHazeCameraFunctionType::SnapWithReset) // During resets, we always need to use the actual camera transform
			TargetView.Location = SplineUserData.PreviousViewLocation.Value;

		if(RotationSettings.Targets.Num() > 0)
			TargetView.Rotation = UpdateViewRotation(SplineLength, 0, TargetView);
		else if(FunctionType != EHazeCameraFunctionType::SnapWithReset) // During resets, we always need to use the actual camera transform
			TargetView.Rotation = SplineUserData.PreviousViewRotation.Value.Quaternion();

		// If we should align the offset with the view
		// we only apply that when we reset the camera;
		if(ShouldUpdateBackwardsOffset())
		{
			GenerateBackwardsViewOffsetDir(OutResult.UserLocation);

			#if EDITOR
			bEditorHasUpdatedBackwardsViewOffset = true;
			#endif
		}

		// If we have keep in view settings,
		// we now apply them since we now know where we would like the camera to be
		UpdateKeepInView(TargetView, 0);

		// If we have any side rotator settings,
		// we now apply them since we now know where we would like the camera to be
		UpdateSideRotator(TargetView, 0);

		// Try to match accelerated location and velocity with average focus velocity
		KeepInViewSettings.ApplyMatchVelocityToLocation(LocationSettings.MoveDuration, SplineUserData.PreviousViewLocation);

		OutResult.ViewLocation = TargetView.Location;
		OutResult.ViewRotation = GetFinalSplineFollowWorldRotation(TargetView, 0);
		//OutResult.ViewRotation = ClampWorldRotation(TargetView.Rotator());
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraUpdate(float DeltaSeconds, FHazeCameraTransform& OutResult)
	{
		if(MainSpline == nullptr)
			return;

		const float SplineLength = MainSpline.SplineLength;
		if(SplineLength <= KINDA_SMALL_NUMBER)
			return;

		if(!ShouldUpdateBackwardsOffset())
		{
			BackwardsOffsetDirection = 1;

			#if EDITOR
			bEditorHasUpdatedBackwardsViewOffset = false;
			#endif
		}

		// In the editor, we can change the type in runtime
		// so if we do, we need to update the view offset angle
		#if EDITOR
		else if(!bEditorHasUpdatedBackwardsViewOffset)
		{
			GenerateBackwardsViewOffsetDir(OutResult.UserLocation);
			bEditorHasUpdatedBackwardsViewOffset = true;
		}
		#endif

		FTransform TargetView = OutResult.ViewTransform;
		if(LocationSettings.Targets.Num() > 0)
			TargetView.Location = UpdateViewLocation(SplineLength, DeltaSeconds, TargetView);
		else if(Type != EHazeCameraUpdaterType::EditorPreview)
			TargetView.Location = SplineUserData.PreviousViewLocation.Value;

		if(RotationSettings.Targets.Num() > 0)
			TargetView.Rotation = UpdateViewRotation(SplineLength, DeltaSeconds, TargetView);
		else if(Type != EHazeCameraUpdaterType::EditorPreview)
			TargetView.Rotation = SplineUserData.PreviousViewRotation.Value.Quaternion();

		// If we have keep in view settings,
		// we now apply them since we now know where we would like the camera to be
		UpdateKeepInView(TargetView, DeltaSeconds);

		// If we have any side rotator settings,
		// we now apply them since we now know where we would like the camera to be
		UpdateSideRotator(TargetView, DeltaSeconds);

		OutResult.ViewLocation = TargetView.Location;
		OutResult.ViewRotation = GetFinalSplineFollowWorldRotation(TargetView, DeltaSeconds);

		// If we have user input settings,
		// apply player camera control rotation
		UpdateInputViewRotation(OutResult, DeltaSeconds);

		// Finally clamp

			// OutResult.ViewRotation = ClampWorldRotation(OutResult.ViewRotation);

		// Eman TODO: Should we change the clamping to support roll?
		FRotator ClampedRotation = ClampWorldRotation(OutResult.ViewRotation);
		ClampedRotation.Roll = OutResult.ViewRotation.Roll;
		OutResult.ViewRotation = ClampedRotation;
	}

	void UpdateInputViewRotation(FHazeCameraTransform& OutCameraTransform, float DeltaTime)
	{
		if (!InputSettings.bAllowPlayerCameraInput)
			return;

		// Get target info
		FRotator UserInputDelta = OutCameraTransform.LocalDesiredRotationDeltaChange;
		FRotator TargetRotation = ClampLocalRotation(InputData.ViewRotationInput.Value + UserInputDelta);

		// Clamp target
		InputSettings.ClampSettings.ClampRotation(TargetRotation);

		// Get acceleration duration
		float AccelerationDuration = 1.0 / Math::Max(DeltaTime, InputSettings.RotationSpeed);
		if (DeltaTime < SMALL_NUMBER)
			AccelerationDuration = 0.0;

		if (InputSettings.bShouldResetAfterNoInput)
		{
			if (UserInputDelta.IsNearlyZero())
			{
				if (InputData.TimeSinceLastInput >= InputSettings.SecsWithNoInput)
				{
					TargetRotation = FRotator::ZeroRotator;
					AccelerationDuration = InputSettings.ResetAccelerationDuration;
				}

				InputData.TimeSinceLastInput += DeltaTime;
			}
			else
			{
				InputData.TimeSinceLastInput = 0;
			}
		}

		InputData.ViewRotationInput.AccelerateTo(TargetRotation, AccelerationDuration, DeltaTime);
		OutCameraTransform.ViewRotation += LocalToWorldRotation(InputData.ViewRotationInput.Value);
	}

	UFUNCTION(BlueprintOverride)
	protected void DebugLogUpdater()
	{
	#if !RELEASE
		//TemporalLog.Value(f"{CameraDebug::CategoryUpdater};Arm Length:", SpringArmData.ArmLength.Value);

	#endif
	}
	
	void InitUserData(FRotator ViewRotation)
	{
		SplineSettings.CurrentViewRotation = ViewRotation;
	}

	void InitSettings(UHazeSplineComponent Spline, FCameraSplineFollowUserSettings FollowSettings)
	{
		SplineSettings.ActiveSpline = Spline;
		SplineSettings.AlignBackwardsOffsetAngle = FollowSettings.BackwardsOffsetAlignAngle;
		SplineSettings.bWantsToAlignWithBackwardsOffset = FollowSettings.bAlignBackwardsOffsetWithView;
		SplineSettings.bCanMoveBackwards = FollowSettings.bCanMoveBackwardsOnSpline;
		
		LocationSettings.MoveDuration = FollowSettings.GetLocationUpdateDuration();
		LocationSettings.LocationOffset = FollowSettings.LocationOffset;
		LocationSettings.SplineBackwardsOffset = FollowSettings.LocationSplineBackwardsOffset;
		LocationSettings.FollowType = FollowSettings.FollowType;
		
		RotationSettings.RotationDuration = FollowSettings.RotationDuration;
		RotationSettings.RotationOffset = FollowSettings.RotationOffset;
		RotationSettings.SplineBackwardsOffset = FollowSettings.RotationSplineBackwardsOffset;
		RotationSettings.FollowType = FollowSettings.FollowType;
		RotationSettings.bUseSplineUpToRollCamera = FollowSettings.bUseSplineUpToRollCamera;
	}

	void InitUserInputSettings(FCameraSplineFollowUserInputSettings UserInputSettings)
	{
		InputSettings = UserInputSettings;
	}

	private bool ShouldUpdateBackwardsOffset() const
	{
		if(!SplineSettings.bWantsToAlignWithBackwardsOffset)
			return false;

		if(LocationSettings.Type == ECameraSplineLocationTargetType::PlaceAtTargetSplineLocation)
			return true;

		if(RotationSettings.Type == ECameraSplineRotationTargetType::SplineRotationAtFocusTargetSplineLocation)
			return true;

		if(RotationSettings.Type == ECameraSplineRotationTargetType::SideRotator)
			return true;

		if(RotationSettings.Type == ECameraSplineRotationTargetType::LookAtFocusTargetSplineLocation)
			return true;

		return false;
	}

	private void GenerateBackwardsViewOffsetDir(FVector UserLocation)
	{
		float SplineDistance = MainSpline.GetClosestSplineDistanceToWorldLocation(UserLocation);
		BackwardsOffsetDirection = GetBackWardsOffsetViewAlignment(MainSpline, SplineDistance);
	}

	void ApplyRuntimeOverrides(const UHazeCameraUserComponent User, USplineFollowCameraRuntimeSettingsComponent SettingsOverride)
	{
		SettingsOverride.GetLocationBackwardsOffsetOverride(User, LocationSettings.SplineBackwardsOffset);
		SettingsOverride.GetRotationBackwardsOffsetOverride(User, RotationSettings.SplineBackwardsOffset);
	}

	void ApplyFractionDetectionSpline(UHazeSplineComponent Spline)
	{
		SplineSettings.OptionalFractionSpline = Spline;
	}

	void ApplyManualFollowSplineFraction(float Value)
	{
		SplineSettings.ManualFollowFraction = Math::Clamp(Value, 0.0, 1.0);
	}

	void PlaceAtTargetLocation(FFocusTargets Targets)
	{
		LocationSettings.Type = ECameraSplineLocationTargetType::PlaceAtTargetLocation;
		LocationSettings.Targets = Targets;
	}

	void PlaceAtTargetSplineLocation(FFocusTargets Targets, float BackwardsOffset = -1)
	{
		LocationSettings.Type = ECameraSplineLocationTargetType::PlaceAtTargetSplineLocation;
		LocationSettings.Targets = Targets;
		if(BackwardsOffset >= 0)
			LocationSettings.SplineBackwardsOffset = BackwardsOffset;
	}

	void LookInSplineRotationAtFocusTargetSplineLocation(FFocusTargets Targets, bool bLockToHorizontalPlane = false, float BackwardsOffset = -1)
	{
		if(bLockToHorizontalPlane)
			RotationSettings.Type = ECameraSplineRotationTargetType::HorizontalSplineRotationAtFocusTargetSplineLocation;
		else
			RotationSettings.Type = ECameraSplineRotationTargetType::SplineRotationAtFocusTargetSplineLocation;

		RotationSettings.Targets = Targets;
		if(BackwardsOffset >= 0)
			RotationSettings.SplineBackwardsOffset = BackwardsOffset;
	}

	void LookAtFocusTarget(FFocusTargets Targets)
	{
		RotationSettings.Type = ECameraSplineRotationTargetType::LookAtFocusTarget;
		RotationSettings.Targets = Targets;
	}

	void LookAtFocusTargetSplineLocation(FFocusTargets Targets, float BackwardsOffset = -1)
	{
		RotationSettings.Type = ECameraSplineRotationTargetType::LookAtFocusTargetSplineLocation;
		RotationSettings.Targets = Targets;
		if(BackwardsOffset >= 0)
			RotationSettings.SplineBackwardsOffset = BackwardsOffset;
	}

	void UseAsSideRotator(FFocusTargets Targets, float SideScrollerCorridorWidth = -1)
	{
		RotationSettings.Type = ECameraSplineRotationTargetType::SideRotator;
		RotationSettings.Targets = Targets;
		RotationSettings.SideRotatorCorridorWidth = SideScrollerCorridorWidth;
	}

	void ApplyKeepInViewToLocation(const UHazeCameraUserComponent HazeUser, FFocusTargets PrimaryTargets = FFocusTargets())
	{	
		devCheck(LocationSettings.Type != ECameraSplineLocationTargetType::None, "ApplyKeepInViewToLocation must be called after a location type has been picked");

		KeepInViewSettings.Init(HazeUser);
		
		LocationSettings.PrimaryTargets = PrimaryTargets;
		LocationSettings.bKeepInView = true;
	}

	private void UpdateKeepInView(FTransform& TargetView, float DeltaSeconds)
	{
		// Location
		if(LocationSettings.bKeepInView && LocationSettings.Type != ECameraSplineLocationTargetType::None)
		{
			FVector NewLocation = SplineUserData.PreviousViewLocation.Value;
			KeepInViewSettings.GetTargetLocation(TargetView, CameraSettings, LocationSettings.Targets, LocationSettings.PrimaryTargets, NewLocation);	
			if(DeltaSeconds <= KINDA_SMALL_NUMBER || LocationSettings.MoveDuration <= KINDA_SMALL_NUMBER)
				SplineUserData.PreviousViewLocation.SnapTo(NewLocation);
			else
				SplineUserData.PreviousViewLocation.AccelerateTo(NewLocation, LocationSettings.MoveDuration, DeltaSeconds);

			NewLocation = SplineUserData.PreviousViewLocation.Value;
			SplineUserData.PreviousViewLocation.SnapTo(NewLocation);
			TargetView.SetLocation(NewLocation);
		}
	}

	private void UpdateSideRotator(FTransform& TargetView, float DeltaSeconds)
	{
		if(RotationSettings.Type != ECameraSplineRotationTargetType::SideRotator)
			return;

		if (RotationSettings.Targets.Num() < 2)
			return;

		float CorridorWidth = RotationSettings.SideRotatorCorridorWidth;
		if(CorridorWidth < 0)
			CorridorWidth = CameraTraceParams.ProbeSize;
		if(CorridorWidth < 0)
			CorridorWidth = 400;

		FRotator GuideRotation = TargetView.Rotator();
		// Use weighted average of all directions between focus targets 
		FVector SideDir = FVector::ZeroVector;
		FVector GuideDir = GuideRotation.Vector();
		for (int i = 0; i < RotationSettings.Targets.Num() - 1; i++)
		{
			FVector From = RotationSettings.Targets[i].Location;
			for (int j = i + 1; j < RotationSettings.Targets.Num(); j++)
			{
				// Reduce vector between the focus points with up to corridor width in the guide direction
				FVector To = RotationSettings.Targets[j].Location;
				FVector Delta = (To - From);
				float GuideDot = GuideDir.DotProduct(Delta);
				FVector WithinCorridorDelta = Delta - GuideDir * Math::Sign(GuideDot) * Math::Min(CorridorWidth, Math::Abs(GuideDot));
				FVector Dir = WithinCorridorDelta.GetSafeNormal();
				SideDir	+= Dir * RotationSettings.Targets[i].Weight * RotationSettings.Targets[j].Weight;
			}
		}

		// We should be facing orthogonal of side direction
		FVector TargetDir = SideDir.CrossProduct(YawAxis); 

		// We normally want to follow on the outside or the inside of some wall, so make sure we're aligned with guide rotation
		if (TargetDir.DotProduct(GuideRotation.Vector()) < 0.0)
			TargetDir *= -1.0;

		FRotator TargetRot = TargetDir.Rotation();
		FRotator LocalPitchRotation = FRotator(WorldToLocalRotation(GuideRotation).Pitch, 0.0, 0.0);
		TargetView.SetRotation(LocalPitchRotation.Compose(TargetRot));
	}

	private FVector UpdateViewLocation(float SplineLength, float DeltaSeconds, FTransform TargetView)
	{
		// Location
		const FVector ViewLocation = TargetView.Location;
		FVector NewTargetLocation = ViewLocation;
		float Duration = LocationSettings.MoveDuration;
		
		// If we have a keep in view, we snap the location to the spline
		// since the keep in view will instead update the location using duration
		if(LocationSettings.bKeepInView)
			Duration = 0;
		
		FRotator TargetRotation = TargetView.Rotator();
		const float BackwardsOffset = LocationSettings.SplineBackwardsOffset;
		const ESplineFollowerType FollowType = LocationSettings.FollowType;
		if(LocationSettings.Type == ECameraSplineLocationTargetType::PlaceAtTargetSplineLocation)
		{
			// place the camera location on the spline for the focus target
			const float TargetDistanceAlongSpline = GetTargetDistance(ViewLocation, SplineUserData.PreviousSplinePositionDistance, SplineLength, BackwardsOffset, LocationSettings.Targets, FollowType);
			FSplinePosition SplinePosition = UpdateSplineDistance(SplineUserData.PreviousSplinePositionDistance, DeltaSeconds, TargetDistanceAlongSpline, SplineLength, Duration);
			NewTargetLocation = SplinePosition.WorldLocation;
			TargetRotation = SplinePosition.WorldRotation.Rotator();

			// The keep in view will update the previous location
			if(!LocationSettings.bKeepInView)
				SplineUserData.PreviousViewLocation.SnapTo(NewTargetLocation);
		}
		else if(LocationSettings.Type == ECameraSplineLocationTargetType::PlaceAtTargetLocation)
		{
			// place the camera on the focus target
			NewTargetLocation = LocationSettings.Targets.GetFocusLocation(ViewLocation);
			LocationSettings.Targets.GetFocusRotation(ViewLocation, TargetRotation);
			
			// The keep in view will update the previous location
			if(!LocationSettings.bKeepInView)
			{
				if(Duration > KINDA_SMALL_NUMBER && DeltaSeconds > 0)
					NewTargetLocation = SplineUserData.PreviousViewLocation.AccelerateTo(NewTargetLocation, Duration, DeltaSeconds);
				else
					SplineUserData.PreviousViewLocation.SnapTo(NewTargetLocation);
			}
		}

		FRotator OffsetRotation = FRotator::MakeFromXZ(TargetRotation.ForwardVector * BackwardsOffsetDirection, TargetRotation.UpVector);
		NewTargetLocation += OffsetRotation.RotateVector(LocationSettings.LocationOffset);
		return NewTargetLocation;
	}

	private FQuat UpdateViewRotation(float SplineLength, float DeltaSeconds, FTransform TargetView)
	{
		FQuat NewTargetRotation = TargetView.Rotation;
		if(RotationSettings.Type == ECameraSplineRotationTargetType::None)
			return NewTargetRotation;

		const float Duration = RotationSettings.RotationDuration;
		const float BackwardsOffset = RotationSettings.SplineBackwardsOffset;
		const ESplineFollowerType FollowType = RotationSettings.FollowType;

		if(RotationSettings.Type == ECameraSplineRotationTargetType::LookAtFocusTargetSplineLocation)
		{
			// Focus the view on the target position on the spline
			const float TargetDistanceAlongSpline = GetTargetDistance(TargetView.Location, SplineUserData.PreviousSplineRotationDistance, SplineLength, BackwardsOffset, RotationSettings.Targets, FollowType);
			FSplinePosition SplinePosition = UpdateSplineDistance(SplineUserData.PreviousSplineRotationDistance, DeltaSeconds, TargetDistanceAlongSpline, SplineLength, Duration);
			
			FVector Forward = (SplinePosition.WorldLocation - TargetView.Location).GetSafeNormal();
			if(!Forward.IsNearlyZero())
			{
				NewTargetRotation = FQuat::MakeFromZX(YawAxis, Forward);
			}
		}
		if(RotationSettings.Type == ECameraSplineRotationTargetType::LookAtFocusTarget)
		{
			FRotator TargetRotation;
			RotationSettings.Targets.GetFocusRotation(TargetView.Location, TargetRotation);
			NewTargetRotation = TargetRotation.Quaternion();
		}
		else if(RotationSettings.Type == ECameraSplineRotationTargetType::SideRotator)
		{
			// Focus the view on the target position
			const float TargetDistanceAlongSpline = GetTargetDistance(TargetView.Location, SplineUserData.PreviousSplineRotationDistance, SplineLength, BackwardsOffset, RotationSettings.Targets, FollowType);
			FSplinePosition SplinePosition = UpdateSplineDistance(SplineUserData.PreviousSplineRotationDistance, DeltaSeconds, TargetDistanceAlongSpline, SplineLength, Duration);
			
			FRotator TargetRotation;
			RotationSettings.Targets.GetFocusRotation(SplinePosition.WorldLocation, TargetRotation);
			NewTargetRotation = TargetRotation.Quaternion();
		}
		else if(RotationSettings.Type == ECameraSplineRotationTargetType::SplineRotationAtFocusTargetSplineLocation)
		{
			// Use the spline rotation at the rotation focus position
			const float TargetDistanceAlongSpline = GetTargetDistance(TargetView.Location, SplineUserData.PreviousSplineRotationDistance, SplineLength, BackwardsOffset, RotationSettings.Targets, FollowType);
			FSplinePosition SplinePosition = UpdateSplineDistance(SplineUserData.PreviousSplineRotationDistance, DeltaSeconds, TargetDistanceAlongSpline, SplineLength, Duration);
			NewTargetRotation = FQuat::MakeFromXZ(SplinePosition.WorldForwardVector, YawAxis);
		}
		else if(RotationSettings.Type == ECameraSplineRotationTargetType::HorizontalSplineRotationAtFocusTargetSplineLocation)
		{
			// Use the spline rotation at the rotation focus position
			const float TargetDistanceAlongSpline = GetTargetDistance(TargetView.Location, SplineUserData.PreviousSplineRotationDistance, SplineLength, BackwardsOffset, RotationSettings.Targets, FollowType);
			FSplinePosition SplinePosition = UpdateSplineDistance(SplineUserData.PreviousSplineRotationDistance, DeltaSeconds, TargetDistanceAlongSpline, SplineLength, Duration);
			NewTargetRotation = FQuat::MakeFromZX(YawAxis, SplinePosition.WorldForwardVector);
		}

		NewTargetRotation *= RotationSettings.RotationOffset.Quaternion();
		return NewTargetRotation;
	}

	protected FRotator GetFinalSplineFollowWorldRotation(FTransform TargetView, float DeltaTime)
	{
		FRotator TargetRotation = ClampWorldRotation(TargetView.Rotator());

		// Align yaw axis with spline's up vector
		if (RotationSettings.bUseSplineUpToRollCamera)
		{
			const float TargetDistanceAlongSpline = GetTargetDistance(TargetView.Location, SplineUserData.PreviousSplineRotationDistance, MainSpline.SplineLength, RotationSettings.SplineBackwardsOffset, RotationSettings.Targets, RotationSettings.FollowType);
			UpdateSplineDistance(SplineUserData.PreviousSplineRotationDistance, DeltaTime, TargetDistanceAlongSpline, MainSpline.SplineLength, RotationSettings.RotationDuration);

			FRotator RelativeRotation = WorldToLocalRotation(TargetRotation);
			FQuat RelativeSplineRotation = MainSpline.GetRelativeRotationAtSplineDistance(SplineUserData.PreviousSplinePositionDistance.Value);

			RelativeRotation = FRotator::MakeFromXZ(RelativeRotation.ForwardVector, RelativeSplineRotation.AxisZ);
			TargetRotation = LocalToWorldRotation(RelativeRotation);
		}

		// The spline might have a separate rotation speed
		// If so, apply that here to the target rotation 
		if(RotationSettings.RotationDuration > KINDA_SMALL_NUMBER && DeltaTime > 0)
		{
			SplineUserData.PreviousViewRotation.AccelerateTo(TargetRotation, RotationSettings.RotationDuration, DeltaTime);
		}
		else
		{
			SplineUserData.PreviousViewRotation.SnapTo(TargetRotation);
		}

		return SplineUserData.PreviousViewRotation.Value;
	}

	private FSplinePosition UpdateSplineDistance(FHazeAcceleratedFloat& CurrentDistance, float DeltaSeconds, float TargetDistance, float SplineLength, float Duration) const
	{	
		if(DeltaSeconds < KINDA_SMALL_NUMBER || Duration < KINDA_SMALL_NUMBER)
		{
			CurrentDistance.SnapTo(TargetDistance);
		}
		else
		{
			CurrentDistance.AccelerateTo(TargetDistance, Duration, DeltaSeconds);  
		}

		// In case of looping spline, we might need to wrap the result
		if (CurrentDistance.Value < 0.0)
			CurrentDistance.Value += SplineLength;
		if (CurrentDistance.Value > SplineLength)
			CurrentDistance.Value -= SplineLength;
		
		return MainSpline.GetSplinePositionAtSplineDistance(CurrentDistance.Value);
	}

	private float GetTargetDistance(FVector ViewTargetLocation, FHazeAcceleratedFloat PreviousSplineDistance, float SplineLength, float BackwardsOffset, FFocusTargets Targets, ESplineFollowerType FollowType) const
	{
		const bool bIsClosedLoop = MainSpline.IsClosedLoop();

		float FollowFraction = SplineSettings.ManualFollowFraction;
		if(FollowFraction < 0)
		{
			FollowFraction = GetFollowFraction(
				SplineSettings.OptionalFractionSpline != nullptr ? SplineSettings.OptionalFractionSpline : SplineSettings.ActiveSpline, 
				ViewTargetLocation,
				Targets,
				FollowType);
		}

		float TargetDistanceAlongSpline = GetTargetDistanceAlongSpline(
				MainSpline, 
				FollowFraction,
				BackwardsOffset);
		
		const float CurrentDistanceAlongSpline = PreviousSplineDistance.Value;

		// Clamp distance along spline if camera is not allowed to move backwards
		if (!SplineSettings.bCanMoveBackwards)
			TargetDistanceAlongSpline = Math::Max(CurrentDistanceAlongSpline, TargetDistanceAlongSpline);

		if (bIsClosedLoop && (Math::Abs(TargetDistanceAlongSpline - CurrentDistanceAlongSpline) > SplineLength * 0.5))
		{
			// Looping past start/end if shorter than the other way around
			if (CurrentDistanceAlongSpline > SplineLength * 0.5)
				TargetDistanceAlongSpline += SplineLength;
			else
				TargetDistanceAlongSpline -= SplineLength;
		}

		return TargetDistanceAlongSpline;
	}

	float GetTargetDistanceAlongSpline(UHazeSplineComponent Spline, float FollowFraction, float BackwardsOffset) const
	{
		if (Spline == nullptr)
			return 0;
		
		const float SplineLength = Spline.GetSplineLength();
		if (SplineLength <= 0)
			return 0.0;

		float TargetDistance = FollowFraction * SplineLength;
		TargetDistance -= (BackwardsOffset * BackwardsOffsetDirection);

		if (!Spline.IsClosedLoop())
			TargetDistance = Math::Clamp(TargetDistance, 1.0, SplineLength - 1);

		return TargetDistance;
	}

	float GetFollowFraction(UHazeSplineComponent Spline, FVector BaseLocation, FFocusTargets FollowTargets, ESplineFollowerType FollowType) const
	{
		if (Spline == nullptr)
			return 0;

		const float SplineLength = Spline.GetSplineLength();
		if (SplineLength <= 0)
			return 0.0;

		float GuideDistance = 0.0;
		switch (FollowType)
		{
			case ESplineFollowerType::Foremost:
				GuideDistance = GetForemostGuideDistance(Spline, FollowTargets);
				break;
			case ESplineFollowerType::Rearmost:
				GuideDistance = GetRearmostGuideDistance(Spline, FollowTargets);
				break;
			case ESplineFollowerType::Weighted:
				GuideDistance =	GetWeightedGuideDistance(Spline, BaseLocation, FollowTargets);
				break;
			case ESplineFollowerType::IndividuallyWeighted:
				GuideDistance =	GetIndividuallyWeightedGuideDistance(Spline, FollowTargets);
				break;
		} 

		return GuideDistance / SplineLength;
	}

	void SetUsingGamepad(bool bValue)
	{
		InputData.bIsUsingGamepad = bValue;
	}

	private float GetWeightedGuideDistance(UHazeSplineComponent Spline, FVector BaseLocation, FFocusTargets FollowTargets) const
	{	
		FVector FocusOffset = FVector::ZeroVector;
		FVector LocationSum = FVector::ZeroVector;

		for (auto FollowTarget : FollowTargets.Targets)
		{
			FVector FocusLoc = FollowTarget.Location;
			float Weight = FollowTarget.Weight;
			FocusOffset += ((FocusLoc - BaseLocation) * Weight);
		}

		LocationSum = BaseLocation + FocusOffset;
		return Spline.GetClosestSplineDistanceToWorldLocation(LocationSum);
	}

	private float GetIndividuallyWeightedGuideDistance(UHazeSplineComponent Spline, FFocusTargets Targets) const
	{
		float WeightSum = 0.0;
		float DistanceAlongSplineSum = 0.0;
		for (auto FollowTarget : Targets.Targets)
		{
			FVector FollowLoc = FollowTarget.Location;
			float DistAlongSpline = Spline.GetClosestSplineDistanceToWorldLocation(FollowLoc);
			
			// Hack fix for two equal weight targets, need testing for general case
			if (Spline.IsClosedLoop() && (WeightSum > 0.0))
			{
				float Delta = (DistanceAlongSplineSum / WeightSum) - DistAlongSpline;

				if (Math::Abs(Delta) > Spline.SplineLength * 0.5)
				{
					DistAlongSpline += Math::Sign(Delta) * Spline.SplineLength;
				}
			}

			DistanceAlongSplineSum += DistAlongSpline * FollowTarget.Weight;
			WeightSum += FollowTarget.Weight;
		}

		if (WeightSum == 0.0)
			return 0.0;
		return DistanceAlongSplineSum / WeightSum;
	}

	private float GetForemostGuideDistance(UHazeSplineComponent Spline, FFocusTargets FollowTargets) const
	{
		float ForemostDistance = 0.0;
		for (auto FollowTarget : FollowTargets.Targets)
		{
			FVector FollowLoc = FollowTarget.Location;
			float Distance = Spline.GetClosestSplineDistanceToWorldLocation(FollowLoc);
			if (Distance > ForemostDistance)
				ForemostDistance = Distance;
		}
		return ForemostDistance;
	}

	private float GetRearmostGuideDistance(UHazeSplineComponent Spline, FFocusTargets FollowTargets) const
	{
		float RearmostDistance = Spline.SplineLength;
		for (auto FollowTarget : FollowTargets.Targets)
		{
			FVector FollowLoc = FollowTarget.Location;
			float Distance = Spline.GetClosestSplineDistanceToWorldLocation(FollowLoc);
			if (Distance < RearmostDistance)
				RearmostDistance = Distance;
		}
		return RearmostDistance;
	}

	private float GetBackWardsOffsetViewAlignment(UHazeSplineComponent Spline, float DistAlongSpline) const
	{
		FVector SplineTangent = Spline.GetWorldTangentAtSplineDistance(DistAlongSpline);
		FVector ViewDir = SplineSettings.CurrentViewRotation.Vector();
		float Angle = Math::Abs(FRotator::NormalizeAxis(SplineSettings.AlignBackwardsOffsetAngle));
		float AlignDegrees = Math::GetMappedRangeValueClamped(FVector2D(0.0, Spline.SplineLength), FVector2D(Angle, 180.0 - Angle), DistAlongSpline);
		if (ViewDir.DotProduct(SplineTangent.GetSafeNormal()) < Math::Cos(Math::DegreesToRadians(AlignDegrees)))
			return -1.0;
		return 1.0;
	}

	private UHazeSplineComponent GetMainSpline() const property
	{
		return SplineSettings.ActiveSpline;
	}
}
