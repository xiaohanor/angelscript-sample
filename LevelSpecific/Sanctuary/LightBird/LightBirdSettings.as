namespace LightBird
{
	namespace Tags
	{
		const FName LightBird = n"LightBird";

		const FName LightBirdAim = n"LightBirdAim";
		const FName LightBirdFire = n"LightBirdFire";

		const FName LightBirdRelease = n"LightBirdRelease";
		const FName LightBirdLaunch = n"LightBirdLaunch";
		const FName LightBirdRecall = n"LightBirdRecall";
		const FName LightBirdHover = n"LightBirdHover";
		const FName LightBirdLantern = n"LightBirdLantern";
		const FName LightBirdPlacementValidation = n"LightBirdPlacementValidation";

		const FName LightBirdIlluminate = n"LightBirdIlluminate";

		const FName LightBirdActiveDuringIntro = n"LightBirdActiveDuringIntro";
		const FName LightBirdInvestigate = n"LightBirdInvestigate";
	}

	namespace Absorb
	{
		const FName AttachSocket = n"Backpack";
	}

	namespace Aim
	{
		// Maximum distance we can trace and consequently move when released.
		const float Range = 1500.0;

		// True if we can attach to any blocking surface. If false, we can only attach to specific targetables.
		const bool bCanAttachToSurfaces = false;
	}

	namespace Release
	{
		// Time spent in the release state.
		const float Duration = 0.3;
		// Offset we move towards locally from the attachment socket when releasing.
		const FVector ReleaseOffset = FVector(-150.0, 100.0, 150.0);
	}

	namespace Launch
	{
		const float Acceleration = 20000.0;
		const float Drag = 0.0;
		const float MaximumSpeed = 4000.0;
		const float Delay = 0.02;
	}

	namespace Recall
	{
		const float Acceleration = 7500.0;
		const float Drag = 0.0;
		const float MaximumSpeed = 25000.0;
	}

	namespace Illumination
	{
		// Whether we can illuminate whilst flying.
		const bool bUseWhileFlying = false;

		// Maximum distance to actors when querying response components.
		const float Radius = 1000.0;
		// Duration until we're fully charged while illuminating, affects growth of the response component grab radius.
		const float ChargeDuration = 0.6;
	}
}