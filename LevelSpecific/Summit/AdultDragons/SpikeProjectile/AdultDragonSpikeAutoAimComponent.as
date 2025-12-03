class UAdultDragonSpikeAutoAimComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"Smash";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;
	default AutoAimMaxAngle = 22.0;
	default MaximumDistance = 20000;
	default TargetShape.Type = EHazeShapeType::Sphere;
	default TargetShape.SphereRadius = 250.0;
}