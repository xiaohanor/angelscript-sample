// This is just a default implementation of sounddef limiting, using condition assets.
class USoundDefInstanceLimitingDataAsset : UHazeSoundDefInstanceLimitingDataAsset
{
	UPROPERTY(EditAnywhere)
	TArray<USoundDefInstanceLimitingCondition> Conditions;

	// DEFAULT IMPLEMENTATIONS

	bool AnyConditionFailed(const FHazeSoundDefInstanceEvaluationData& EvaluationData, UHazeSoundDefBase SoundDef, const TArray<int>& IndexesToRemove, const int& Index) const
	{
		switch(Behaviour)
		{
			case ESoundDefInstanceLimitingBehaviour::Disable:
			{
				if (SoundDef.GetActivationState() == ESoundDefActivationState::Active)
				{
					for (auto Condition : Conditions)
					{
						if (Condition.ShouldDeactivate(EvaluationData, SoundDef, IndexesToRemove, Index))
						{
							// If Active we want to add it to the index array on any fail
							// I.e deactivate it.
							return true;
						}
					}

					return false;
				}
				else
				{
					for (auto Condition : Conditions)
					{
						if (Condition.ShouldActivate(EvaluationData, SoundDef, IndexesToRemove, Index) == false)
						{
							// If disabled, we only want to add it to the array when all conditions are successful.
							return false;
						}
					}

					// Request for re-enabling.
					return true;
				}
			}
			case ESoundDefInstanceLimitingBehaviour::Kill:
			{
				if (SoundDef != nullptr)
				{
					// No point in evaluating SD already in the correct state.
					if (SoundDef.GetActivationState() == ESoundDefActivationState::Destroyed)
						return false;
				}

				for (auto Condition : Conditions)
				{
					if (Condition.ShouldKill(EvaluationData, SoundDef, IndexesToRemove, Index))
					{
						// If any condition fails, we kill it. Just like with ShouldDeactivate
						return true;
					}
				}
			}
			break;
		}

		return false;
	}

	bool EvaluateConditional(const FHazeSoundDefInstanceEvaluationData& EvaluationData, TArray<int>& IndexesToRemove, bool bShouldKill = false) const
	{
		for (int i=0; i < EvaluationData.Internal.SoundDefs.Num(); ++i)
		{
			if (AnyConditionFailed(EvaluationData, EvaluationData.Internal.SoundDefs[i], IndexesToRemove, i))
			{
				IndexesToRemove.Add(i);

				// One off when creating a SD
				if (bShouldKill) // I.e break
				{
					return true;
				}
			}
		}

		return IndexesToRemove.Num() > 0;
	}

	bool EvaluateNewest(const FHazeSoundDefInstanceEvaluationData& EvaluationData, TArray<int>& IndexesToRemove, bool bShouldKill = false) const
	{
		for (int i=EvaluationData.Internal.SoundDefs.Num()-1; i >= 0; --i)
		{
			if (AnyConditionFailed(EvaluationData, EvaluationData.Internal.SoundDefs[i], IndexesToRemove, i))
			{
				IndexesToRemove.Add(i);

				// One off when creating a SD
				if (bShouldKill) // I.e break
				{
					return true;
				}
			}
		}

		return IndexesToRemove.Num() > 0;
	}

	bool EvaluateOldest(const FHazeSoundDefInstanceEvaluationData& EvaluationData, TArray<int>& IndexesToRemove, bool bShouldKill = false) const
	{
		return EvaluateConditional(EvaluationData, IndexesToRemove, bShouldKill);
	}

	//~DEFAULT

	UFUNCTION(BlueprintOverride)
	bool ShouldActivateOrDeactivate(FHazeSoundDefInstanceEvaluationData EvaluationData, TArray<int>& IndexesToRemove) const
	{
		int ArrayNum = EvaluationData.Internal.SoundDefs.Num();
		if (ArrayNum == 0)
			return false;

		if (Behaviour == ESoundDefInstanceLimitingBehaviour::Disable ||
			LimitingType == ESoundDefInstanceLimitingType::Conditional )
		{
			return EvaluateConditional(EvaluationData, IndexesToRemove);
		}

		if (LimitingType == ESoundDefInstanceLimitingType::Newest)
			return EvaluateNewest(EvaluationData, IndexesToRemove);

		return EvaluateOldest(EvaluationData, IndexesToRemove);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDestroy(const FHazeSoundDefInstanceEvaluationData& EvaluationData, TArray<int>& IndexesToRemove) const
	{
		// We know we are searching for a sounddef to kill.
		// If zero indexes are returned the one to be created will be killed (not created)!

		// Newest means the object to be created.
		if (LimitingType == ESoundDefInstanceLimitingType::Newest)
		{
			for (auto Condition : Conditions)
			{
				if (Condition.ShouldKill(EvaluationData, nullptr, IndexesToRemove,-1))
				{
					return true;
				}
			}

			// Then the rest.
			return EvaluateNewest(EvaluationData, IndexesToRemove, true);
		}
		else 
		{
			// Oldest i.e existing ones first.
			if (EvaluateOldest(EvaluationData, IndexesToRemove, true))
				return true;
			
			// Now the one to be created.
			for (auto Condition : Conditions)
			{
				if (Condition.ShouldKill(EvaluationData, nullptr, IndexesToRemove, -1))
				{
					return true;
				}
			}

		}

		// Do nothing.
		return false;
	}
}