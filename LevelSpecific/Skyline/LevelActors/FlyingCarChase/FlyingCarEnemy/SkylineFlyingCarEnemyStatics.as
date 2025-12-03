namespace SkylineFlyingCarEnemy
{
	AHazePlayerCharacter GetDriverPlayer()
	{
		return Game::Zoe;
	}

	AHazePlayerCharacter GetGunnerPlayer()
	{
		return Game::Mio;
	}

	float GetPlayerHealth()
	{
		auto HealthComp = USkylineFlyingCarHealthComponent::Get(GetPlayerFlyingCar());
		return HealthComp.GetCurrentHealth();
	}

	ASkylineFlyingCar GetPlayerFlyingCar()
	{
		USkylineFlyingCarPilotComponent FlyingCarPilotComp = USkylineFlyingCarPilotComponent::Get(GetDriverPlayer());
		return FlyingCarPilotComp.Car;
	}
}