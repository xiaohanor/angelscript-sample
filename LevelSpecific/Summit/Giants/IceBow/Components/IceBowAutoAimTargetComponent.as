
class UIceBowAutoAimTargetComponent : UAutoAimTargetComponent
{
	default TargetableCategory = IceBow::TargetableCategory;
	default UsableByPlayers = IceBow::SelectPlayer;
	default AutoAimMaxAngle = 5.0;
	default MaximumDistance = IceBow::DefaultAutoAimDistance;
}
