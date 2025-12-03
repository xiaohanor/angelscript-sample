UCLASS(Abstract)
class USkylineTorHammerBulletEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSkylineTorHammerBulletEventHandlerOnImpactData Data) {}
}

struct FSkylineTorHammerBulletEventHandlerOnImpactData
{
	UPROPERTY()
	AHazePlayerCharacter Target;

	FSkylineTorHammerBulletEventHandlerOnImpactData(AHazePlayerCharacter _Target)
	{
		Target = _Target;
	}
}