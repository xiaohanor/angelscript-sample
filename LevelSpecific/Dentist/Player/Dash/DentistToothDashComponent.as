enum EDentistToothDashRecoveryState
{
	None,
	Landing,
	Backflipping,
};

UCLASS(NotBlueprintable)
class UDentistToothDashComponent : UActorComponent
{
	access Resolver = private, UDentistToothDashMovementResolver;

	private AHazePlayerCharacter Player;
	private UPlayerMovementComponent MoveComp;

	UDentistToothDashSettings Settings;

	// Input
	bool bIsInputtingDash = false;
	uint StartDashInputFrame = 0;
	float StartDashInputTime = -BIG_NUMBER;
	float DashGraceTimer = BIG_NUMBER;

	private bool bIsDashing = false;
	private EDentistToothDashRecoveryState RecoveryState = EDentistToothDashRecoveryState::None;
	UDentistToothDashAutoAimComponent DashTarget;
	private FInstigator DashInstigator;
	private float StartDashTime = 0;
	private int DashCount = 0;

	private uint BackflipFromImpactFrame = 0;
	private float BackflipDuration = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UDentistToothDashSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (MoveComp.IsOnWalkableGround())
		{
			DashGraceTimer = 0.0;
			ResetDashUsage();
		}
		else
		{
			DashGraceTimer += DeltaTime;
		}

		#if EDITOR
		TEMPORAL_LOG(this)
			.Value("Input;bIsInputtingDash", bIsInputtingDash)
			.Value("Input;StartDashInputFrame", StartDashInputFrame)
			.Value("Input;StartDashInputTime", StartDashInputTime)
			.Value("Input;DashGraceTimer", DashGraceTimer)
			.Value("Input;WasDashInputStartedThisFrame", WasDashInputStartedThisFrame())
			.Value("Input;ShouldDash", ShouldDash())

			.Value("Dash;Is Dashing", IsDashing())
			.Value("Dash;DashInstigator", DashInstigator)
			.Value("Dash;DashTarget", DashTarget)

			.Value("Recovery;RecoveryState", RecoveryState)

			.Value("Recovery;Landing;Is Landing", IsLanding())

			.Value("Recovery;Backflip;Is Backflipping", IsBackflipping())
			.Value("Recovery;Backflip;BackflipFromImpactFrame", BackflipFromImpactFrame)
			.Value("Recovery;Backflip;ShouldBackFlipOutOfDash", ShouldBackFlipOutOfDash())
		;
		#endif
	}

	bool WasDashInputStartedThisFrame() const
	{
		return StartDashInputFrame == Time::FrameNumber;
	}

	bool ShouldDash() const
	{
		// Too long since we input
		if(Time::GetRealTimeSince(StartDashInputTime) > Settings.DashInputBufferTime)
			return false;

		return true;
	}

	void ConsumeDashInput()
	{
		bIsInputtingDash = false;
		StartDashInputFrame = 0;
		StartDashInputTime = -BIG_NUMBER;
	}

	void OnStartDash(FInstigator Instigator, UDentistToothDashAutoAimComponent InDashTarget)
	{
		check(!IsDashing());

		bIsDashing = true;
		RecoveryState = EDentistToothDashRecoveryState::None;
		DashTarget = InDashTarget;
		DashInstigator = Instigator;
		StartDashTime = Time::GameTimeSeconds;

		ConsumeDashInput();

		Player.BlockCapabilities(Dentist::Tags::BlockedWhileDash, this);

		UDentistToothEventHandler::Trigger_OnStartDash(Player);

		DashCount++;
	}

	void OnStopDash(EDentistToothDashRecoveryState InRecoveryState)
	{
		if(!ensure(IsDashing()))
			return;

		bIsDashing = false;
		RecoveryState = InRecoveryState;
		DashTarget = nullptr;
		DashInstigator = nullptr;

		Player.UnblockCapabilities(Dentist::Tags::BlockedWhileDash, this);

		UDentistToothEventHandler::Trigger_OnStopDash(Player);
	}

	bool IsDashing() const
	{
		return bIsDashing;
	}

	bool IsActive() const
	{
		return IsDashing() || RecoveryState != EDentistToothDashRecoveryState::None;
	}

	float GetDashDuration() const
	{
		check(IsDashing());
		return Time::GetGameTimeSince(StartDashTime);
	}

	void ResetDashDuration()
	{
		check(IsDashing());
		StartDashTime = Time::GameTimeSeconds;
	}

	void OnStartLanding()
	{
		check(RecoveryState == EDentistToothDashRecoveryState::Landing);
		UDentistToothEventHandler::Trigger_OnStartDashLanding(Player);
	}

	void OnStopLanding()
	{
		if(RecoveryState == EDentistToothDashRecoveryState::Landing)
			RecoveryState = EDentistToothDashRecoveryState::None;

		UDentistToothEventHandler::Trigger_OnStopDashLanding(Player);
	}

	bool IsLanding() const
	{
		return RecoveryState == EDentistToothDashRecoveryState::Landing;
	}

	void OnStartBackflipping()
	{
		check(RecoveryState == EDentistToothDashRecoveryState::Backflipping);
		UDentistToothEventHandler::Trigger_OnStartDashBackflipping(Player);
	}

	void OnStopBackflipping()
	{
		if(RecoveryState == EDentistToothDashRecoveryState::Backflipping)
			RecoveryState = EDentistToothDashRecoveryState::None;

		UDentistToothEventHandler::Trigger_OnStopDashBackflipping(Player);
	}

	bool IsBackflipping() const
	{
		return RecoveryState == EDentistToothDashRecoveryState::Backflipping;
	}

	bool CanDash() const
	{
		return DashCount < Settings.MaxDashCount;
	}

	void ResetDashUsage()
	{
		DashCount = 0;
	}

	access:Resolver
	void SetBackflip(float Duration)
	{
		BackflipFromImpactFrame = Time::FrameNumber;
		BackflipDuration = Duration;
	}

	bool ShouldBackFlipOutOfDash() const
	{
		return BackflipFromImpactFrame >= Time::FrameNumber - 1;
	}

	float GetBackflipDuration() const
	{
		return BackflipDuration;
	}
}