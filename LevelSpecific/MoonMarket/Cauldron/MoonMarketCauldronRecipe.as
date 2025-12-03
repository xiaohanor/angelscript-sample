enum EMoonMarketPotionID
{
	ThunderCloud,
	TrumpetHead,
	Polymorph,
	YarnBall,
	Mushroom,
	BallBlaster,

	MAX UMETA(Hidden)
}

class UMoonMarketCauldronRecipeDataAsset : UDataAsset
{
	UPROPERTY()
	TArray<EMoonMarketCauldronIngredient> Ingredients;
	
	UPROPERTY()
	UHazeCapabilitySheet Sheet;

	UPROPERTY()
	EMoonMarketPotionID PotionID;
}