struct FMoonMarketMoleReaction
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter InstigatingPlayer;
	
	UPROPERTY(BlueprintReadOnly)
	FName ActionTag;
	
	UPROPERTY(BlueprintReadOnly)
	AMoonMarketMole Mole;
	int Priority = 1;
}

struct FMoonMarketMoleReactionFinished
{
	AMoonMarketMole Mole;
}

namespace MoleReactions
{
	const FName Thunder = n"Thunder";
	const FName Firework = n"Firework";
	const FName Trumpet = n"Trumpet";
	const FName Candy = n"Candy";
	const FName RainReaction = n"Rain";
	const FName Polymorph = n"Polymorph";
	const FName Unmorph = n"Unmorph";
	const FName LostBalloon = n"LostBalloon";
	const FName GivenBalloon = n"GivenBalloon";
}