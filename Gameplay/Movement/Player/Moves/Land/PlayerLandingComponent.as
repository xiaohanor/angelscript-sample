

namespace PlayerLanding
{

const FConsoleVariable CVar_MovementAllowFallDamage("Haze.Movement.AllowFallDamage", 1);

};

class UPlayerLandingComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> DeathEffect;
	
	UPROPERTY()
	UPlayerLandingSettings Settings;

	UPROPERTY()
	FPlayerLandingAnimationData AnimData;

	TInstigated<EPlayerLandingMode> InstigatedFatalLandingMode;
	default InstigatedFatalLandingMode.SetDefaultValue(EPlayerLandingMode::Normal);

	TInstigated<EPlayerLandingMode> InstigatedStunnedLandingMode;
	default InstigatedStunnedLandingMode.SetDefaultValue(EPlayerLandingMode::Normal);

	private TArray<FInstigator> FallDamageBlockers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerLandingSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	void ApplyLanding(FInstigator Instigator, EInstigatePriority Priority, EPlayerLandingMode FatalMode, EPlayerLandingMode StunnedMode)
	{
		InstigatedFatalLandingMode.Apply(FatalMode, Instigator, Priority);
		InstigatedStunnedLandingMode.Apply(StunnedMode, Instigator, Priority);
	}

	void ClearLanding(FInstigator Instigator)
	{
		InstigatedFatalLandingMode.Clear(Instigator);
		InstigatedStunnedLandingMode.Clear(Instigator);
	}

	void BlockFallDamage(FInstigator Instigator)
	{
		FallDamageBlockers.AddUnique(Instigator);
	}

	void UnblockFallDamage(FInstigator Instigator)
	{
		FallDamageBlockers.RemoveSingleSwap(Instigator);
	}

	bool HasBlockedFallDamage() const
	{
		return FallDamageBlockers.Num() > 0;
	}
}

struct FPlayerLandingAnimationData
{
	UPROPERTY()
	EPlayerLandingState State;

	UPROPERTY()	
	float StunnedFraction;

	UPROPERTY()	
	float FatalFraction;

	UPROPERTY()	
	float FatalTransitionThreshold = 0.12;

	void Reset()
	{
		State = EPlayerLandingState::Standard;
	}
}

enum EPlayerLandingState
{
	Standard,
	Stunned,
	Fatal
}

enum EPlayerLandingMode
{
	Normal,
	Force,
	Avoid
}