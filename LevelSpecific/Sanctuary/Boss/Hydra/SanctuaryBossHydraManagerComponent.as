namespace Hydra
{
	USanctuaryBossHydraManagerComponent GetHydraManager()
	{
		return USanctuaryBossHydraManagerComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION()
	ASanctuaryBossHydraBase GetHydraBase()
	{
		auto Manager = GetHydraManager();
		return Manager.Base;
	}

	UFUNCTION()
	void SetHydraBase(ASanctuaryBossHydraBase InBase)
	{
		auto Manager = GetHydraManager();
		Manager.Base = InBase;
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetAudioTetherPlayerOwner()
	{
		return Game::Mio;
	}

}

class USanctuaryBossHydraManagerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	ASanctuaryBossHydraBase Base;
}