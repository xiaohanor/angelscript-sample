UCLASS(NotBlueprintable)
class UGravityBikeSplineAttackShipFacePlayerTriggerComponent : UGravityBikeSplineEnemyTriggerComponent
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

		AttackShip.bFacePlayer.Apply(true, this);
		UGravityBikeSplineAttackShipEventHandler::Trigger_OnFacePlayer(AttackShip);
	}
	
	void OnEnemyExit(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		auto AttackShip = Cast<AGravityBikeSplineAttackShip>(TriggerUserComp.Owner);
		if(AttackShip == nullptr)
			return;

		AttackShip.bFacePlayer.Clear(this);
		UGravityBikeSplineAttackShipEventHandler::Trigger_OnFaceForward(AttackShip);
	}
};