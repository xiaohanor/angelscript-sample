UCLASS(Abstract)
class USkylineTorBoloEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSkylineTorBoloEventHandlerOnImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDamage(FSkylineTorBoloEventHandlerOnDamageData Data) {}
}

struct FSkylineTorBoloEventHandlerOnImpactData
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	bool bIsGreenMesh = false;

	FSkylineTorBoloEventHandlerOnImpactData(FVector _Location, bool _bIsGreenMesh)
	{
		Location = _Location;
		bIsGreenMesh = _bIsGreenMesh;
	}
}

struct FSkylineTorBoloEventHandlerOnDamageData
{
	UPROPERTY()
	AHazePlayerCharacter Target;

	FSkylineTorBoloEventHandlerOnDamageData(AHazePlayerCharacter _Target)
	{
		Target = _Target;
	}
}