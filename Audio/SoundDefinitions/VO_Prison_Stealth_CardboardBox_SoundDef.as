
UCLASS(Abstract)
class UVO_Prison_Stealth_CardboardBox_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnCardboardBoxEnter(){}

	UFUNCTION(BlueprintEvent)
	void OnCardboardBoxLeave(){}

	UFUNCTION(BlueprintEvent)
	void OnCardboardHit(){}

	UFUNCTION(BlueprintEvent)
	void OnCardboardDisappear(){}

	UFUNCTION(BlueprintEvent)
	void OnCardboardRespawn(){}

	/* END OF AUTO-GENERATED CODE */

	UPrisonStealthCardboardBoxPlayerComponent BoxComp;
	UPlayerHealthComponent HealthComp;

	UPROPERTY()
	APrisonStealthCardboardBox CardboardBox;

	UPROPERTY()
	bool bFirstLineCompleted = false;
	UPROPERTY()
	bool bQueueCardbordHit = false;

	UPROPERTY()
	bool bEvasionLineFinished = false;
	bool bTriggerdEvasionLine = false;

	UPROPERTY()
	bool bMiosResponseLineFinished = false;
	bool bTriggeredTraitorLine = false;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		auto Player = Game::Zoe;
		CardboardBox = Cast<APrisonStealthCardboardBox>(HazeOwner);
		BoxComp = UPrisonStealthCardboardBoxPlayerComponent::Get(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (!bFirstLineCompleted)
			return;

		CheckEvasionLine();
		CheckTraitorLine();
	}

	void CheckEvasionLine()
	{
		if (BoxComp == nullptr)
			return;

		if (!BoxComp.HasCardboardBox())
			return;

		if (!BoxComp.HasEvadedDetection())
			return;

		if (bTriggerdEvasionLine)
		{
			// Ignore and reset any evasions during the first line.
			BoxComp.OnEvadedDetection(false);
			return;
		}

		bTriggerdEvasionLine = true;
		OnEvasion();
	}
	
	// Either wait or trigger traitor line right away.
	void CheckTraitorLine()
	{
		if (bTriggeredTraitorLine)
			return;

		if (!bMiosResponseLineFinished)
			return;

		if (HealthComp.bIsDead || HealthComp.bIsRespawning)
			return;

		bTriggeredTraitorLine = true;
		OnRespawnedAfterMioCausedDeath();
	}

	UFUNCTION(BlueprintEvent)
	void OnEvasion() {}

	UFUNCTION(BlueprintEvent)
	void OnRespawnedAfterMioCausedDeath() {}
}