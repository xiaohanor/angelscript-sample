struct FPlayerForceFeedbackDuration
{
	FInstigator Instigator;
	float Duration;
	float RemainingTime;
	FHazeFrameForceFeedback ChannelsStart;
	FHazeFrameForceFeedback ChannelsEnd;
}

class UPlayerForceFeedbackEffectsManagerComponent : UActorComponent
{
	TArray<FPlayerForceFeedbackDuration> Durations;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void AddDuration(FInstigator Instigator, float Time, FHazeFrameForceFeedback Channels)
	{
		FPlayerForceFeedbackDuration Effect;
		Effect.Instigator = Instigator;
		Effect.Duration = Time;
		Effect.RemainingTime = Time;
		Effect.ChannelsStart = Channels;
		Effect.ChannelsEnd = Channels;
		Durations.Add(Effect);

		SetComponentTickEnabled(true);
	}

	void AddBlendedDuration(FInstigator Instigator, float Time, FHazeFrameForceFeedback ChannelsStart, FHazeFrameForceFeedback ChannelsEnd)
	{
		FPlayerForceFeedbackDuration Effect;
		Effect.Instigator = Instigator;
		Effect.Duration = Time;
		Effect.RemainingTime = Time;
		Effect.ChannelsStart = ChannelsStart;
		Effect.ChannelsEnd = ChannelsEnd;
		Durations.Add(Effect);

		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (int i = Durations.Num() - 1; i >= 0; --i)
		{
			FPlayerForceFeedbackDuration& Effect = Durations[i];
			Effect.RemainingTime -= DeltaSeconds;

			float Alpha = Math::Saturate(1.0 - (Effect.RemainingTime / Effect.Duration));

			FHazeFrameForceFeedback ForceFeedback;
			ForceFeedback.LeftMotor = Math::Lerp(Effect.ChannelsStart.LeftMotor, Effect.ChannelsEnd.LeftMotor, Alpha);
			ForceFeedback.RightMotor = Math::Lerp(Effect.ChannelsStart.RightMotor, Effect.ChannelsEnd.RightMotor, Alpha);
			ForceFeedback.LeftTrigger = Math::Lerp(Effect.ChannelsStart.LeftTrigger, Effect.ChannelsEnd.LeftTrigger, Alpha);
			ForceFeedback.RightTrigger = Math::Lerp(Effect.ChannelsStart.RightTrigger, Effect.ChannelsEnd.RightTrigger, Alpha);

			Player.SetFrameForceFeedback(ForceFeedback);

			if (Effect.RemainingTime < 0.0)
				Durations.RemoveAt(i);
		}

		if (Durations.Num() == 0)
			SetComponentTickEnabled(false);
	}
}