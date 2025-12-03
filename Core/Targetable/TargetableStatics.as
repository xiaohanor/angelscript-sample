UFUNCTION(Category = "Targetables")
mixin EPlayerTargetingMode GetCurrentTargetingMode(AHazePlayerCharacter Player)
{
	auto TargetablesComp = UPlayerTargetablesComponent::Get(Player);
	return TargetablesComp.TargetingMode.Get();
}