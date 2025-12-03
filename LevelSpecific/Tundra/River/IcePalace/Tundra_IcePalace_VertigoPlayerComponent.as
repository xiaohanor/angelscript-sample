class UTundra_IcePalace_VertigoPlayerComponent : UActorComponent
{
	TArray<ATundra_IcePalace_VertigoCameraPoint> VertigoCameraPoints;
	TArray<float> Distances;
	AHazeLevelSequenceActor VertigoSeq;
	bool bCapabilityActive = false;
	TSubclassOf<UCameraShakeBase> VertigoCameraShake;
};