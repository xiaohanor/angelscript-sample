struct FGravityBikeSplineHoverSyncedData
{
	FVector RelativeLocation;
	FRotator RelativeRotation;
	float RollVelocity;
	float PitchVelocity;
};

UCLASS(NotBlueprintable)
class UGravityBikeSplineHoverSyncedDataComponent : UHazeCrumbSyncedStructComponent
{
	default SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	void InterpolateValues(FGravityBikeSplineHoverSyncedData& OutValue, FGravityBikeSplineHoverSyncedData A, FGravityBikeSplineHoverSyncedData B, float Alpha) const
	{
		OutValue.RelativeLocation = Math::Lerp(A.RelativeLocation, B.RelativeLocation, Alpha);
		OutValue.RelativeRotation = Math::LerpShortestPath(A.RelativeRotation, B.RelativeRotation, Alpha);
		OutValue.RollVelocity = Math::Lerp(A.RollVelocity, B.RollVelocity, Alpha);
		OutValue.PitchVelocity = Math::Lerp(A.PitchVelocity, B.PitchVelocity, Alpha);
	}
};