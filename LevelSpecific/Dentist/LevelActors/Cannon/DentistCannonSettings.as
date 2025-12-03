enum EDentistCannonAimMode
{
	Automatic,
	Manual,
};

enum EDentistCannonLaunchTrigger
{
	OnInput,
	AfterDelay,
};

namespace Dentist::Cannon
{
	const float SpringDropSpeed = 500;

	const EDentistCannonAimMode AimMode = EDentistCannonAimMode::Automatic;
	const EDentistCannonLaunchTrigger LaunchTrigger = EDentistCannonLaunchTrigger::AfterDelay;

	const FName DentistCannonBlockExclusionTag = n"DentistCannonBlockExclusion";
};