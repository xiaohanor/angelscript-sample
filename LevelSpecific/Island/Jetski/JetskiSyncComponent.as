struct FJetskiSyncedData
{
	FJetskiInput Input;
};

UCLASS(NotBlueprintable)
class UJetskiSyncComponent : UHazeCrumbSyncedStructComponent
{
	default SyncRate = EHazeCrumbSyncRate::Standard;

	void InterpolateValues(FJetskiSyncedData& OutValue, FJetskiSyncedData A, FJetskiSyncedData B, float Alpha) const
	{
		OutValue.Input = FJetskiInput::Lerp(A.Input, B.Input, Alpha);
	}
};