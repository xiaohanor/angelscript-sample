class UDarkProjectileTargetComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"DarkProjectile";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;
	default MaximumDistance = DarkProjectile::AimRange;
}