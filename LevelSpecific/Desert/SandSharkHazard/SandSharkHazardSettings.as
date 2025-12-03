namespace SandSharkHazard
{
	const float SandDetectionDistance = 10;
	//delay before "onsand" is registered
	const float SandHitDelay = 0.3;
	const float SharkSpawnCooldown = 1;

	namespace Shark
	{
		const float SpawnDepth = 1000;
		const float AttackHeight = 400;
		const float TimeToKillPlayer = 0.5;
		const float LifeTime = 1;
	}
	
	namespace Tags
	{
		const FName SandSharkHazard = n"SandSharkHazard";
		const FName SandSharkHazardAttack = n"SandSharkHazardAttack";
	}
}
