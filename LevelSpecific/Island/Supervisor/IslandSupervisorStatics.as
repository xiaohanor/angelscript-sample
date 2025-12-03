namespace IslandSupervisor
{
	UFUNCTION()
	void IslandSupervisorSetPersistentMood(EIslandSupervisorMood Mood)
	{
		auto Manager = UIslandSupervisorManagerComponent::GetOrCreate(Game::Mio);
		Manager.SetPersistentMood(Mood);
	}

	UFUNCTION()
	void IslandSupervisorResetMood()
	{
		auto Manager = UIslandSupervisorManagerComponent::GetOrCreate(Game::Mio);
		Manager.ResetMood();
	}

	UFUNCTION()
	void IslandSupervisorEnqueueMood(EIslandSupervisorMood Mood, float Duration)
	{
		auto Manager = UIslandSupervisorManagerComponent::GetOrCreate(Game::Mio);
		Manager.EnqueueMood(Mood, Duration);
	}

	UFUNCTION()
	void IslandSupervisorActivateForDuration(float Duration)
	{
		auto Manager = UIslandSupervisorManagerComponent::GetOrCreate(Game::Mio);
		Manager.ActivateForDuration(Duration);
	}

	UFUNCTION()
	void IslandSupervisorActivate(FInstigator Instigator)
	{
		auto Manager = UIslandSupervisorManagerComponent::GetOrCreate(Game::Mio);
		Manager.Activate(Instigator);
	}

	UFUNCTION()
	void IslandSupervisorDeactivate(FInstigator Instigator)
	{
		auto Manager = UIslandSupervisorManagerComponent::GetOrCreate(Game::Mio);
		Manager.Deactivate(Instigator);
	}
}