event void FMoonMarketOnHonkedAt(AHazePlayerCharacter InstigatingPlayer);

class UMoonMarketTrumpetHonkResponseComponent : UActorComponent
{
	FMoonMarketOnHonkedAt OnHonkedAt;
};