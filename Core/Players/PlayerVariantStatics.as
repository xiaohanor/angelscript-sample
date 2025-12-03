
/**
 * Override the variant of the player that is active at the moment.
 * This mainly affects the mesh that is displayed.
 */
UFUNCTION(Category = "Players | Variants")
mixin void ApplyPlayerVariantOverride(AHazePlayerCharacter Player, UHazePlayerVariantAsset Variant, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
{
	auto VariantComp = UPlayerVariantComponent::Get(Player);
	VariantComp.ApplyPlayerVariantOverride(Variant, Instigator, Priority);
}

/**
 * Clear a previously applied override for the player variant that is active.
 * This mainly affects the mesh that is displayed.
 */
UFUNCTION(Category = "Players | Variants")
mixin void ClearPlayerVariantOverride(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto VariantComp = UPlayerVariantComponent::Get(Player);
	VariantComp.ClearPlayerVariantOverride(Instigator);
}

/**
 * Get which overall player variant type is currently active (scifi, realworld, fantasy)
 */
UFUNCTION(Category = "Players | Variants")
mixin EHazePlayerVariantType GetActivePlayerVariantType(const AHazePlayerCharacter Player)
{
	auto VariantComp = UPlayerVariantComponent::Get(Player);
	return VariantComp.GetPlayerVariantType();
}