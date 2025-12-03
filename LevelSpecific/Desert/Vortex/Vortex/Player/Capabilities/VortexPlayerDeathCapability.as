class UVortexPlayerDeathCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		switch(Desert::GetDesertLevelState())
		{
			case EDesertLevelState::None:
				return false;
				
			case EDesertLevelState::Vortex:
			{
				if(MoveComp.HasGroundContact())
				{
					auto Landscape = Cast<ALandscape>(MoveComp.GroundContact.Actor);
					if(Landscape != nullptr)
						return true;

					auto SandFish = Cast<AVortexSandFish>(MoveComp.GroundContact.Actor);
					if(SandFish != nullptr)
						return true;
				}

				if(MoveComp.HasWallContact())
				{
					auto SandFish = Cast<AVortexSandFish>(MoveComp.WallContact.Actor);
					if(SandFish != nullptr)
						return true;
				}

				if(MoveComp.HasCeilingContact())
				{
					auto SandFish = Cast<AVortexSandFish>(MoveComp.CeilingContact.Actor);
					if(SandFish != nullptr)
						return true;
				}

				break;
			}

			case EDesertLevelState::Climb:
			{
				auto SandFish = VortexSandFish::GetVortexSandFish();
				if(MoveComp.HasGroundContact())
				{
					if(MoveComp.GroundContact.Actor != SandFish)
						return true;
				}

				if(MoveComp.HasWallContact())
				{
					if(MoveComp.WallContact.Actor != SandFish)
						return true;
				}

				if(MoveComp.HasCeilingContact())
				{
					if(MoveComp.CeilingContact.Actor != SandFish)
						return true;
				}

				break;
			}

			case EDesertLevelState::Steer:
			{
				return false;
			}

			case EDesertLevelState::Fall:
			{
				return false;
			}
		}
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.KillPlayer();
	}
};