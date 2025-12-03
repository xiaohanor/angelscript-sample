
struct FSanctuaryBossMedallionHydraEmissiveFaceData
{
	UCurveFloat Curve;
	float GameStartTime;
	float GameEndTime;
}

class USanctuaryBossMedallionHydraEmissiveFaceComponent : UActorComponent
{
	access CapabilityAccess = private, USanctuaryBossMedallionHydraEmissiveFaceFadeOutCapability, USanctuaryBossMedallionHydraEmissiveFaceCapability, ASanctuaryBossMedallionHydra;

	access : CapabilityAccess TMap<FInstigator, FSanctuaryBossMedallionHydraEmissiveFaceData> EmissiveFaceRequesters;
	access : CapabilityAccess UMaterialInstanceDynamic EmissiveFaceDynamicMaterial = nullptr;
	access : CapabilityAccess FHazeAcceleratedFloat AccEmissiveFace;

	private ASanctuaryBossMedallionHydra Hydra;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Hydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
		SetupEmissiveFaceMaterial();
	}

	private void SetupEmissiveFaceMaterial()
	{
		if (Hydra.SkeletalMesh.NumMaterials == 0)
			return;
		EmissiveFaceDynamicMaterial = Material::CreateDynamicMaterialInstance(this, Hydra.SkeletalMesh.GetMaterial(0));
		Hydra.SkeletalMesh.SetMaterial(0, EmissiveFaceDynamicMaterial);
		EmissiveFaceDynamicMaterial.SetVectorParameterValue(n"EmissiveTintMaw", FLinearColor::White * SanctuaryBossMedallionHydraEmissiveFaceCurve_LaunchProjectileSingle.GetFloatValue(0.0));
	}

	void RequestEmissiveFace(FInstigator Requester, UCurveFloat Curve)
	{
		float32 Start = 0.0;
		float32 Duration = 0.0;
		Curve.GetTimeRange(Start, Duration);
		if (EmissiveFaceRequesters.Contains(Requester))
		{
			EmissiveFaceRequesters[Requester].Curve = Curve;
			EmissiveFaceRequesters[Requester].GameStartTime = Time::GameTimeSeconds;
			EmissiveFaceRequesters[Requester].GameEndTime = Time::GameTimeSeconds + Duration;
		}
		else
		{
			FSanctuaryBossMedallionHydraEmissiveFaceData Data;
			Data.GameStartTime = Time::GameTimeSeconds;
			Data.GameEndTime = Time::GameTimeSeconds + Duration;
			Data.Curve = Curve;
			EmissiveFaceRequesters.Add(Requester, Data);
		}
	}

	void RemoveEmissiveFaceByInstigator(FInstigator Requester)
	{
		if (EmissiveFaceRequesters.Contains(Requester))
			EmissiveFaceRequesters.Remove(Requester);
	}

	void RemoveOutdatedEmissiveFaceRequests()
	{
		TArray<FInstigator> ToRemove;
		for (auto Iterator : EmissiveFaceRequesters)
		{
			if (Iterator.Value.GameEndTime <= Time::GameTimeSeconds)
				ToRemove.Add(Iterator.Key);
		}
		for (auto Instigator : ToRemove)
			EmissiveFaceRequesters.Remove(Instigator);
	}

	bool ShouldHaveEmissiveFace() const
	{
		if (!EmissiveFaceRequesters.IsEmpty())
			return true;
		// if (AnimationComponent.GetFeatureTag() == EFeatureTagMedallionHydra::ProjectileSingle)
		// 	return true;
		// if (AnimationComponent.GetFeatureTag() == EFeatureTagMedallionHydra::ProjectileTripple)
		// 	return true;
		// if (AnimationComponent.GetFeatureTag() == EFeatureTagMedallionHydra::RainAttack)
		// 	return true;
		return false;
	}
};