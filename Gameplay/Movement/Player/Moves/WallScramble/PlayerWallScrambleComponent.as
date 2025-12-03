namespace PlayerWallScramble
{
	const FConsoleVariable CVar_DebugWallScramble("Haze.Movement.Debug.WallScramble", 0);
}

class UPlayerWallScrambleComponent : UActorComponent
{
	UPlayerWallScrambleSettings Settings;
	UPlayerWallSettings WallSettings;

	FPlayerWallScrambleData Data;
	UPROPERTY(BlueprintReadOnly)
	FPlayerWallScrambleAnimData AnimData;

	bool bCanScramble = false;

	// HACK
	bool bForceScramble = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerWallScrambleSettings::GetSettings(Cast<AHazePlayerCharacter>(Owner));
		WallSettings = UPlayerWallSettings::GetSettings(Cast<AHazePlayerCharacter>(Owner));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	EPlayerWallScrambleState GetState() const property
	{
		return Data.State;
	}

	void SetState(EPlayerWallScrambleState NewState) property
	{
		Data.State = NewState;
		AnimData.State = Data.State;
	}

	// Returns true if the state completed was the active state (nothing else took over)
	bool StateCompleted(EPlayerWallScrambleState CompletedState)
	{
		if (State == CompletedState)
		{
			ResetWallScramble();
			return true;
		}
		return false;
	}

	void ResetWallScramble()
	{
		State = EPlayerWallScrambleState::None;
		Data.Reset();
		AnimData.Reset();
	}
}

struct FPlayerWallScrambleData
{	
	EPlayerWallScrambleState State = EPlayerWallScrambleState::None;

	bool bWallScrambleComplete = false;
	bool bWantsToExit = false;

	float ExitDuration = 0.0;
	float WallPitch = 0.0;

	FHitResult WallHit;
	FHitResult PredictedScrambleHit;
	FRotator ExitStartRotation;

	void Reset()
	{
		bWallScrambleComplete = false;
		bWantsToExit = false;
		WallHit = FHitResult();
		PredictedScrambleHit = FHitResult();
		WallPitch = 0.0;
		ExitDuration = 0.0;
	}
}

struct FPlayerWallScrambleAnimData
{
	UPROPERTY()
	EPlayerWallScrambleState State = EPlayerWallScrambleState::None;

	UPROPERTY()
	float JumpRotationAngle = 0.0;

	void Reset()
	{
		State = EPlayerWallScrambleState::None;
		JumpRotationAngle = 0.0;
	}
}

enum EPlayerWallScrambleState
{
	None,
	Scramble,
	Exit,
	Jump
}