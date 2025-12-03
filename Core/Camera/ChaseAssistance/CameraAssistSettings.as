
class UPlayerCameraAssistSettings : UHazeComposableSettings
{
	// Validate the physics state when settings the chase assist strength
	UPROPERTY(Category = "Assist")
	bool bUpdateChaseAssistBasedOnPhysicsStateType = true;

	// Validate contextual targetables when settings the chase assist strength
	UPROPERTY(Category = "Assist")
	bool bUpdateChaseAssistBasedOnContextualTargetType = true;

	// If the chase should stop if I look up for some reason
	UPROPERTY(Category = "Assist")
	bool bUpdateChaseAssistBasedOnPitch = false;

	// Validate aiming when settings the chase assist strength
	UPROPERTY(Category = "Assist")
	bool bUpdateChaseBasedOnAiming = true;

	/** 
	 * How long it will take to return to full assist after input is given
	 * This can be modified by the 'CameraAssistMultiplierAfterInput'
	*/
	UPROPERTY(Category = "Assist")
	float CameraAssistRegainAfterInputTime = 1.5;

	/**
	 * How much assist should be applied after input is given.
	 * @Time; 0 -> 1 where 1 is 'CameraAssistRegainAfterInputTime'
	 * @Alpha; 0 -> 1
	 */
	UPROPERTY(Category = "Assist")
	FRuntimeFloatCurve CameraAssistMultiplierAfterInput;	
	default CameraAssistMultiplierAfterInput.AddDefaultKey(0, 0);
	default CameraAssistMultiplierAfterInput.AddDefaultKey(0.7, 0);
	default CameraAssistMultiplierAfterInput.AddDefaultKey(1, 1);

	/**
	 * These were previously on the asset type
	 */

	// How fast we rotate
	UPROPERTY(Category = "Assist")
	float RotationSpeed = 100;

	// At what user movement velocity do we reach alpha 1
	UPROPERTY(Category = "Assist")
	float MaxUserVelocity = 100;

	/** How much should we be facing the wanted movement direction (0 -> 1)
	 * This is used when the player is moving towards the camera view direction
	 * @Time; 1, we are moving 100% forward in the cameras left/right view direction
	 */
	UPROPERTY(Category = "Assist")
	FRuntimeFloatCurve ForwardMovementMultiplier;
	default ForwardMovementMultiplier.AddDefaultKey(1, 1);
	default ForwardMovementMultiplier.AddDefaultKey(0, 0);

	/** How much should we be facing the wanted movement direction (0 -> 1)
	 * This is used when the player is moving backwards in the camera view direction
	 * @Time; 1, we are moving 100% forward in the cameras left/right view direction
	 */
	UPROPERTY(Category = "Assist")
	FRuntimeFloatCurve BackwardMovementMultiplier;
	default BackwardMovementMultiplier.AddDefaultKey(1, 1);
	default BackwardMovementMultiplier.AddDefaultKey(0, 0);

	/**
	 * New Settings
	 */

	// Validate the pitch amount when settings the chase assist strength
	UPROPERTY(Category = "New")
	bool bUpdateChaseAssistBasedOnPitchWithUpwardsCutoff = false;

	/** 
	 * How long it will take to return to full assist after movement input is given
	*/
	UPROPERTY(Category = "New")
	float RegainAfterMovingTime = 0;

	UPROPERTY(Category = "New")
	bool bResetRotateSpeedOnInputStop = true;

	UPROPERTY(Category = "New")
	float RegainAfterInputStopDelay = 0.5;

	UPROPERTY(Category = "New|Yaw")
	bool bRequireMovementInput = true;

	UPROPERTY(Category = "New|Yaw")
	bool bYawResetRotateSpeedOnActivate = true;

	UPROPERTY(Category = "New|Yaw")
	bool bYawResetRotateSpeedOnInput = true;

	UPROPERTY(Category = "New|Yaw")
	float YawIncreaseRotationSpeedDuration = 3.0;

	UPROPERTY(Category = "New|Yaw")
	float YawDecreaseRotationSpeedDuration = 1.0;

	UPROPERTY(Category = "New|Yaw")
	float YawStopRotationSpeedDuration = 0.25;

	/**
	 * When changing direction, do we want to stop?
	 * If > 0, we slow down to a full stop over a duration
	 * If == 0, we immediately stop
	 * If < 0, this is disabled
	 */
	UPROPERTY(Category = "New|Yaw")
	float YawSwitchDirectionStopDuration = -1;
	
	/**
	 * Turn off to completely disable pitch assist
	 */
	UPROPERTY(Category = "New|Pitch")
	bool bApplyPitch = true;

	UPROPERTY(Category = "New|Pitch")
	bool bPitchResetRotateSpeedOnActivate = true;

	UPROPERTY(Category = "New|Pitch")
	float WorldUpAccelerateDuration = 0.3;

	UPROPERTY(Category = "New|Pitch")
	float GroundNormalAccelerateDuration = 0.5;

	/**
	 * How long it takes for the pitch assist to reach the target speed while accelerating
	 */
	UPROPERTY(Category = "New|Pitch")
	float PitchIncreaseRotationSpeedDuration = 2.0;

	/**
	 * How long it takes for the pitch assist to reach the target speed while decelerating
	 */
	UPROPERTY(Category = "New|Pitch")
	float PitchDecreaseRotationSpeedDuration = 0.5;

	/**
	 * How long it takes for the pitch assist to reach the target speed while accelerating
	 */
	UPROPERTY(Category = "New|Pitch")
	float PitchStopRotationSpeedDuration = 0.25;

	/**
	 * Should the pitch assist adjust itself for slopes?
	 */
	UPROPERTY(Category = "New|Pitch")
	bool bFollowSlopes = true;

	UPROPERTY(Category = "New|Pitch")
	float FollowSlopeSpeed = 0.2;

	/**
	 * If the player is looking up at the ceiling, but then starts running, should the camera start pitching down do show the floor again?
	 */
	UPROPERTY(Category = "New|Pitch")
	bool bPitchDownFromRunForwardWhenCameraPitchedUp = true;

	UPROPERTY(Category = "New|Pitch")
	float PitchDownFromRunStartInputDelay = 0.5;

	UPROPERTY(Category = "New|Pitch")
	float PitchDownFromRunStartAngle = 40.0;

	UPROPERTY(Category = "New|Pitch")
	float PitchDownFromRunStartForwardVelocity = 300.0;

	UPROPERTY(Category = "New|Pitch")
	float PitchDownFromRunTargetAngle = 30.0;

	UPROPERTY(Category = "New|Pitch")
	float PitchDownFromRunRotationSpeed = 10.0;


	UPROPERTY(Category = "New|Pitch")
	bool bPitchUpFromRunForwardWhenCameraPitchedDown = true;

	UPROPERTY(Category = "New|Pitch")
	float PitchUpFromRunStartInputDelay = 0.5;

	UPROPERTY(Category = "New|Pitch")
	float PitchUpFromRunStartAngle = -45.0;

	UPROPERTY(Category = "New|Pitch")
	float PitchUpFromRunStartForwardVelocity = 300.0;

	UPROPERTY(Category = "New|Pitch")
	float PitchUpFromRunTargetAngle = -40.0;

	UPROPERTY(Category = "New|Pitch")
	float PitchUpFromRunRotationSpeed = 10.0;
};

UCLASS(Abstract)
class UCameraAssistType : UDataAsset
{
	void Apply(float DeltaTime, float ScriptMultiplier, FCameraAssistSettingsData Settings, FHazeActiveCameraAssistData& Data, FHazeCameraTransform& OutResult) const
	{

	}
}

struct FCameraAssistSettingsData
{
	UCameraAssistType AssistType;
	
	FVector CurrentViewLocation = FVector::ZeroVector;
	FRotator CurrentViewRotation = FRotator::ZeroRotator;
	
	FVector2D CameraInput;
	FVector2D MovementInputRaw;
	float InputSensitivity = 1;
	float FollowSensitivity = 0.5;

	FVector UserVelocity;
	FVector UserWorldUp;

	float InputMultiplier = 1;
	float ContextualMultiplier = 1;
	float ActiveDuration = 0;

	/**
	 * New
	 */

	bool bApplyYaw = true;
	bool bApplyPitch = true;

	UPlayerCameraAssistSettings Settings;
	UCameraUserSettings CameraUserSettings;

	float LastCameraInputTime;
	float LastNoCameraInputTime;
	uint LastCameraInputFrame;

	float LastMovementInputTime;
	float LastNoMovementInputTime;

	// Rotation with Z being Yaw Axis and X being View forward
	FRotator ControlRotation = FRotator::ZeroRotator;

	FVector LocalUserVelocity;
	FRotator LocalUserRotation;
	FVector LocalUserWorldUp;

	FRotator LocalViewRotation;
	FVector LocalVerticalAxis;

	bool bIsGrounded = false;
	FVector VerticalAxis;
}

struct FHazeActiveCameraAssistData
{
	FHazeAcceleratedRotator DesiredRotation;

	FHazeAcceleratedFloat YawRotationSpeed;
	float YawSwitchDirectionTime = -1;

	FHazeAcceleratedFloat PitchRotationSpeed;
	bool bIsPitchingDownFromRun = false;
	bool bIsPitchingUpFromRun = false;

	void ResetYaw()
	{
		YawRotationSpeed.SnapTo(0);
		YawSwitchDirectionTime = -1;
	}

	void ResetPitch()
	{
		PitchRotationSpeed.SnapTo(0);
		bIsPitchingDownFromRun = false;
		bIsPitchingUpFromRun = false;
	}

	bool IsDirty() const
	{
		if (YawRotationSpeed.Value != 0)
			return true;

		if (PitchRotationSpeed.Value != 0)
			return true;

		if(bIsPitchingDownFromRun)
			return true;

		if(bIsPitchingUpFromRun)
			return true;

		return false;
	}
}