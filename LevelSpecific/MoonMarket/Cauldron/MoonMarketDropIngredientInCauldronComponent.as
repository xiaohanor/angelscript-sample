class UMoonMarketDropIngredientInCauldronComponent : USceneComponent
{
	AMoonMarketWitchCauldron Cauldron;
	AMoonMarketCauldronIngredient CurrentIngredient;

	const float DropTime = 0.5;
	float FinishedTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cauldron = Cast<AMoonMarketWitchCauldron>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(CurrentIngredient == nullptr)
			return;

		if(Time::GameTimeSeconds >= FinishedTime)
		{
			ForceFeedback::PlayWorldForceFeedback(ForceFeedback::Default_Light, Cauldron.ActorLocation, true, this, Intensity = 0.7);
			Cauldron.OnIngredientDroppedInCauldron(CurrentIngredient);
			CurrentIngredient = nullptr;
		}
	}

	void StartDroppingIngredientIntoCauldron(AMoonMarketCauldronIngredient Ingredient)
	{
		FinishedTime = Time::GameTimeSeconds + DropTime;
		CurrentIngredient = Ingredient;
		Ingredient.DropInCauldron(Cauldron.ActorLocation + FVector::UpVector * 50);
	}
};