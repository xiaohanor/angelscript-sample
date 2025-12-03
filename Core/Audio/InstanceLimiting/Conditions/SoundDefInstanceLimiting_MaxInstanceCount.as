class USoundDefInstanceLimiting_MaxInstanceCount : USoundDefInstanceLimitingCondition
{
	UPROPERTY(EditAnywhere)
	int32 MaxInstanceCount = 0;

	bool ToManyInstances(const FHazeSoundDefInstanceEvaluationData& EvaluationData, const TArray<int>& IndexesToRemove, int32 Offset = 0)
	{
		devCheck(MaxInstanceCount > 0, f"MaxInstanceCount '{MaxInstanceCount}' hasn't been set for {this}, and won't work as intended!");

		// Hasn't been setup yet.
		if (MaxInstanceCount == 0)
			return true;

		if (EvaluationData.Internal.SoundDefs.Num() + Offset - IndexesToRemove.Num() > MaxInstanceCount)
			return true;

		return false;
	}


	bool ShouldActivate(const FHazeSoundDefInstanceEvaluationData& EvaluationData,
						const UHazeSoundDefBase SoundDef, const TArray<int>& IndexesToRemove, const int& Index) override
	{
		if (!ToManyInstances(EvaluationData, IndexesToRemove))
			return true;

		return false;
	}

	// Either check evaluation data or sounddef
	bool ShouldDeactivate(const FHazeSoundDefInstanceEvaluationData& EvaluationData,
				   const UHazeSoundDefBase SoundDef,
				   const TArray<int>& IndexesToRemove,
				   const int& Index) override
	{
		devCheck(MaxInstanceCount > 0, f"MaxInstanceCount '{MaxInstanceCount}' hasn't been set for {this}, and won't work as intended!");

		if (ToManyInstances(EvaluationData, IndexesToRemove))
			return true;

		return false;
	}

	bool ShouldKill(const FHazeSoundDefInstanceEvaluationData& EvaluationData,
					const UHazeSoundDefBase SoundDef, const TArray<int>& IndexesToRemove, const int& Index) override
	{
		// If evaluating new sounddefs to be, add a offset.
		return ToManyInstances(EvaluationData, IndexesToRemove, EvaluationData.Class != nullptr ? 1 : 0);
	}
}
