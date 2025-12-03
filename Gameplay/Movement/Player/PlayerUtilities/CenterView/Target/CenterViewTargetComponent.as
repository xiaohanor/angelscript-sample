/**
 * Anything that should be a CenterView target can implement this.
 * Usually you want to create a child class and override CheckTargetable with custom conditions,
 * but if the actor you attach to already does Enable/Disable, then it could just work out of the box.
 */
UCLASS(NotBlueprintable, HideCategories = "Visuals Rendering Activation Cooking LOD AssetUserData Navigation")
class UCenterViewTargetComponent : UTargetableComponent
{
	default TargetableCategory = n"CenterView";

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		// Sort based on distance
		Targetable::ApplyDistanceToScore(Query);
		return true;
	}
};