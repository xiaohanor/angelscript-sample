class UClimbSandFishStartSteeringCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AVortexSandFish SandFish;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandFish = Cast<AVortexSandFish>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		switch(Desert::GetDesertLevelState())
		{
			case EDesertLevelState::Climb:
			{
				if(!ClimbSandFish::AreBothPlayersInteracting())
					return false;

				return true;
			}

			default:
				return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Desert::SetDesertLevelState(EDesertLevelState::Steer);
	}
};