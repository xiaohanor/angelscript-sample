namespace ForceFeedback
{
	/** Add non-looping force feedback effect to a world location which can affect both players.
	* @param ForceFeedbackEffect			The FF effect asset to use.
	* @param Epicenter						Location to place the effect in world space.
	* @param bIgnoreTimeDilation			If true, intensity won't be affected by time dilation.
	* @param Tag							Instance identifier, used for stopping effects.
	* @param InnerRadius					Players inside this radius get the effect at full intensity.
	* @param FalloffRadius					Players outside this radius will not be affected (this value gets added to the inner radius).
	* @param Falloff						Exponent that describes the intensity falloff curve between InnerRadius and InnerRadius + FalloffRadius. 1.0 is linear.
	* @param Intensity						Intensity multiplier
	* @param AffectedPlayers				The player characters that will be affected by this effect.
	*/
	UFUNCTION(BlueprintCallable)
	void PlayWorldForceFeedback(UForceFeedbackEffect ForceFeedbackEffect, FVector Epicenter, bool bIgnoreTimeDilation, FInstigator Instigator, float InnerRadius = 180.0, float FalloffRadius = 320.0, float Falloff = 1.0, float Intensity = 1.0, EHazeSelectPlayer AffectedPlayers = EHazeSelectPlayer::Both)
	{
		if (ForceFeedbackEffect == nullptr)
		{
			Warning("PlayWorldForceFeedback() - Force feedback effect is not valid!");
			return;
		}

		for (auto Player : Game::Players)
		{
			if (!Player.IsSelectedBy(AffectedPlayers))
				continue;

			float FalloffMultiplier = GetWorldForceFeedbackIntensityForPlayer(Player, Epicenter, InnerRadius, InnerRadius + FalloffRadius, Falloff);
			if (Math::IsNearlyZero(FalloffMultiplier))
				continue;

			Player.PlayForceFeedback(ForceFeedbackEffect, false, bIgnoreTimeDilation, Instigator, Intensity * FalloffMultiplier);
		}
	}

	/** For one frame, plays force feedback values at a world location which can affect both players.
	* @param FrameForceFeedback				FF values to play for one frame.
	* @param Epicenter						Location to place the effect in world space.
	* @param InnerRadius					Players inside this radius get the effect at full intensity.
	* @param FalloffRadius					Players outside this radius will not be affected (this value is added to the inner radius).
	* @param Falloff						Exponent that describes the intensity falloff curve between InnerRadius and InnerRadius + FalloffRadius. 1.0 is linear.
	* @param AffectedPlayers				The player characters that will be affected by this effect.
	*/
	UFUNCTION(BlueprintCallable)
	void PlayWorldForceFeedbackForFrame(FHazeFrameForceFeedback FrameForceFeedback, FVector Epicenter, float InnerRadius = 180.0, float FalloffRadius = 320.0, float Falloff = 1.0, EHazeSelectPlayer AffectedPlayers = EHazeSelectPlayer::Both, bool bDebugDraw = false)
	{
		for (auto Player : Game::Players)
		{
			if (!Player.IsSelectedBy(AffectedPlayers))
				continue;

			float Intensity = GetWorldForceFeedbackIntensityForPlayer(Player, Epicenter, InnerRadius, InnerRadius + FalloffRadius, Falloff);
			if (Math::IsNearlyZero(Intensity))
				continue;

			Player.SetFrameForceFeedback(FrameForceFeedback, Intensity);
		}

#if EDITOR
			if (bDebugDraw)
			{
				Debug::DrawDebugSphere(Epicenter, InnerRadius, 12, FLinearColor::Green);
				Debug::DrawDebugSphere(Epicenter, InnerRadius + FalloffRadius, 12, FLinearColor::Yellow);
			}
#endif
	}

	/** For one frame, plays a directional force feedback effect at a world location which can affect both players.
	* @param Epicenter						Location to place the effect in world space.
	* @param Intensity						How strong will the effect be.
	* @param InnerRadius					Players inside this radius get the effect at full intensity.
	* @param FalloffRadius					Players outside this radius will not be affected (this value is added to the inner radius).
	* @param Falloff						Exponent that describes the intensity falloff curve between InnerRadius and InnerRadius + FalloffRadius. 1.0 is linear.
	* @param AffectedPlayers				The player characters that will be affected by this effect.
	*/
	UFUNCTION(BlueprintCallable)
	void PlayDirectionalWorldForceFeedbackForFrame(FVector Epicenter, float Intensity, float InnerRadius = 180.0, float FalloffRadius = 320.0, float Falloff = 1.0, EHazeSelectPlayer AffectedPlayers = EHazeSelectPlayer::Both, bool bDebugDraw = false)
	{
		for (auto Player : Game::Players)
		{
			if (!Player.IsSelectedBy(AffectedPlayers))
				continue;

			float FalloffIntensity = GetWorldForceFeedbackIntensityForPlayer(Player, Epicenter, InnerRadius, InnerRadius + FalloffRadius, Falloff);
			if (Math::IsNearlyZero(FalloffIntensity))
				continue;

			FHazeDirectionalForceFeedbackParams DirectionalFFParams;
			DirectionalFFParams.WorldLocation = Epicenter;
			DirectionalFFParams.Intensity = FalloffIntensity * Intensity;

			Player.SetFrameDirectionalForceFeedback(DirectionalFFParams);
		}

#if EDITOR
		if (bDebugDraw)
		{
			Debug::DrawDebugSphere(Epicenter, InnerRadius, 12, FLinearColor::Green);
			Debug::DrawDebugSphere(Epicenter, InnerRadius + FalloffRadius, 12, FLinearColor::Yellow);
		}
#endif
	}

	UFUNCTION(BlueprintCallable)
	void StopWorldForceFeedback(FInstigator Instigator)
	{
		for (auto Player : Game::Players)
			Player.StopForceFeedback(Instigator);
	}

	float GetWorldForceFeedbackIntensityForPlayer(AHazePlayerCharacter Player, FVector Epicenter, float InnerRadius, float OuterRadius, float Falloff)
	{
		float DistanceToEpicenter = Player.ActorLocation.Distance(Epicenter);
		if (DistanceToEpicenter > OuterRadius)
			return 0.0;

		float Intensity = 1.0;
		if (DistanceToEpicenter > InnerRadius)
		{
			float Fraction = Math::Saturate((DistanceToEpicenter - InnerRadius) / (OuterRadius - InnerRadius));
			Intensity = Math::Pow(1.0 - Fraction, Falloff);
		}

		return Intensity;
	}

	FHazeFrameForceFeedback ConvertWorldDirectionToForceFeedback(AHazePlayerCharacter Player, FVector WorldDirection, float Intensity)
	{
		FVector PlayerViewRight = Player.ViewRotation.RightVector;
		FVector NormalDirection = WorldDirection.GetSafeNormal();

		float LeftForceFeedback = Math::Max(NormalDirection.DotProduct(-PlayerViewRight), 0);
		float RightForceFeedback = Math::Max(NormalDirection.DotProduct(PlayerViewRight), 0);
		float RemainingForceFeedback = 1.0 - LeftForceFeedback - RightForceFeedback;

		FHazeFrameForceFeedback ForceFeedback;
		ForceFeedback.LeftMotor = (RemainingForceFeedback + LeftForceFeedback) * Intensity;
		ForceFeedback.RightMotor = (RemainingForceFeedback + RightForceFeedback) * Intensity;

		// The left motor is stronger and lower frequency, so to make it feel nicer lower the intensity a bit
		ForceFeedback.LeftMotor *= 0.625;

		// PrintScaled(f"{ForceFeedback.LeftMotor=}");
		// PrintScaled(f"{ForceFeedback.RightMotor=}");

		return ForceFeedback;
	}
}

/**
 * Play force feedback on the player for the specified duration.
 */
UFUNCTION(BlueprintCallable, Category = "Force Feedback")
mixin void PlayForceFeedbackDuration(AHazePlayerCharacter Player, FInstigator Instigator, float Duration, FHazeFrameForceFeedback ForceFeedback)
{
	auto EffectsManager = UPlayerForceFeedbackEffectsManagerComponent::GetOrCreate(Player);
	EffectsManager.AddDuration(Instigator, Duration, ForceFeedback);
}

/**
 * Play force feedback on the player for the specified duration, blended over time.
 */
UFUNCTION(BlueprintCallable, Category = "Force Feedback")
mixin void PlayForceFeedbackBlendedDuration(AHazePlayerCharacter Player, FInstigator Instigator, float Duration, FHazeFrameForceFeedback StartForceFeedback, FHazeFrameForceFeedback EndForceFeedback)
{
	auto EffectsManager = UPlayerForceFeedbackEffectsManagerComponent::GetOrCreate(Player);
	EffectsManager.AddBlendedDuration(Instigator, Duration, StartForceFeedback, EndForceFeedback);
}

/**
 * Play a force feedback effect originating from the player going in the specified world direction.
 * This will vibrate the left/right motors depending on where the direction is going relative to the player.
 */
UFUNCTION(BlueprintCallable, Category = "Force Feedback")
mixin void PlayForceFeedbackWorldDirection(AHazePlayerCharacter Player, FInstigator Instigator, float Duration, FVector WorldDirection, float Intensity)
{
	auto EffectsManager = UPlayerForceFeedbackEffectsManagerComponent::GetOrCreate(Player);
	EffectsManager.AddDuration(Instigator, Duration, ForceFeedback::ConvertWorldDirectionToForceFeedback(Player, WorldDirection, Intensity));
}

/**
 * Play a force feedback effect originating from the player going in the specified world direction.
 * This will vibrate the left/right motors depending on where the direction is going relative to the player.
 * 
 * Over the duration, the direction will blend from the start direction to the end direction.
 */
UFUNCTION(BlueprintCallable, Category = "Force Feedback")
mixin void PlayForceFeedbackBlendedWorldDirection(AHazePlayerCharacter Player, FInstigator Instigator, float Duration,
	FVector StartWorldDirection, float StartIntensity, FVector EndWorldDirection, float EndIntensity)
{
	auto EffectsManager = UPlayerForceFeedbackEffectsManagerComponent::GetOrCreate(Player);
	EffectsManager.AddBlendedDuration(Instigator, Duration,
	ForceFeedback::ConvertWorldDirectionToForceFeedback(Player, StartWorldDirection, StartIntensity),
	ForceFeedback::ConvertWorldDirectionToForceFeedback(Player, EndWorldDirection, EndIntensity),
	);
}