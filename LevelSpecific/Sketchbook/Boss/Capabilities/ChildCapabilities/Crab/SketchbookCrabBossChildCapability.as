class USketchbookCrabBossChildCapability : USketchbookBossChildCapability
{
	USketchbookCrabBossComponent CrabComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CrabComp = USketchbookCrabBossComponent::Get(Owner);
	}
};