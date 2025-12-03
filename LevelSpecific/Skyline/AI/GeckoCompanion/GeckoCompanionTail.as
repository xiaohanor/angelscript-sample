class UGeckoCompanionTail : USceneComponent
{
	FHazeAcceleratedFloat AccPitch;
	FRotator BaseRot;

	float WagAmplitude = 0.0;
	float WagFrequency = 1.0;
	FHazeAcceleratedFloat AccAmplitude;
	FHazeAcceleratedFloat AccFrequency;

	float Elevation = 0.0;
	float ElevationStiffness = 1.0;
	FHazeAcceleratedFloat AccElevation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BaseRot = RelativeRotation;
		AccPitch.SnapTo(0.0);
	}

	void SetElevation(float Pitch, float Stiffness)
	{
		Elevation = Pitch;
		ElevationStiffness = Stiffness;
	}

	void Wag(float Amplitude, float Frequency)
	{
		WagAmplitude = Amplitude;
		WagFrequency = Frequency;
	}	

	void StopWagging()
	{
		WagAmplitude = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AccAmplitude.AccelerateTo(WagAmplitude, 2.0, DeltaTime);
		//AccFrequency.AccelerateTo(WagFrequency, 2.0, DeltaTime);

		// Wag in yaw
		float WagYaw = Math::Sin(Time::GameTimeSeconds * WagFrequency) * AccAmplitude.Value;

		// Only elevation in pitch
		AccPitch.SpringTo(Elevation, ElevationStiffness, 0.2, DeltaTime);

		//RelativeRotation = FRotator(AccPitch.Value, 0.0, 0.0).Compose(BaseRot).Compose(FRotator(0.0, AccYaw.Value, 0.0));
		RelativeRotation = BaseRot.Compose(FRotator(AccPitch.Value, WagYaw, 0.0));
	}
}
