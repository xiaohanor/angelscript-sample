class ULightBeamTargetComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"LightBeam";
	default UsableByPlayers = EHazeSelectPlayer::Mio;
	default MaximumDistance = LightBeam::BeamLength;
}