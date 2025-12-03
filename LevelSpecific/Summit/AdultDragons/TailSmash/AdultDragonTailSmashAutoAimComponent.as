class UAdultDragonTailSmashAutoAimComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"Smash";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;
	default AutoAimMaxAngle = 60.0;
	default MaximumDistance = AdultDragonTailSmash::AutoAimMaxDistance;
	default TargetShape.Type = EHazeShapeType::Sphere;
	default TargetShape.SphereRadius = 1000.0;
}