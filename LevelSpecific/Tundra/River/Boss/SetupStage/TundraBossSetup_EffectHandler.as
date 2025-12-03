
UCLASS(Abstract)
class UTundraBossSetup_EffectHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	ATundraBossSetup IceKing;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		IceKing = Cast<ATundraBossSetup>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBossAppear()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBossDisappear()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashAttack(FTundraBossPhase01AttackEventData AttackVariation)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPounce()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreakIceFloor()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWait()
	{
	}

	UFUNCTION(BlueprintPure)
	ATundraBossSetup GetIceKing() const
	{
		return IceKing;
	}
};