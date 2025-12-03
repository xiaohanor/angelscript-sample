class USkylineBossTankCenterViewTargetComponent : UCenterViewTargetComponent
{
	ASkylineBossTank BossTank;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		BossTank = Cast<ASkylineBossTank>(Owner);
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		return true;
	}
};