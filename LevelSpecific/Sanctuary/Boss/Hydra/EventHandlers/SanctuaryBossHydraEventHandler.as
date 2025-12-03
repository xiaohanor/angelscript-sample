UCLASS(Abstract)
class USanctuaryBossHydraEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Hydra")
	ASanctuaryBossHydraHead HydraHead;
	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Hydra")
	USanctuaryBossHydraSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraHead = Cast<ASanctuaryBossHydraHead>(Owner);
		Settings = USanctuaryBossHydraSettings::GetSettings(HydraHead);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmashAttack() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmashAttackTelegraphBegin() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmashAttackTelegraphEnd() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FireBreathBegin() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FireBreathEnd() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FireBreathTelegraphBegin() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FireBreathTelegraphEnd() { }

	UFUNCTION(BlueprintPure)
	FRotator GetMouthOffsetRotation() const property
	{
		return FRotator(Settings.MouthPitch, 0.0, 0.0);
	}

	UFUNCTION(BlueprintPure)
	FVector GetFireBreathStartLocation() const property
	{
		return HydraHead.FireBreathStartLocation;
	}

	UFUNCTION(BlueprintPure)
	FVector GetFireBreathEndLocation() const property
	{
		return HydraHead.FireBreathEndLocation;
	}
}