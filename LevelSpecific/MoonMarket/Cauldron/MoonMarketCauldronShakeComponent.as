event void FCauldronOnShakeDone();

struct FShakeSettings
{
	float ShakeAmountX = 0.2;
	float ShakeAmountY = 0.2;
	float ShakeAmountZ = 1.0;
	float ShakeSpeed = 30;
	float Amplitude = 0.5;
	float ShakeDuration = 0.5;
}

class UMoonMarketCauldronShakeComponent : USceneComponent
{
	FVector StartLocation;

	TOptional<FShakeSettings> CurrentSettings;

	UPROPERTY()
	FCauldronOnShakeDone ShakeDone;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = RelativeLocation;
	}

	UFUNCTION(BlueprintCallable)
	void OverrideShakeSettings(FShakeSettings NewSettings)
	{
		CurrentSettings.Set(NewSettings);
		Timer::SetTimer(this, n"StopShake", NewSettings.ShakeDuration);
	}

	UFUNCTION(BlueprintCallable)
	void StopShake()
	{
		CurrentSettings.Reset();
		SetRelativeLocation(FVector(0,0,0));
		ShakeDone.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!CurrentSettings.IsSet())
			return;

		float SineMove = Math::Sin(Time::GameTimeSeconds * CurrentSettings.Value.ShakeSpeed) * CurrentSettings.Value.Amplitude;
		FVector Shake = FVector(CurrentSettings.Value.ShakeAmountX, CurrentSettings.Value.ShakeAmountY , CurrentSettings.Value.ShakeAmountZ);
		RelativeLocation = StartLocation + Shake * SineMove;
	}
};