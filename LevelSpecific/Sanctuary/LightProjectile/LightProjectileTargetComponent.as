class ULightProjectileTargetComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"LightProjectile";
	default UsableByPlayers = EHazeSelectPlayer::Mio;
	default MaximumDistance = LightProjectile::AimRange;
}

class ULightProjectileTargetComponent2D : UAutoAimTargetComponent
{
	default TargetableCategory = n"LightProjectile2D";
	default UsableByPlayers = EHazeSelectPlayer::Mio;
	default MaximumDistance = LightProjectile::AimRange;
}