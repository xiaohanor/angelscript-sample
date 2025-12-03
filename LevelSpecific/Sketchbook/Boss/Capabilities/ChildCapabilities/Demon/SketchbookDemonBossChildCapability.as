class USketchbookDemonBossChildCapability : USketchbookBossChildCapability
{
	USketchbookDemonBossComponent DemonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DemonComp = USketchbookDemonBossComponent::Get(Owner);
	}
};