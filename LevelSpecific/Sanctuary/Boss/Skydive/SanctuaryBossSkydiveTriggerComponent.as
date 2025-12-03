event void FSanctuaryBossSkydiveTriggerComponentSignature();

class USanctuaryBossSkydiveTriggerComponent : UActorComponent
{
	UPROPERTY()
	FSanctuaryBossSkydiveTriggerComponentSignature OnTriggered;

	UFUNCTION()
	void Trigger()
	{
		OnTriggered.Broadcast();
	}
};