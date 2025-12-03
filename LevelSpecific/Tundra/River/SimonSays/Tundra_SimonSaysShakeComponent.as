enum ETundra_SimonSaysShakePattern
{
	PerlinNoise
}

struct FTundra_SimonSaysShakePerlinSettings
{
	UPROPERTY()
	FTundra_SimonSaysShakePerlinComponentSettings X;

	UPROPERTY()
	FTundra_SimonSaysShakePerlinComponentSettings Y;

	UPROPERTY()
	FTundra_SimonSaysShakePerlinComponentSettings Z;
}

struct FTundra_SimonSaysShakePerlinComponentSettings
{
	UPROPERTY()
	float Frequency = 10.0;

	UPROPERTY()
	float Amplitude = 5.0;

	UPROPERTY()
	float Offset = 0.0;
}

// This shake component will shake it's parent scene component in beat with simon says
class UTundra_SimonSaysShakeComponent : USceneComponent
{
	ATundra_SimonSaysManager Manager;
	int LastBeatRumbleTriggeredAt = -1;
	float TimeOfStartShake = -100.0;

	UPROPERTY(EditAnywhere)
	ETundra_SimonSaysShakePattern ShakePattern;

	UPROPERTY(EditAnywhere)
	float ShakeDuration = 0.2;

	// This random offset will be applied to the perlin noise sampling, if 0 all shakes will be identical.
	UPROPERTY(EditAnywhere)
	float MaxRandomOffset = 200.0;

	UPROPERTY(EditAnywhere)
	FTundra_SimonSaysShakePerlinSettings PerlinSettings;
	default PerlinSettings.Z.Amplitude = 0.0;
	default PerlinSettings.Z.Frequency = 0.0;

	bool bIsShaking = false;
	FVector OriginalRelativeLocation;

	// Perlin noise stuff
	FVector PerlinOffset = FVector::ZeroVector;
	float PerlinCurrentRandomOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<ATundra_SimonSaysManager> ListedManager;
		Manager = ListedManager.Single;
		OriginalRelativeLocation = AttachParent.RelativeLocation;
		//StartShake();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		HandleShake(DeltaTime);

		if(Manager.GetTimeToNextBeat() <= -Manager.BeatRumbleTimeOffset && Manager.GetCurrentBeat() != LastBeatRumbleTriggeredAt)
		{
			LastBeatRumbleTriggeredAt = Manager.GetCurrentBeat();
			StartShake();
		}
	}

	void StartShake()
	{
		TimeOfStartShake = Time::GetGameTimeSeconds();
		bIsShaking = true;
		PerlinOffset = FVector(PerlinSettings.X.Offset, PerlinSettings.Y.Offset, PerlinSettings.Z.Offset);

		// Perlin
		PerlinCurrentRandomOffset = Math::RandRange(0.0, MaxRandomOffset);
	}

	void HandleShake(float DeltaTime)
	{
		if(!bIsShaking)
			return;

		if(Time::GetGameTimeSince(TimeOfStartShake) < ShakeDuration)
		{
			switch(ShakePattern)
			{
				case ETundra_SimonSaysShakePattern::PerlinNoise:
				{
					AttachParent.RelativeLocation = FVector(
						OriginalRelativeLocation.X + GetCurrentPerlinOffset(DeltaTime, PerlinOffset.X, PerlinSettings.X),
						OriginalRelativeLocation.Y + GetCurrentPerlinOffset(DeltaTime, PerlinOffset.Y, PerlinSettings.Y),
						OriginalRelativeLocation.Z + GetCurrentPerlinOffset(DeltaTime, PerlinOffset.Z, PerlinSettings.Z)
					);
					break;
				}
				default:
					devError("Not implemented");
			}
			
		}
		else
		{
			bIsShaking = false;
			AttachParent.RelativeLocation = OriginalRelativeLocation;
		}
	}

	float GetCurrentPerlinOffset(float DeltaTime, float& InOutPerlinOffset, FTundra_SimonSaysShakePerlinComponentSettings ComponentSettings)
	{
		if(ComponentSettings.Amplitude != 0.0)
		{
			InOutPerlinOffset += DeltaTime * ComponentSettings.Frequency;
			return ComponentSettings.Amplitude * Math::PerlinNoise1D(InOutPerlinOffset + PerlinCurrentRandomOffset);
		}

		return 0.0;
	}
}