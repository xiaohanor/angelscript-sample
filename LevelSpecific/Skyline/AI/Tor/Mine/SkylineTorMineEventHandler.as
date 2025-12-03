UCLASS(Abstract)
class USkylineTorMineEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpactHit(FSkylineTorMineOnImpactHitEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeflected(FSkylineTorMineOnDeflectEventData Data) {}
}

struct FSkylineTorMineOnImpactHitEventData
{
	UPROPERTY()
	FHitResult HitResult;

	FSkylineTorMineOnImpactHitEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}

struct FSkylineTorMineOnDeflectEventData
{
	UPROPERTY()
	AHazeActor DeflectingActor;

	FSkylineTorMineOnDeflectEventData(AHazeActor InDeflectingActor)
	{
		DeflectingActor = InDeflectingActor;
	}
}
