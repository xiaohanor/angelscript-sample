class USoundDefInstanceLimiting_WithInDot : USoundDefInstanceLimitingCondition
{
	UPROPERTY(EditAnywhere)
	float32 Dot = 0;

	TSet<UHazeSoundDefBase> ClearedSoundDefs;

	// Either check evaluation data or sounddef
	bool ShouldDeactivate(const FHazeSoundDefInstanceEvaluationData& EvaluationData,
				  const UHazeSoundDefBase SoundDef,
				  const TArray<int>& IndexesToRemove,
				  const int& Index) override
	{
		// Hasn't been setup yet.
		if (Dot == 0)
			return false;

		if (SoundDef.TimeActive == 0)
		{
			ClearedSoundDefs.Remove(SoundDef);
		}

		// Already marked as fine to use.
		if (SoundDef.ActivationState == ESoundDefActivationState::Active && ClearedSoundDefs.Contains(SoundDef))
			return true;
		
		if (OutsideOfDot(SoundDef))
			return true;
		
		#if TEST
		FAngelscriptGameThreadScopeWorldContext WorldScope(SoundDef);
		Debug::DrawDebugLine(SoundDef.AudioComponents[0].WorldLocation, SoundDef.AudioComponents[0].WorldLocation + SoundDef.AudioComponents[0].ForwardVector * 500, FLinearColor::Red, 10, 5);
		#endif
		return false;
	}

	bool ShouldActivate(const FHazeSoundDefInstanceEvaluationData& EvaluationData,
						const UHazeSoundDefBase SoundDef, 
						const TArray<int>& IndexesToRemove,
						const int& Index) override
	{
		// Release control of Sounddef, if it's no longer active.
		if (SoundDef.HazeOwner.IsActorDisabled() && SoundDef.ActivationState == ESoundDefActivationState::Deactive)
			return true;
		
		// Continue to be deactivated when deactivated.
		if (SoundDef.ActivationState == ESoundDefActivationState::Deactive)
		{
			return false;
		}

		if (OutsideOfDot(SoundDef) == false)
			return true;

		return false;
	}

	bool OutsideOfDot(const UHazeSoundDefBase SoundDef)
	{
		FAngelscriptGameThreadScopeWorldContext WorldScope(SoundDef);

		// Is any component within range
		for (auto Player: Game::Players)
		{
			for (const auto Component : SoundDef.AudioComponents)
			{
				auto PlayerDirection = (Player.ActorLocation - Component.WorldLocation);
				PlayerDirection.Normalize();

				auto DotProduct = PlayerDirection.DotProduct(Component.ForwardVector);

				if (DotProduct >= Dot)
				{
					#if TEST
					Debug::DrawDebugArrow(Component.WorldLocation, Component.WorldLocation + Component.ForwardVector * 500, 50, FLinearColor::Blue, 5, 30, true);
					#endif
					ClearedSoundDefs.Add(SoundDef);
					return true;
				}
			}
		}

		return false;
	}

	bool ShouldKill(const FHazeSoundDefInstanceEvaluationData& EvaluationData,
					const UHazeSoundDefBase SoundDef,
					const TArray<int>& IndexesToRemove, 
					const int& Index) override
	{
		devCheck(false, f"{this} doesn't support killing sounddef instances!");
		return false;
	}
}