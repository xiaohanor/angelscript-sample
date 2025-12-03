struct FSanctuaryBossHydraAnimationData
{
	bool bIsIdling = false;

	bool bIsEnteringSmash = false;
	bool bIsTelegraphingSmash = false;
	bool bIsSmashing = false;
	bool bIsSmashRecovering = false;
	bool bIsSmashReturning = false;

	bool bIsEnteringFireBreath = false;
	bool bIsTelegraphingFireBreath = false;
	bool bIsFireBreathing = false;
	bool bIsFireBreathRecovering = false;
	bool bIsFireBreathReturning = false;

	ESanctuaryHydraBossPhase Phase = ESanctuaryHydraBossPhase::Traversal;

	bool bDecapitated = false;

	FString ToString() const
	{
		return f"Idling: {bIsIdling}\n" + 
			f"Smash: Enter={bIsEnteringSmash}, Telegraph={bIsTelegraphingSmash}, Attack={bIsSmashing}, Recover={bIsSmashRecovering}, Return={bIsSmashReturning}\n" +
			f"FireBreath: Enter={bIsEnteringFireBreath}, Telegraph={bIsTelegraphingFireBreath}, Attack={bIsFireBreathing}, Recover={bIsFireBreathRecovering}, Return={bIsFireBreathReturning}\n" +
			f"Decapitated: {bDecapitated}";
	}
}