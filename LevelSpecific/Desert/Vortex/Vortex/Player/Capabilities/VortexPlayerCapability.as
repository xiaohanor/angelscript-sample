class UVortexPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsInVortex())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsInVortex())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(DesertSlopeSlide::Tags::DesertSlopeSlide, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(DesertSlopeSlide::Tags::DesertSlopeSlide, this);
	}

	bool IsInVortex() const
	{
		switch(Desert::GetDesertLevelState())
		{
			case EDesertLevelState::None:
				return false;

			case EDesertLevelState::Vortex:
				return true;
			
			case EDesertLevelState::Climb:
				return true;

			case EDesertLevelState::Steer:
				return true;

			case EDesertLevelState::Fall:
				return true;

		}
	}
};