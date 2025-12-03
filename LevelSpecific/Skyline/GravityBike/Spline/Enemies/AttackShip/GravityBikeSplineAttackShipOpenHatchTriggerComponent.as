UCLASS(NotBlueprintable)
class UGravityBikeSplineAttackShipOpenHatchTriggerComponent : UGravityBikeSplineEnemyTriggerComponent
{
	default StartColor = FLinearColor::Red;
	default EndColor = FLinearColor::Yellow;
	default bUseEndExtent = true;
	default EndExtent = 10000;

	void OnEnemyEnter(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		auto AttackShip = Cast<AGravityBikeSplineAttackShip>(TriggerUserComp.Owner);
		if(AttackShip == nullptr)
			return;

		AttackShip.OpenHatchInstigators.Add(this);
	}
	
	void OnEnemyExit(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		auto AttackShip = Cast<AGravityBikeSplineAttackShip>(TriggerUserComp.Owner);
		if(AttackShip == nullptr)
			return;

		AttackShip.OpenHatchInstigators.Remove(this);
	}
};