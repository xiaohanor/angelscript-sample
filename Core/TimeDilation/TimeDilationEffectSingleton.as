struct FActiveTimeDilation
{
	FTimeDilationEffect Effect;
	AHazeActor Actor;
	FInstigator Instigator;
	float Timer = 0.0;
	bool bBlendingOut = false;
	bool bIsWorldDilation = false;

	float GetWantedTimeDilation() const
	{
		if (bBlendingOut)
		{
			return Math::Lerp(
				Effect.TimeDilation, 1.0,
				Math::Saturate(Timer / Effect.BlendOutDurationInRealTime)
			);
		}
		else if (Timer < Effect.BlendInDurationInRealTime)
		{
			return Math::Lerp(
				1.0, Effect.TimeDilation,
				Math::Saturate(Timer / Effect.BlendInDurationInRealTime)
			);
		}
		else
		{
			return Effect.TimeDilation;
		}
	}
}

class UTimeDilationEffectSingleton : UHazeSingleton
{
	TArray<FActiveTimeDilation> ActiveEffects;
	float AppliedWorldDilation = 1.0;

	void StartTimeDilationEffect(AHazeActor Actor, FTimeDilationEffect Effect, FInstigator Instigator)
	{
		StopTimeDilationEffect(Actor, Instigator, bSkipBlend = true);

		FActiveTimeDilation ActiveDilation;
		ActiveDilation.Effect = Effect;
		ActiveDilation.Actor = Actor;
		ActiveDilation.Instigator = Instigator;
		ActiveDilation.bIsWorldDilation = (Actor == nullptr);
		ActiveEffects.Add(ActiveDilation);
	}

	void StopTimeDilationEffect(AHazeActor Actor, FInstigator Instigator, bool bSkipBlend = false)
	{
		for (int i = ActiveEffects.Num() - 1; i >= 0; --i)
		{
			if (ActiveEffects[i].Instigator == Instigator && ActiveEffects[i].Actor == Actor)
			{
				if (bSkipBlend || ActiveEffects[i].Effect.BlendOutDurationInRealTime <= 0.0)
				{
					if (Actor != nullptr)
						Actor.ClearActorTimeDilation(Instigator);
					ActiveEffects.RemoveAt(i);
				}
				else
				{
					ActiveEffects[i].bBlendingOut = true;
					ActiveEffects[i].Timer = 0.0;
				}
			}
		}
	}

	float GetWantedWorldTimeDilation()
	{
		float LowestDilation = MAX_flt;
		bool bHadAnyDilation = false;

		for (int i = ActiveEffects.Num() - 1; i >= 0; --i)
		{
			FActiveTimeDilation& ActiveEffect = ActiveEffects[i];
			if (!ActiveEffect.bIsWorldDilation)
				continue;

			bHadAnyDilation = true;

			float WantedDilation = ActiveEffect.GetWantedTimeDilation();
			if (WantedDilation < LowestDilation)
				LowestDilation = WantedDilation;
		}

		if (!bHadAnyDilation)
			return 1.0;
		return LowestDilation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!Game::IsPausedForAnyReason())
		{
			// Progress all existing time dilation effects
			float UndilatedDeltaTime = Time::UndilatedWorldDeltaSeconds;

			for (int i = ActiveEffects.Num() - 1; i >= 0; --i)
			{
				FActiveTimeDilation& ActiveEffect = ActiveEffects[i];
				ActiveEffect.Timer += UndilatedDeltaTime;

				// Remove effects where the actor has been destroyed
				if (!ActiveEffect.bIsWorldDilation && !IsValid(ActiveEffect.Actor))
				{
					ActiveEffects.RemoveAt(i);
					continue;
				}

				if (ActiveEffect.bBlendingOut)
				{
					// Remove the effect after the blend out is done
					if (ActiveEffect.Timer >= ActiveEffect.Effect.BlendOutDurationInRealTime)
					{
						if (ActiveEffect.Actor != nullptr)
							ActiveEffect.Actor.ClearActorTimeDilation(ActiveEffect.Instigator);
						ActiveEffects.RemoveAt(i);
					}
				}
				else
				{
					if (ActiveEffect.Effect.MaxDurationInRealTime >= 0.0
						&& ActiveEffect.Timer >= ActiveEffect.Effect.MaxDurationInRealTime + ActiveEffect.Effect.BlendInDurationInRealTime)
					{
						ActiveEffect.Timer -= ActiveEffect.Effect.BlendInDurationInRealTime;
						ActiveEffect.Timer -= ActiveEffect.Effect.MaxDurationInRealTime;

						if (ActiveEffect.Timer >= ActiveEffect.Effect.BlendOutDurationInRealTime)
						{
							// Blend out is completed as well, remove the effect
							if (ActiveEffect.Actor != nullptr)
								ActiveEffect.Actor.ClearActorTimeDilation(ActiveEffect.Instigator);
							ActiveEffects.RemoveAt(i);
						}
						else
						{
							// Start blending out
							ActiveEffect.bBlendingOut = true;
						}
					}
				}
			}

			// Apply time dilation to the world
			float WantedWorldDilation = GetWantedWorldTimeDilation();
			if (WantedWorldDilation != AppliedWorldDilation)
			{
				AppliedWorldDilation = WantedWorldDilation;
				Time::SetWorldTimeDilation(WantedWorldDilation);
			}

			// Apply time dilation effects to actors
			for (int i = ActiveEffects.Num() - 1; i >= 0; --i)
			{
				FActiveTimeDilation& ActiveEffect = ActiveEffects[i];
				if (ActiveEffect.Actor != nullptr)
					ActiveEffect.Actor.SetActorTimeDilation(ActiveEffect.GetWantedTimeDilation(), ActiveEffect.Instigator);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void ResetStateBetweenLevels()
	{
		ActiveEffects.Empty();
		Time::SetWorldTimeDilation(1.0);
		AppliedWorldDilation = 1.0;
	}
}