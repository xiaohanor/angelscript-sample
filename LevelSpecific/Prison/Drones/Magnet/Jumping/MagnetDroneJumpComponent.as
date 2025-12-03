namespace MagnetDroneTags
{
	const FName BlockedWhileJumping = n"BlockedWhileJumping";
}

UCLASS(NotBlueprintable)
class UMagnetDroneJumpComponent : UActorComponent
{
	private AHazePlayerCharacter Player;
	private UHazeMovementComponent MoveComp;
	private UMagnetDroneComponent DroneComp;

	// Input
	bool bIsInputtingJump = false;
	uint StartJumpInputFrame = 0;
	float StartJumpInputTime = -BIG_NUMBER;

	private FInstigator CurrentJumpInstigator;
	private bool bIsJumping = false;
	private uint StartJumpingFrame = 0;
	private float StartJumpingTime = 0;
	private FVector JumpDir;
	private uint StopJumpingFrame = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
		DroneComp = UMagnetDroneComponent::Get(Player);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "MagnetDroneJump");
#endif
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("Input;bIsInputtingJump", bIsInputtingJump);
		TemporalLog.Value("Input;StartJumpInputFrame", StartJumpInputFrame);
		TemporalLog.Value("Input;StartJumpInputTime", StartJumpInputTime);

		TemporalLog.Value("Jump;CurrentJumpInstigator", CurrentJumpInstigator);
		TemporalLog.Value("Jump;bIsJumping", bIsJumping);
		TemporalLog.Value("Jump;StartJumpingFrame", StartJumpingFrame);
		TemporalLog.Value("Jump;StartJumpingTime", StartJumpingTime);
		TemporalLog.DirectionalArrow("Jump;JumpDir", Player.ActorLocation, JumpDir);
	}
	#endif

	bool WasJumpInputStartedThisFrame() const
	{
		return StartJumpInputFrame == Time::FrameNumber;
	}

	bool WasJumpInputStartedDuringTime(float Time) const
	{
		return Time::GetGameTimeSince(StartJumpInputTime) < Time;
	}

	void ConsumeJumpInput()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
		bIsInputtingJump = false;
		StartJumpInputFrame = 0;
		StartJumpingTime = -BIG_NUMBER;
	}

	void ApplyIsJumping(FInstigator Instigator, FVector InJumpDir = FVector::ZeroVector)
	{
		if(!HasControl() && bIsJumping)
		{
			// The remote can get confused here, because of capabilities deactivating in the wrong order,
			// just clear jumping, should be fine.
			ClearIsJumping(CurrentJumpInstigator);
		}

		if(!ensure(!bIsJumping))
			return;

		if(!ensure(!CurrentJumpInstigator.IsValid()))
			return;

		if(!ensure(Instigator.IsValid()))
			return;

		CurrentJumpInstigator = Instigator;

		bIsJumping = true;
		StartJumpingFrame = Time::FrameNumber;
		StartJumpingTime = Time::GameTimeSeconds;
		JumpDir = InJumpDir;

		UMagnetDroneEventHandler::Trigger_JumpStart(Player);
		Player.BlockCapabilities(DroneCommonTags::DroneDashCapability, this);
		Player.BlockCapabilities(MagnetDroneTags::BlockedWhileJumping, this);
	}

	void AddJumpImpulse(FInstigator Instigator, float JumpImpulseMultiplier = 1.0)
	{
		if(!ensure(CurrentJumpInstigator == Instigator))
			return;

		// If we are moving over a certain speed (say we dashed or rolled very quickly), limit horizontal speed
		if(MoveComp.HorizontalVelocity.Size() > DroneComp.MovementSettings.JumpMaxHorizontalSpeed)
		{
			FVector ClampedHorizontalVelocity = MoveComp.HorizontalVelocity.GetClampedToMaxSize(DroneComp.MovementSettings.JumpMaxHorizontalSpeed);
			Player.SetActorHorizontalVelocity(ClampedHorizontalVelocity);
		}

		const FVector JumpDirection = GetJumpDirection();

		FVector Impulse = JumpDirection * DroneComp.MovementSettings.JumpImpulse * JumpImpulseMultiplier;

		// Limit max vertical impulse to prevent super high jumps
		float CurrentSpeedInJumpDirection = Player.ActorVelocity.DotProduct(JumpDirection);
		if(CurrentSpeedInJumpDirection > DroneComp.MovementSettings.JumpImpulse)
		{
			// If we are already moving fast upwards, don't jump
			Impulse = FVector::ZeroVector;
		}
		else if(CurrentSpeedInJumpDirection > 0)
		{
			Impulse -= JumpDirection * CurrentSpeedInJumpDirection;
		}

		Player.AddMovementImpulse(Impulse);
	}

	void ClearIsJumping(FInstigator Instigator)
	{
		if(!bIsJumping)
			return;

		if(!CurrentJumpInstigator.IsValid())
			return;

		if(CurrentJumpInstigator != Instigator)
			return;
		
		CurrentJumpInstigator = nullptr;

		bIsJumping = false;
		JumpDir = FVector::ZeroVector;
		StopJumpingFrame = Time::FrameNumber;

		UMagnetDroneEventHandler::Trigger_JumpStop(Player);
		Player.UnblockCapabilities(DroneCommonTags::DroneDashCapability, this);
		Player.UnblockCapabilities(MagnetDroneTags::BlockedWhileJumping, this);
	}

	bool IsJumping() const
	{
		return bIsJumping;
	}

	bool StartedJumpingThisOrLastFrame() const
	{
		return StartJumpingFrame >= Time::FrameNumber - 1;
	}

	bool StoppedJumpingThisFrame() const
	{
		return StopJumpingFrame == Time::FrameNumber;
	}

	float GetJumpDuration() const
	{
		check(IsJumping());
		return Time::GetGameTimeSince(StartJumpingTime);
	}

	FVector GetJumpDirection() const
	{
		check(IsJumping());

		if(JumpDir.IsNearlyZero())
			return FVector::UpVector;

		return JumpDir;
	}
};