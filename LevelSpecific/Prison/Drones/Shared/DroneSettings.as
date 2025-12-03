namespace Drone
{
	const float CutsceneDroneScale = 0.5;

	AHazePlayerCharacter GetSwarmDronePlayer() property
	{
		return Game::Mio;
	}

	AHazePlayerCharacter GetMagnetDronePlayer() property
	{
		return Game::Zoe;
	}
}