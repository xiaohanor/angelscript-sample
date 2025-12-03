enum EDentistToothJump
{
	None,
	Regular,
	Swirl,
	FrontFlip,
};

UCLASS(NotBlueprintable)
class UDentistToothJumpComponent : UActorComponent
{
	private AHazePlayerCharacter Player;
	private UPlayerMovementComponent MoveComp;
	UDentistToothJumpSettings Settings;

	// Input
	bool bIsInputtingJump = false;
	uint StartJumpInputFrame = 0;
	float StartJumpInputTime = -BIG_NUMBER;

	bool bForceFrontFlipJump = false;

	// Jump
	private FInstigator CurrentJumpInstigator;
	private bool bIsJumping = false;
	private uint StartJumpingFrame = 0;
	private float StartJumpingTime = 0;
	private bool bQueuedJump = false;

	// Grounded
	private float GroundTime = BIG_NUMBER;
	private float AirTime = -1;

	private EDentistToothJump JumpType = EDentistToothJump::None;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UDentistToothJumpSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (MoveComp.IsOnWalkableGround())
		{
			AirTime = 0.0;
			GroundTime += DeltaTime;

			if(!IsJumping() && !ShouldJump() && GroundTime > Settings.ChainJumpGroundGraceTime)
				ResetChainedJumpCount();
		}
		else
		{
			AirTime += DeltaTime;
			GroundTime = 0.0;
		}

		Time::GetGameTimeSince(MoveComp.FallingData.StartTime);

		#if EDITOR
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("Input;Is Inputting Jump", bIsInputtingJump);
		TemporalLog.Value("Input;Start Jump Input Frame", StartJumpInputFrame);
		TemporalLog.Value("Input;Start Jump Input Time", StartJumpInputTime);
		TemporalLog.Value("Input;Game Time", Time::GameTimeSeconds);
		TemporalLog.Value("Input;Jump Input Expire Time", StartJumpInputTime + Settings.JumpInputBufferTime);

		TemporalLog.Value("Jump;Current Jump Instigator", CurrentJumpInstigator);
		TemporalLog.Value("Jump;Is Jumping", bIsJumping);
		TemporalLog.Value("Jump;Start Jumping Frame", StartJumpingFrame);
		TemporalLog.Value("Jump;Start Jumping Time", StartJumpingTime);

		TemporalLog.Value("Input;Is In Jump Grace Period", IsInJumpGracePeriod());
		TemporalLog.Value("Input;Was Jump Input Started This Frame", WasJumpInputStartedThisFrame());
		TemporalLog.Value("Input;Should Jump", ShouldJump());
		
		TemporalLog.Value("Jump;Started Jumping This Or Last Frame", StartedJumpingThisOrLastFrame());

		if(IsJumping())
		{
			TemporalLog.Value("Jump;Jump Duration", GetJumpDuration());
		}

		TemporalLog.Value("Grounded;Ground Time", GroundTime);
		TemporalLog.Value("Grounded;Air Duration", GetAirDuration());

		TemporalLog.Value("Grounded;Falling Duration", GetFallingDuration());
		#endif
	}

	bool IsInJumpGracePeriod() const
	{
		if(AirTime < 0)
			return false;

		return AirTime <= Settings.JumpGraceTime;
	}

	void ResetJumpGracePeriod()
	{
		AirTime = -1;
	}

	bool WasJumpInputStartedThisFrame() const
	{
		return StartJumpInputFrame == Time::FrameNumber;
	}

	bool ShouldJump() const
	{
		// Not in grace window
		if(!IsInJumpGracePeriod())
			return false;

		if(bForceFrontFlipJump)
			return true;

		// Too long since we input
		if(Time::GetGameTimeSince(StartJumpInputTime) > Settings.JumpInputBufferTime)
			return false;

		return true;
	}

	void ConsumeJumpInput()
	{
		bIsInputtingJump = false;
		StartJumpInputFrame = 0;
		StartJumpingTime = -BIG_NUMBER;
	}

	void ApplyIsJumping(FInstigator Instigator)
	{
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
	}

	void IncrementChainedJumpCount()
	{
		if(bForceFrontFlipJump)
		{
			JumpType = EDentistToothJump::FrontFlip;
			bForceFrontFlipJump = false;
			return;
		}

		switch(JumpType)
		{
			case EDentistToothJump::None:
				JumpType = EDentistToothJump::Regular;
				break;

			case EDentistToothJump::Regular:
				JumpType = EDentistToothJump::Swirl;
				break;

			case EDentistToothJump::Swirl:
				JumpType = EDentistToothJump::FrontFlip;
				break;

			case EDentistToothJump::FrontFlip:
				JumpType = EDentistToothJump::Regular;
				break;
		}
	}

	void AddJumpImpulse(FInstigator Instigator)
	{
		if(!ensure(CurrentJumpInstigator == Instigator))
			return;

		// If we are moving over a certain speed (say we dashed or rolled very quickly), limit horizontal speed
		if(MoveComp.HorizontalVelocity.Size() > Settings.JumpMaxHorizontalSpeed)
		{
			FVector ClampedHorizontalVelocity = MoveComp.HorizontalVelocity.GetClampedToMaxSize(Settings.JumpMaxHorizontalSpeed);
			Player.SetActorHorizontalVelocity(ClampedHorizontalVelocity);
		}

		const float JumpImpulse = GetJumpImpulse();
		FVector Impulse = FVector::UpVector * JumpImpulse;

		// Limit max vertical impulse to prevent super high jumps
		float CurrentSpeedInJumpDirection = Player.ActorVelocity.DotProduct(FVector::UpVector);
		if(CurrentSpeedInJumpDirection > JumpImpulse)
		{
			// If we are already moving fast upwards, don't jump
			return;
		}
		else if(CurrentSpeedInJumpDirection > 0)
		{
			// Reduce the impulse to prevent the max speed from being too high
			Impulse -= FVector::UpVector * CurrentSpeedInJumpDirection;
		}

		MoveComp.AddPendingImpulse(Impulse);
	}

	void ClearIsJumping(FInstigator Instigator)
	{
		if(!ensure(bIsJumping))
			return;

		if(!ensure(CurrentJumpInstigator.IsValid()))
			return;

		if(!ensure(CurrentJumpInstigator == Instigator))
			return;
		
		CurrentJumpInstigator = nullptr;

		bIsJumping = false;
	}

	bool IsJumping() const
	{
		return bIsJumping;
	}

	bool StartedJumpingThisOrLastFrame() const
	{
		return StartJumpingFrame >= Time::FrameNumber - 1;
	}

	EDentistToothJump GetJumpType() const
	{
		return JumpType;
	}

	void SetJumpType(EDentistToothJump InJumpType)
	{
		JumpType = InJumpType;
	}

	void ResetChainedJumpCount()
	{
		JumpType = EDentistToothJump::None;
	}

	float GetJumpImpulse() const
	{
		float JumpImpulse = Settings.JumpImpulse;

		switch(JumpType)
		{
			case EDentistToothJump::None:
			case EDentistToothJump::Regular:
				return JumpImpulse;

			case EDentistToothJump::Swirl:
				return JumpImpulse * Settings.DoubleJumpImpulseMultiplier;

			case EDentistToothJump::FrontFlip:
				return JumpImpulse * Settings.TripleJumpImpulseMultiplier;
		}
	}

	float GetJumpDuration() const
	{
		check(IsJumping());
		return Time::GetGameTimeSince(StartJumpingTime);
	}

	float GetAirDuration() const
	{
		if(AirTime < 0)
			return 0;
		else
			return AirTime;
	}

	float GetFallingDuration() const
	{
		if(!MoveComp.IsFalling())
			return 0;
		else
			return Time::GetGameTimeSince(MoveComp.FallingData.StartTime);
	}
};