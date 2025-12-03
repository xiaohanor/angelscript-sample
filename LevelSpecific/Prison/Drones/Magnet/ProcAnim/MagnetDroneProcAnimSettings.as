namespace MagnetDrone
{
	namespace ShellSettings
	{
		const int ShellCount = 5;

		// Shells
		const float ShellAccelerateFactor = 300.0;
		const float ShellDragCoefficient = 0.001;
		const float ShellMinimumSpeedFactor = 100.0;

		// Slices Settings
		const float SpeedMultiplier = 1500.0;
		const float UpMultiplier = 0.7;
		const float ForwardMultiplier = 0.0;
		const float MoveOutDist = 10.0;

		const bool bUseSine = true;
		const float SinOffset = 0.1;
		const float SinFrequency = 3.0;
		const float SinIntensity = 5.0;
		const float SinSharpness = 20.0;

		const float AccDuration = 0.1;

		// Jumping
		const float JumpAnimSpeed = 1;
	}

	namespace CapSettings
	{
		const int CapCount = 2;

		const float MoveOutDuration = 0.5;
		const float MoveInDuration = 0.2;
		const float MoveOutAmount = 10.0;
	}
}