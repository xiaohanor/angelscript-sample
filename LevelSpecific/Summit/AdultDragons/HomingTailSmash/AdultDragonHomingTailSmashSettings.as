namespace AdultDragonHomingTailSmash
{
	const float SpinChargeTime = 0.25;

	//if over this distance then the dragon will do a "fail" animation
	const float AutoAimMaxDistance = 18000;

	const int DefaultTickGroupOrder = 50;
	const float SpinRotationInterpSpeed = 10;

	namespace Tags
	{
		const FName AdultDragonTailSmash = n"AdultDragonTailSmash";
	}

	namespace Locomotion
	{
		const FName AirSmash = n"AdultDragonAirSmash";
		const FName DragonRiding = n"DragonRiding";
	}
}