struct FSandSharkCameraShake
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	float InnerRadius = 5000;

	UPROPERTY(EditDefaultsOnly)
	float OuterRadius = 10000;

	/** Exponent that describes the intensity falloff curve between InnerRadius and InnerRadius + FalloffRadius. 1.0 is linear */
	UPROPERTY(EditDefaultsOnly, Meta = (ClampMin = "0"))
	float FallOff = 1;
}

struct FSandSharkForceFeedback
{
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedbackEffect;

	UPROPERTY(EditDefaultsOnly)
	float InnerRadius = 5000;

	UPROPERTY(EditDefaultsOnly)
	float OuterRadius = 10000;

	/** Min Times per second that FF is played */
	UPROPERTY(EditDefaultsOnly, Meta = (ClampMin = "0"))
	float MinFrequency = 0;

	/** Max Times per second that FF is played */
	UPROPERTY(EditDefaultsOnly, Meta = (ClampMin = "0"))
	float MaxFrequency = 1;

	/** Exponent that describes the intensity falloff curve between InnerRadius and InnerRadius + FalloffRadius. 1.0 is linear */
	UPROPERTY(EditDefaultsOnly, Meta = (ClampMin = "0"))
	float FallOff = 1;

	UPROPERTY(EditDefaultsOnly, Meta = (ClampMin = "0"))
	float MaxIntensity = 1;

	UPROPERTY(EditDefaultsOnly)
	bool bFinishBeforeRepeat;
}

struct FSandSharkAttackFromBelowAnimData
{
	UPROPERTY()
	bool bIsJumping;
}

struct FSandSharkLungeAnimData
{
	UPROPERTY()
	bool bIsJumping;
}
struct FSandSharkAnimData
{
	UPROPERTY()
	FSandSharkAttackFromBelowAnimData AttackFromBelow;

	UPROPERTY()
	FSandSharkLungeAnimData Lunge;

	UPROPERTY()
	bool bIsChasing;

	UPROPERTY()
	bool bIsDiving;

	UPROPERTY()
	bool bIsTurnDiving;

	UPROPERTY()
	bool bShouldTurnLeft;

	UPROPERTY()
	float BoneRelaxSpeedScale = 0.0;

	// Max Left == -1, Max Right == 1 
	UPROPERTY()
	float TurnBlend;

	void Log(FTemporalLog TemporalLog)
	{
		TemporalLog.Value(f"Data;AttackFromBelow.bIsJumping", AttackFromBelow.bIsJumping);
		TemporalLog.Value(f"Data;Lunge.bIsJumping", Lunge.bIsJumping);
		TemporalLog.Value(f"Data;bIsChasing", bIsChasing);
		TemporalLog.Value(f"Data;bIsDiving", bIsDiving);
		TemporalLog.Value(f"Data;bIsTurnDiving", bIsTurnDiving);
		TemporalLog.Value(f"Data;bShouldTurnLeft", bShouldTurnLeft);
	}
}