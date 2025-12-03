UCLASS(NotBlueprintable, HideCategories = "Debug Rendering Activation Cooking Tags LOD Collision")
class UGravityBikeSplineEnemyBlockRespawnTriggerComponent : UGravityBikeSplineEnemyTriggerComponent
{
	default StartColor = ColorDebug::Black;
	default EndColor = ColorDebug::White;
	default bUseEndExtent = true;
	default EndExtent = 5000;

	void OnEnemyEnter(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		auto HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(TriggerUserComp.Owner);
		if(HealthComp == nullptr)
			return;

		HealthComp.BlockRespawnInstigators.Add(this);
	}

	void OnEnemyExit(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		auto HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(TriggerUserComp.Owner);
		if(HealthComp == nullptr)
			return;

		HealthComp.BlockRespawnInstigators.Remove(this);
	}
};