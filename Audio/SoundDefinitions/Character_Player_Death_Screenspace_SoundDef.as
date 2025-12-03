
UCLASS(Abstract)
class UCharacter_Player_Death_Screenspace_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void RespawnStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnRespawnPulseMash(){}

	/* END OF AUTO-GENERATED CODE */

	UPlayerHealthComponent HealthComp;
	UPlayerHealthComponent OtherPlayerHealthComp;
	UPlayerRespawnComponent RespawnComp;

	// Sometimes you just gotta make it work.
	float LastRespawnTimer = 0;
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		HealthComp = UPlayerHealthComponent::Get(PlayerOwner);
		OtherPlayerHealthComp = UPlayerHealthComponent::Get(PlayerOwner.OtherPlayer);
		RespawnComp = UPlayerRespawnComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Respawn Progress"))
	float GetRespawnProgress()
	{
		if (HealthComp.HealthSettings.RespawnTimer == 0)
		{
			if (LastRespawnTimer != 0)
				return Math::Clamp(HealthComp.RespawnTimer, 0, LastRespawnTimer) / LastRespawnTimer;

			return Math::Clamp(HealthComp.RespawnTimer, 0, 1);
		}

		LastRespawnTimer = HealthComp.HealthSettings.RespawnTimer;
		return Math::Clamp(HealthComp.RespawnTimer, 0, LastRespawnTimer) / LastRespawnTimer;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "GameOver is possible"))
	bool CanGameOver()
	{
		return HealthComp.HealthSettings.bGameOverWhenBothPlayersDead;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "OtherPlayer Is Dead"))
	bool OtherPlayerIsDead()
	{
		return OtherPlayerHealthComp.bIsDead;
	}

}