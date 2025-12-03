enum EGravityBikeFreeHalfPipeRotationState
{
	None,

	BackFlip,
	Aim,
	Land,
}

UCLASS(Abstract)
class UGravityBikeFreeHalfPipeComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditDefaultsOnly)
	UGravityBikeFreeHalfPipeSettings DefaultSettings;

	AGravityBikeFree GravityBike;

	FGravityBikeFreeHalfPipeJumpData JumpData; 

	bool bIsJumping;
	EGravityBikeFreeHalfPipeRotationState RotationState;
	float Speed;
	float DistanceAlongTrajectory;
	FHazeAcceleratedQuat AccRotation;
	FHazeAcceleratedVector AccYawAxis;

	UGravityBikeFreeHalfPipeSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		
		Settings = UGravityBikeFreeHalfPipeSettings::GetSettings(GravityBike);
		GravityBike.ApplyDefaultSettings(DefaultSettings);
	}

	void Reset()
	{
		JumpData.Invalidate();

		bIsJumping = false;
		RotationState = EGravityBikeFreeHalfPipeRotationState::None;
		Speed = 0;
		DistanceAlongTrajectory = 0;
		AccRotation.SnapTo(FQuat::Identity);
		AccYawAxis.SnapTo(FVector::UpVector);
	}

	float GetJumpAlpha() const
	{
		return DistanceAlongTrajectory / JumpData.JumpTrajectoryDistance;
	}
};