

class USanctuaryBossMedallionHydraEmissiveFaceFadeOutCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	USanctuaryBossMedallionHydraEmissiveFaceComponent FaceComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FaceComp = USanctuaryBossMedallionHydraEmissiveFaceComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!FaceComp.ShouldHaveEmissiveFace())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!FaceComp.ShouldHaveEmissiveFace())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FaceComp.AccEmissiveFace.AccelerateTo(0.0, 1.0, DeltaTime);
		FaceComp.EmissiveFaceDynamicMaterial.SetVectorParameterValue(n"EmissiveTintMaw", FLinearColor::White * FaceComp.AccEmissiveFace.Value);
	}
};