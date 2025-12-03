UCLASS(Abstract)
class USkylineTorDebrisEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpactHit(FSkylineTorDebrisOnImpactHitEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeflected(FSkylineTorDebrisOnDeflectEventData Data) {}
}

struct FSkylineTorDebrisOnImpactHitEventData
{
	UPROPERTY()
	FHitResult HitResult;

	FSkylineTorDebrisOnImpactHitEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}

struct FSkylineTorDebrisOnDeflectEventData
{
	UPROPERTY()
	AHazeActor DeflectingActor;

	FSkylineTorDebrisOnDeflectEventData(AHazeActor InDeflectingActor)
	{
		DeflectingActor = InDeflectingActor;
	}
}
