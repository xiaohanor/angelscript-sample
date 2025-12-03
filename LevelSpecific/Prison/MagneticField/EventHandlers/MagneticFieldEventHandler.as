struct FMagneticFieldChargingData
{
	UPROPERTY()
	float ChargeAlpha = 0.0;
}

struct FMagneticFieldPushEventData
{
	UPROPERTY()
	TArray<FMagneticFieldPushEventDataEntry> Data;
}

struct FMagneticFieldPushEventDataEntry
{
	UPROPERTY()
	UMagneticFieldResponseComponent ResponseComp;

	UPROPERTY()
	FMagneticFieldData PushData;
}

class UMagneticFieldEventHandler : UHazeEffectEventHandler
{

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly)
	UMagneticFieldPlayerComponent MagneticFieldComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MagneticFieldComp = UMagneticFieldPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartedCharging() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Charging(FMagneticFieldChargingData ChargeData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishedCharging() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagneticBurst(FMagneticFieldPushEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagneticPush(FMagneticFieldPushEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartedMagneticallyAffecting(FMagneticFieldNearbyData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StoppedMagneticallyAffecting() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Stopped() {}
}