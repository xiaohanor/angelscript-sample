asset GravityBikeSplineBikeEnemyDropSheet of UHazeCapabilitySheet
{
	Components.Add(UGravityBikeSplineBikeEnemyDropComponent);
	Capabilities.Add(UGravityBikeSplineBikeEnemyDropCapability);
};

UCLASS(NotBlueprintable)
class UGravityBikeSplineBikeEnemyDropComponent : UActorComponent
{
	bool bIsDropping = false;
	AGravityBikeSplineAttackShip AttackShip;
};