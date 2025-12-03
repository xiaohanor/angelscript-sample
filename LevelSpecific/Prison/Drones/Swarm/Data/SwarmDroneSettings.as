namespace SwarmDrone
{
	const float Radius = 37.5;
	const float SwarmBotScale = 1.4;

	const int TotalBotCount = 50;
	const int DeployedBotCount = 25;

	const int RetractedInnerLayerBotCount = 20;

	const int SwarmBotLeadCount = 4;

	namespace Movement
	{
		const float Speed = 530.0;
		const float HoverSpeed = 300.0;

		const float DragAirborne = 0.5;
		const float DragGrounded = 1.5;

		const float RotationSpeed = 14.0;

		const float HoverGravityMultiplier = 0.2;

		const float SwarmStickTogetherGroundMultiplier = 50.0;
	}

	namespace SwarmHack
	{
		const float Reach = 300.0;
	}

	namespace Hijack
	{
		const float Range = 300.0;
	}

	asset SwarmBotSheet of UHazeCapabilitySheet
	{
		AddCapability(n"DroneSwarmBotMovementCapability");
	};
}