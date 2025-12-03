event void FPlayerJumpEvent(AHazePlayerCharacter Player);

class UPlayerJumpComponent : UActorComponent
{
	access JumpInternal = private, UPlayerJumpCapability, UPlayerFirstPersonJumpCapability, UTundraPlayerSnowMonkeyJumpCapability, UPlayerRollDashJumpCapability;

	UPlayerJumpSettings Settings;

	access:JumpInternal float JumpGraceTimer = 0.0;
	access:JumpInternal float PreventJumpGraceUntilGameTime = 0.0;
	access:JumpInternal bool bIsInJumpGracePeriod = false;
	access:JumpInternal float JumpCooldown = 0.0;
	access:JumpInternal bool bIsJumpOnCooldown = false;

	private bool bJumpActive = false;
	private float JumpActivationTime = 0.0;

	private float BufferedJumpAtTime = -1.0;
	private float BufferedJumpTimeWindow = 0.0;

	AHazePlayerCharacter Player;

	UPROPERTY()
	FPlayerJumpEvent OnJump;

	UPlayerJumpCounter JumpCounter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerJumpSettings::GetSettings(Cast<AHazeActor>(Owner));

		Player = Cast<AHazePlayerCharacter>(Owner);

		DevTogglesMovement::Jump::AutoAlwaysJump.MakeVisible();

		JumpCounter = Game::GetSingleton(UPlayerJumpCounter);
	}


	void StartJump()
	{
		bJumpActive = true;
		JumpActivationTime = Time::GameTimeSeconds;
		OnJump.Broadcast(Player);

		JumpCounter.IncrementJump();
	}

	void StopJump()
	{
		bJumpActive = false;
	}

	bool IsJumping() const
	{
		return bJumpActive;
	}

	bool IsInJumpGracePeriod() const
	{
		return bIsInJumpGracePeriod;
	}

	void StopJumpGracePeriod(float PreventJumpGraceForDuration = 0.0)
	{
		bIsInJumpGracePeriod = false;
		JumpGraceTimer = MAX_flt;
		PreventJumpGraceUntilGameTime = Time::GameTimeSeconds + PreventJumpGraceForDuration;
	}

	bool IsJumpOnCooldown() const
	{
		return bIsJumpOnCooldown;
	}

	// Check whether we've just started jumping in the past specified duration
	bool StartedJumpingWithinDuration(float MaxStartupDuration)
	{
		if (bJumpActive)
			return Time::GetGameTimeSince(JumpActivationTime) <= MaxStartupDuration;
		return false;
	}

	void BufferJumpInput(float TimeWindow = 0.3)
	{
		const float CurrentTime = Time::GetRealTimeSeconds();
		const float TimeSinceBuffer = CurrentTime - BufferedJumpAtTime;

		BufferedJumpAtTime = CurrentTime;
		BufferedJumpTimeWindow = Math::Max(TimeWindow, (BufferedJumpTimeWindow - TimeSinceBuffer));
	}

	void ConsumeBufferedJump()
	{
		BufferedJumpAtTime = -1.0;
	}

	bool IsJumpBuffered() const
	{
		if (BufferedJumpAtTime < 0.0)
			return false;

		const float CurrentTime = Time::GetRealTimeSeconds();
		const float Dif = CurrentTime - BufferedJumpAtTime;

		return Dif < BufferedJumpTimeWindow;
	}

	bool IsDevAutoJumpToggled() const
	{
		if (DevTogglesMovement::Jump::AutoAlwaysJump.IsEnabled(Player))
			return true;
		return false;
	}
}
