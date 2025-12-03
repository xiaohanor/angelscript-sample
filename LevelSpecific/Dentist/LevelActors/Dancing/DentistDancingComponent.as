struct FDentistDancingFloat
{
	UPROPERTY(EditAnywhere)
	float Amplitude = 1.0;

	UPROPERTY(EditAnywhere)
	float Frequency = 1.0;

	float GetValue(float OriginalValue, float Time, float Multiplier) const
	{
		const float Offset = Math::Sin((Time * Frequency));
		return OriginalValue + (Offset * Amplitude * Multiplier);
	}
};

UCLASS(NotBlueprintable)
class UDentistDancingComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Dancing")
	float DanceSpeed = 1.0;

	UPROPERTY(EditAnywhere, Category = "Dancing")
	bool bScaleDanceSpeedWithActorScale = true;

	UPROPERTY(EditInstanceOnly, Category = "Dancing")
	float TimeOffset = -1;

	UPROPERTY(EditAnywhere, Category = "Dancing|Scale")
	float ScaleMultiplier = 0.1;

	UPROPERTY(EditAnywhere, Category = "Dancing|Scale")
	FDentistDancingFloat ScaleX;
	default ScaleX.Frequency = 1.22;

	UPROPERTY(EditAnywhere, Category = "Dancing|Scale")
	FDentistDancingFloat ScaleY;
	default ScaleY.Frequency = 1.45;

	UPROPERTY(EditAnywhere, Category = "Dancing|Scale")
	FDentistDancingFloat ScaleZ;
	default ScaleZ.Frequency = 1.78;
	
	UPROPERTY(EditAnywhere, Category = "Dancing|Rotation")
	float RotationMultiplier = 10;

	UPROPERTY(EditAnywhere, Category = "Dancing|Rotation")
	FDentistDancingFloat RotationPitch;
	default RotationPitch.Frequency = 1.13;

	UPROPERTY(EditAnywhere, Category = "Dancing|Rotation")
	FDentistDancingFloat RotationRoll;
	default RotationRoll.Frequency = 1.4;

	UPROPERTY(EditAnywhere, Category = "Dancing|Rotation")
	FDentistDancingFloat RotationYaw;
	default RotationYaw.Frequency = 3.86;

	private FVector InitialScale;
	private FRotator InitialRotation;

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		if(TimeOffset < 0)
			TimeOffset = Math::RandRange(0.0, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(TimeOffset < 0)
			TimeOffset = Math::RandRange(0.0, 1.0);

		InitialScale = RelativeScale3D;
		InitialRotation = RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Speed = DanceSpeed;
		if(bScaleDanceSpeedWithActorScale)
			Speed *= 1.0 / Owner.ActorScale3D.AbsMax;

		const float SampleTime = (Time::GameTimeSeconds * Speed) + TimeOffset;

		const FVector Scale = FVector(
			ScaleX.GetValue(InitialScale.X, SampleTime, ScaleMultiplier),
			ScaleY.GetValue(InitialScale.Y, SampleTime, ScaleMultiplier),
			ScaleZ.GetValue(InitialScale.Z, SampleTime, ScaleMultiplier)
		);

		SetRelativeScale3D(Scale);

		const FRotator Rotation = FRotator(
			RotationPitch.GetValue(InitialRotation.Pitch, SampleTime, RotationMultiplier),
			RotationYaw.GetValue(InitialRotation.Yaw, SampleTime, RotationMultiplier),
			RotationRoll.GetValue(InitialRotation.Roll, SampleTime, RotationMultiplier)
		);

		SetRelativeRotation(Rotation);
	}
};