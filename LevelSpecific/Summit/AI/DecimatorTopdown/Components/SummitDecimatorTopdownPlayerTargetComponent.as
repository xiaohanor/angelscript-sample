class USummitDecimatorTopdownPlayerTargetComponent : UActorComponent
{
	private AHazePlayerCharacter CurrentTarget;
	private AHazePlayerCharacter OtherPlayer;
	
	void Init()
	{
		CurrentTarget = Game::Zoe;
		OtherPlayer = Game::Mio;
	}
	
	AHazePlayerCharacter GetTarget() const property
	{
		return CurrentTarget;
	}

	void SwitchTarget()
	{
		AHazePlayerCharacter Temp = CurrentTarget;
		CurrentTarget = OtherPlayer;
		OtherPlayer = Temp;
	}

	bool IsTargetAlive(AHazeActor CheckTarget)
	{
		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(CheckTarget);
		if (HealthComp != nullptr)
			return !HealthComp.bIsDead;
		return false;
	}

};