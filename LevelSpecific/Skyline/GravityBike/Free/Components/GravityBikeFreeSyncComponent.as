/**
 * IMPORTANT:
 * Remember to add these values to UGravityBikeFreeSyncComponent::InterpolateValues()!
 */
struct FGravityBikeFreeSyncData
{
	float Throttle;
};

UCLASS(NotBlueprintable)
class UGravityBikeFreeSyncComponent : UHazeCrumbSyncedStructComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = true;
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_LastDemotable;

	private AGravityBikeFree GravityBike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		GravityBike.Input.Initialize(this);
		FillFromLocal();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(GravityBike == nullptr)
			return;
		
		if(HasControl())
			FillFromLocal();
	}

	void FillFromLocal()
	{
		FGravityBikeFreeSyncData SyncData;
		SyncData.Throttle = GravityBike.Input.ControlThrottle;
		SetValue(SyncData);
	}

	FGravityBikeFreeSyncData GetValue() const
	{
		FGravityBikeFreeSyncData SyncData;
		GetCrumbValueStruct(SyncData);
		return SyncData;
	}

	void SetValue(const FGravityBikeFreeSyncData& NewValue)
	{
		SetCrumbValueStruct(NewValue);
	}

	void ResetInput()
	{
		FGravityBikeFreeSyncData SyncData = GetValue();
		SyncData.Throttle = 0;
		SetValue(SyncData);
	}

	void InterpolateValues(FGravityBikeFreeSyncData& OutValue, FGravityBikeFreeSyncData A, FGravityBikeFreeSyncData B, float64 Alpha) const
	{
		OutValue.Throttle = Math::Lerp(A.Throttle, B.Throttle, Alpha);
	}
};