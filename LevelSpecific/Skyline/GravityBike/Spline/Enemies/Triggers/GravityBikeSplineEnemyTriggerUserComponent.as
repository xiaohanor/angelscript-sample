struct FGravityBikeSplineEnemyDistanceTriggerData
{
	UGravityBikeSplineEnemyTriggerComponent TriggerComp;
	bool bHasEntered = false;
    bool bHasExited = false;

	int opCmp(FGravityBikeSplineEnemyDistanceTriggerData Other) const
	{
		if(Other.TriggerComp > TriggerComp)
			return 1;
		else
			return -1;
	}
};

UCLASS(NotBlueprintable, HideCategories = "Activation Cooking Tags AssetUserData Navigation")
class UGravityBikeSplineEnemyTriggerUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	
	private UGravityBikeSplineEnemyMovementComponent SplineMoveComp;
	TArray<FGravityBikeSplineEnemyDistanceTriggerData> TriggerDistanceDatas;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineMoveComp = UGravityBikeSplineEnemyMovementComponent::Get(Owner);
		InitializeTriggers();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		auto TemporalLog = TEMPORAL_LOG(this);
		for(int i = 0; i < TriggerDistanceDatas.Num(); i++)
		{
			const FString Category = f"TriggerDistanceData [{i + 1}/{TriggerDistanceDatas.Num()}]";
			TemporalLog.Value(f"{Category};TriggerComp", TriggerDistanceDatas[i].TriggerComp);
			TemporalLog.Value(f"{Category};bHasEntered", TriggerDistanceDatas[i].bHasEntered);
			TemporalLog.Value(f"{Category};bHasExited", TriggerDistanceDatas[i].bHasExited);
		}
#endif
	}

	private void InitializeTriggers()
	{
		TArray<UGravityBikeSplineEnemyTriggerComponent> TriggerComponents;
		SplineMoveComp.GetSplineComp().Owner.GetComponentsByClass(TriggerComponents);

		for(auto& TriggerComp : TriggerComponents)
		{
			TriggerComp.Initialize();
			
			FGravityBikeSplineEnemyDistanceTriggerData FireDistanceData;
			FireDistanceData.TriggerComp = TriggerComp;
			// if(TriggerComp.GetStartDistance() < GetDistanceAlongSpline())
			// {
			// 	FireDistanceData.bHasEntered = true;

			// 	if(TriggerComp.bUseEndExtent)
			// 	{
			// 		if(TriggerComp.GetEndDistance() < GetDistanceAlongSpline())
			// 			FireDistanceData.bHasExited = true;
			// 	}
			// }

			TriggerDistanceDatas.Add(FireDistanceData);
		}

		TriggerDistanceDatas.Sort();
	}

	float GetDistanceAlongSpline() const
	{
		return SplineMoveComp.GetDistanceAlongSpline();
	}
};