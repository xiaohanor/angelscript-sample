struct FMoonMarketMushroomPeopleReaction
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter InstigatingPlayer;
	
	UPROPERTY(BlueprintReadOnly)
	FName ActionTag;
	
	UPROPERTY(BlueprintReadOnly)
	AMushroomPeople Mushroom;
	int Priority = 1;
}

struct FMoonMarketMushroomPeopleReactionFinished
{
	AMushroomPeople Mushroom;
}

namespace MushroomPeopleReactions
{
	const FName BigReaction = n"BigReaction";
	const FName JumpedOn = n"JumpedOn";
}