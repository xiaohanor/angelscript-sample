
UCLASS(Abstract)
class USoundDefInstanceLimitingCondition : UDataAsset
{
	// EvaluationData - Data on instance to be created, SoundDef - Existing instance

	// Use the same terminology as the rest of the game.
	bool ShouldActivate(const FHazeSoundDefInstanceEvaluationData& EvaluationData, const UHazeSoundDefBase SoundDef, const TArray<int>& IndexesToRemove, const int& Index) { return false; }
	bool ShouldDeactivate(const FHazeSoundDefInstanceEvaluationData& EvaluationData, const UHazeSoundDefBase SoundDef, const TArray<int>& IndexesToRemove, const int& Index) { return false; }
	bool ShouldKill(const FHazeSoundDefInstanceEvaluationData& EvaluationData, const UHazeSoundDefBase SoundDef, const TArray<int>& IndexesToRemove, const int& Index) { return false; }
}
