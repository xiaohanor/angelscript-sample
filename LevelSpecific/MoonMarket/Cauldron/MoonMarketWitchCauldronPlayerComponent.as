UCLASS(Abstract)
class UMoonMarketWitchCauldronPlayerComponent : UActorComponent
{	
	UPROPERTY()
	UAnimSequence PickupAnim;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BoneFilter;

	UPROPERTY()
	UAnimSequence HoldAnim;
	
	UPROPERTY()
	FHazePlaySlotAnimationParams ThrowAnim;

	bool bThrowingIngredient = false;

	AMoonMarketWitchCauldron Cauldron;
	AMoonMarketCauldronIngredient HeldIngredient;

	void StartThrowingIngredientInCauldron(AMoonMarketWitchCauldron _Cauldron)
	{
		bThrowingIngredient = true;
		Cauldron = _Cauldron;
	}

	void ThrowIngredient()
	{
		Cauldron.NetAddIngredient(HeldIngredient);
	}
};