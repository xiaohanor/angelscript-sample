struct FGravityBikeFreeQuarterPipeRelativeToSplineData
{
	uint FrameNumber;
	AGravityBikeFreeQuarterPipeSplineActor Spline;
	FTransform RelativeTransform;

	void Reset()
	{
		FrameNumber = 0;
		Spline = nullptr;
		RelativeTransform = FTransform::Identity;
	}

	#if EDITOR
	void WriteToTemporalLog(FTemporalLog& TemporalLog, FString Prefix) const
	{
		TemporalLog.Value(f"{Prefix};Frame Number", FrameNumber);
		TemporalLog.Value(f"{Prefix};Spline", Spline);
		TemporalLog.Value(f"{Prefix};RelativeTransform", RelativeTransform);
	}
	#endif
}

UCLASS(Abstract)
class UGravityBikeFreeQuarterPipeComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	FGravityBikeFreeQuarterPipeJumpData JumpData;
	FGravityBikeFreeQuarterPipeRelativeToSplineData RelativeData;

	FVector InitialVelocity;
	private FHazeAcceleratedQuat AccRotation;
	private uint AppliedRotationFrame = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		TemporalLog.Value("Initial Velocity", InitialVelocity);
		TemporalLog.Value("AccRotation;Value", AccRotation.Value);
		TemporalLog.Value("AccRotation;Velocity", AccRotation.VelocityAxisAngle);
		TemporalLog.Value("AppliedRotationFrame", AppliedRotationFrame);

		JumpData.WriteToTemporalLog(TemporalLog, "Jump Data");
		RelativeData.WriteToTemporalLog(TemporalLog, "Relative Data");
	}
	#endif

	void Reset()
	{
		JumpData.Invalidate();

		AccRotation.SnapTo(FQuat::Identity);
		AppliedRotationFrame = 0;
	}

	bool IsJumping() const
	{
		return JumpData.IsValid() && !JumpData.HasLanded();
	}

	bool IsVertical() const
	{
		if(!IsJumping())
			return false;

		const float InitialVerticalSpeed = InitialVelocity.DotProduct(FVector::UpVector);
		if(InitialVerticalSpeed < 3000)
			return false;

		if(Math::Abs(JumpData.HorizontalSpeed) > 2000)
			return false;

		return true;
	}

	void RotationSnapTo(FQuat Target, FVector VelocityAxis = FVector::UpVector, float VelocityAngleDegrees = 0.0)
	{
		AccRotation.SnapTo(Target, VelocityAxis, VelocityAngleDegrees);
	}

	void ApplyRotationAccelerateTo(FQuat Target, float Duration, float DeltaTime)
	{
		check(!HasAppliedRotation());
		AccRotation.AccelerateTo(Target, Duration, DeltaTime);
		AppliedRotationFrame = Time::FrameNumber;
	}

	FQuat GetRotation() const
	{
		return AccRotation.Value;
	}

	bool HasAppliedRotation() const
	{
		if(!IsJumping())
			return false;

		return AppliedRotationFrame == Time::FrameNumber;
	}
};