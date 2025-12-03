
struct FSanctuaryBossMedallionHydraEmissiveFaceRequest
{
	FInstigator Requester;
	float Duration = 1.0;
}

class USanctuaryBossMedallionHydraEmissiveFaceCapability : UHazeCapability
{
	USanctuaryBossMedallionHydraEmissiveFaceComponent FaceComp;
	default TickGroup = EHazeTickGroup::Gameplay;

	FHazeAcceleratedFloat AccStartOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FaceComp = USanctuaryBossMedallionHydraEmissiveFaceComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (FaceComp.ShouldHaveEmissiveFace())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (FaceComp.ShouldHaveEmissiveFace())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccStartOffset.SnapTo(FaceComp.AccEmissiveFace.Value);
		// SanctuaryBossMedallionHydraFadeInEmissiveFaceCurve.GetTimeRange(MinTime, MaxTime);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
#if !RELEASE
		int i = 0;
		for (auto KeyVal : FaceComp.EmissiveFaceRequesters)
		{
			TEMPORAL_LOG(Owner, "Emissive Face").Value("Requester_" + i, KeyVal.Key);
			i++;
		}
#endif
		AccStartOffset.AccelerateTo(0.0, 0.5, DeltaTime);

		float AdditiveEmissiveFace = 0.0;
		for (auto Iterator : FaceComp.EmissiveFaceRequesters)
		{
			float TimeProgress = Time::GameTimeSeconds - Iterator.Value.GameStartTime;
			AdditiveEmissiveFace += Iterator.Value.Curve.GetFloatValue(TimeProgress);
		}

		FaceComp.AccEmissiveFace.SnapTo(AdditiveEmissiveFace + AccStartOffset.Value);
		FaceComp.EmissiveFaceDynamicMaterial.SetVectorParameterValue(n"EmissiveTintMaw", FLinearColor::White * FaceComp.AccEmissiveFace.Value);

		FaceComp.RemoveOutdatedEmissiveFaceRequests();
	}
};