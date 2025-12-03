namespace StoneBeastHead
{
	namespace ShakeTelegraph
	{
		const float PitchAmplitude = 1.2;
		const float PitchFrequency = 1.5;

		const float YawAmplitude = 1.2;
		const float YawFrequency = 1.3;

		const float RollAmplitude = 1.8;
		const float RollFrequency = 1.4;
	}

	namespace Shake
	{
		const float Duration = 4.0;

		const float PitchAmplitude = -8.0;
		const float PitchFrequency = 0.3;

		const float YawAmplitude = -20;
		const float YawFrequency = 0.3;

		const float RollAmplitude = -25;
		const float RollFrequency = 0.5;
	}


	namespace FocusTarget
	{
		const FVector LocalOffset = FVector(0, 0, -50);
		const FVector ViewOffset = FVector(0, 0, 200);
		const float InterpMaxSpeed = 4;
		const float InterpMaxDistance = 500;
	}

	namespace Throw
	{
		const float Impulse = 10000;
		const float ActivateTime = 0.5;
		const float DeactivateTime = 1.5;
		const float TimeBeforeKillPlayers = 1;
	}

	const float RollAmount = 390;
	const float TelegraphRollAmount = -30;

	const FName DebugCategory = n"StoneBeastHead";

	namespace Tags
	{
		const FName StoneBeastHead = n"StoneBeastHead";
		const FName StoneBeastHeadRoll = n"StoneBeastHeadRoll";
		const FName StoneBeastHeadShake = n"StoneBeastHeadShake";
		const FName StoneBeastHeadShakeTelegraph = n"StoneBeastHeadShakeTelegraph";
		const FName StoneBeastHeadCameraFocusUpdater = n"StoneBeastHeadCameraFocusUpdater";
	}
}