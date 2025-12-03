class UClimbSandFishFollowComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	TArray<AHazePlayerCharacter> PlayersOnBack;

	UFUNCTION(BlueprintPure)
	bool AreBothPlayersOnBack() const
	{
		return PlayersOnBack.Num() >= 2;
	}

	UFUNCTION(BlueprintPure)
	bool AreAnyPlayersOnBack() const
	{
		return PlayersOnBack.Num() > 0;
	}

	UFUNCTION(BlueprintPure)
	bool IsPlayerOnBack(AHazePlayerCharacter Player)
	{
		return PlayersOnBack.Contains(Player);
	}
};

namespace ClimbSandFish
{
	UClimbSandFishFollowComponent GetFollowComponent()
	{
		if(VortexSandFish::GetVortexSandFish() == nullptr)
			return nullptr;

		return UClimbSandFishFollowComponent::Get(VortexSandFish::GetVortexSandFish());
	}

	bool AreBothPlayersOnBack()
	{
		return GetFollowComponent().AreBothPlayersOnBack();
	}

	bool AreAnyPlayersOnBack()
	{
		return GetFollowComponent().AreAnyPlayersOnBack();
	}

	bool IsPlayerOnBack(AHazePlayerCharacter Player)
	{
		return GetFollowComponent().IsPlayerOnBack(Player);
	}
}