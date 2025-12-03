class USketchbookDuckBossChildCapability : USketchbookBossChildCapability
{
	USketchbookDuckBossComponent DuckComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DuckComp = USketchbookDuckBossComponent::Get(Owner);
	}
};