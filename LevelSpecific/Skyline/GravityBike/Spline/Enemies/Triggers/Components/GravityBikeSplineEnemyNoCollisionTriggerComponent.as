UCLASS(NotBlueprintable)
class UGravityBikeSplineEnemyNoCollisionTriggerComponent : UGravityBikeSplineEnemyTriggerComponent
{
	default StartColor = ColorDebug::Mauve;
	default EndColor = ColorDebug::Brown;

	default bUseEndExtent = true;
	default EndExtent = 5000;

	void OnEnemyEnter(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		auto MoveComp = UHazeMovementComponent::Get(TriggerUserComp.Owner);
		if(MoveComp == nullptr)
			return;

		MoveComp.ShapeComponent.AddComponentCollisionBlocker(this);
	}

	void OnEnemyExit(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		auto MoveComp = UHazeMovementComponent::Get(TriggerUserComp.Owner);
		if(MoveComp == nullptr)
			return;
		
		MoveComp.ShapeComponent.RemoveComponentCollisionBlocker(this);
	}
};