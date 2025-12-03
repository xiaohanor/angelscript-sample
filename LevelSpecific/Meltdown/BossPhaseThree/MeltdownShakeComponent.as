event void FOnShakeDone();

class UMeltdownShakeComponent : USceneComponent
{
	FVector StartLocation;
	UPROPERTY(EditAnywhere)
	float ShakeAmountX = 20.0;

	UPROPERTY(EditAnywhere)
	float ShakeAmountY = 10.0;

	UPROPERTY(EditAnywhere)
	float ShakeAmountZ = 35.0;

	UPROPERTY(EditAnywhere)
	float ShakeSpeed = 30;

	UPROPERTY(EditAnywhere)
	float Amplitude = 1.0;

	UPROPERTY(EditAnywhere)
	float ShakeDuration;

	UPROPERTY()
	FOnShakeDone ShakeDone;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = RelativeLocation;
		SetComponentTickEnabled(false);

	}

	UFUNCTION(BlueprintCallable)
	void StartShake()
	{
		SetComponentTickEnabled(true);
		Timer::SetTimer(this, n"StopShake", ShakeDuration);
	}

	UFUNCTION(BlueprintCallable)
	void StopShake()
	{
		SetComponentTickEnabled(false);
		SetRelativeLocation(FVector(0,0,0));
		ShakeDone.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float SineMove = Math::Sin(Time::GameTimeSeconds * ShakeSpeed) * Amplitude;
		RelativeLocation = StartLocation + FVector(ShakeAmountX, ShakeAmountY , ShakeAmountZ) * SineMove;
	}
};