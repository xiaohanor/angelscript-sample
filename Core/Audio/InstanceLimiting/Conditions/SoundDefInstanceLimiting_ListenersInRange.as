class USoundDefInstanceLimiting_ListenersInRange : USoundDefInstanceLimitingCondition
{
	// Only used for the sounddef about to be created. Doesn't have any audio components yet.
	UPROPERTY(EditAnywhere)
	float MaxDistance = 0;

	bool AnyListenersInRange(
		const FHazeSoundDefInstanceEvaluationData& EvaluationData,
		const UHazeSoundDefBase SoundDef)
	{
		devCheck(MaxDistance > 0, f"MaxDistance '{MaxDistance}' hasn't been set for {this}, and won't work as intended!");

		if (MaxDistance == 0)
			return true;

		if (SoundDef != nullptr)
			return SoundDef.ListenersInRange();

		TArray<UHazeAudioListenerComponentBase> Listeners;
		if (!Audio::GetListeners(EvaluationData.Outer, Listeners))
			return false;

		// Is any component within range
		for (auto Listener: Listeners)
		{
			for (const auto& ComponentData : EvaluationData.Params.AudioComponentDatas)
			{
				auto SqrDistance = Listener.WorldLocation.DistSquared(ComponentData.WorldTransform.Location);

				if (SqrDistance < MaxDistance * MaxDistance)
				{
					return true;
				}
			}
		}

		return false;
	}

	bool ShouldActivate(const FHazeSoundDefInstanceEvaluationData& EvaluationData,
						const UHazeSoundDefBase SoundDef, const TArray<int>& IndexesToRemove, const int& Index) override
	{
		if (AnyListenersInRange(EvaluationData, SoundDef))
			return true;

		return false;
	}

	// Either check evaluation data or sounddef
	bool ShouldDeactivate(const FHazeSoundDefInstanceEvaluationData& EvaluationData,
				  const UHazeSoundDefBase SoundDef,
				  const TArray<int>& IndexesToRemove,
				  const int& Index) override
	{
		if (!AnyListenersInRange(EvaluationData, SoundDef))
			return true;

		return false;
	}

	bool ShouldKill(const FHazeSoundDefInstanceEvaluationData& EvaluationData,
					const UHazeSoundDefBase SoundDef, 
					const TArray<int>& IndexesToRemove,
					const int& Index) override
	{
		if (!AnyListenersInRange(EvaluationData, SoundDef))
			return true;

		return false;

	}

}