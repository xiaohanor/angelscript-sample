struct FFlowerInstanceDataPerComponent
{
	TArray<FFlowerInstanceData> InstanceDatas;
}

struct FFlowerPooledInstancesPerComponent
{
	TArray<int> PooledInstanceIndices;

	FFlowerPooledInstancesPerComponent()
	{
		PooledInstanceIndices.Reserve(500);
	}
}

struct FFlowerInstanceData
{
	FTransform Transform;
	float DeathTime;
	bool bIsWithering = false;
	bool bIsPooled = false;
	float CurrentSizeMultiplier = 0;
	float TargetScale = 0;
	float CurrentEmissive = 0;
	float TargetEmissive = 0;

	FFlowerInstanceData(FTransform InTransform, bool bSuccesfulPlacement)
	{
		Transform = InTransform;
		DeathTime = bSuccesfulPlacement ? MAX_flt : Time::GameTimeSeconds + FlowerPuzzle::FlowerUnhealthyLifeTime;
		bIsWithering = !bSuccesfulPlacement;
	}
}