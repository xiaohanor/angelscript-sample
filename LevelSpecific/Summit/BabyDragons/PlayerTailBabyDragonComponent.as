
enum ETailBabyDragonClimbState
{
	None,
	Enter,
	Hang,
	Transfer,
};

enum ETailBabyDragonZiplineState
{
	None,
	Enter,
	Follow,
};

enum ETailBabyDragonAnimationState
{
	Idle,
	ClimbEnterGrounded,
	ClimbEnterAirborne,
	ClimbHang,
	ClimbReach,
	ClimbJumpTransfer,
	ClimbExitJumpOff,
	ZiplineEnter,
	ZiplineFollow,
};

class UPlayerTailBabyDragonComponent : UPlayerBabyDragonComponent
{
	// * Animation
	TInstigated<ETailBabyDragonAnimationState> AnimationState;
	default AnimationState.DefaultValue = ETailBabyDragonAnimationState::Idle;

	FRotator AnimationClimbDirection;

	// * Tail Climbing
	private TInstigated<ETailBabyDragonClimbState> ClimbStateInternal;
	default ClimbStateInternal.DefaultValue = ETailBabyDragonClimbState::None;

	UBabyDragonTailClimbTargetable ClimbActivePoint;
	float LastHangGameTime = -1.0;

	bool bClimbReachedPoint = false;
	bool bClimbCancelledExternally = false;
	float ClimbBonusTrace = 0;
	UPrimitiveComponent AttachmentComponent;

	bool bTriggerLaunchForce = false;
	FVector ClimbLaunchForce;
	FVector PreviousClimbLaunchForce; // Used by audio, ClimbLaunchForce is cleared before its use
	bool bInvertTailClimbLaunchForce = true;
	float NextAutomaticReTriggerTime = 0;
	FVector AttachNormal;
	bool bUseClimbingCamera = false;
	bool bDisableWallStickInitially = false;

	UPROPERTY()
	UHazeCameraSettingsDataAsset ClimbCameraSettings;

	// * Ziplining
	ETailBabyDragonZiplineState ZiplineState = ETailBabyDragonZiplineState::None;
	bool bZiplineReachedLine = false;
	ABabyDragonZiplinePoint ZiplineActivePoint;
	FSplinePosition ZiplinePosition;

	UPROPERTY()
	UHazeCameraSettingsDataAsset ZiplineCameraSettings;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ZiplineCameraShake;

	UPROPERTY()
	UForceFeedbackEffect ZiplineRumble;

	// Relative location of the end of the tail to its start
	FVector RelativeTailEndLocation;

	UPROPERTY()
	TSubclassOf<UCrosshairWidget> GrabCrosshair;

	UPROPERTY()
	TSubclassOf<UTargetableWidget> ClimbEnterTargetableWidget;

	UPROPERTY()
	TSubclassOf<UTargetableWidget> ClimbTransferTargetableWidget;

	UPROPERTY()
	TSubclassOf<UTargetableWidget> ZiplineTargetableWidget;

	UPROPERTY()
	UForceFeedbackEffect ClimbAttachRumble;

	UPROPERTY()
	UForceFeedbackEffect ClimbLaunchRumble;

	TOptional<ABabyDragonTailClimbFreeFormHorizontalLockVolume> HorizontalLockVolume;

	FTransform GetTailStartTransform() const property
	{
		FTransform SocketTransform = BabyDragon.Mesh.GetSocketTransform(n"Tail13");
		return SocketTransform;
	}

	FVector GetTailEndLocation() const property
	{
		return GetTailStartTransform().TransformPosition(RelativeTailEndLocation);
	}

	UFUNCTION(BlueprintPure)
	ETailBabyDragonClimbState GetClimbState() const property
	{
		return ClimbStateInternal.Get();
	} 

	void SetClimbState(ETailBabyDragonClimbState NewState) property
	{
		ClimbStateInternal.Apply(NewState, this, EInstigatePriority::Low);
	} 

	void ApplyClimbState(ETailBabyDragonClimbState NewState, FInstigator Instigator, EInstigatePriority Priority) 
	{
		ClimbStateInternal.Apply(NewState, Instigator, Priority);
	} 

	void ClearClimbStateInstigator(FInstigator Instigator) 
	{
		ClimbStateInternal.Clear(Instigator);
	} 

	UFUNCTION(BlueprintPure)
	float GetLaunchForceSpeed()
	{
		return PreviousClimbLaunchForce.Size();
	}
};