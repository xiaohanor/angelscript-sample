class UDentistToothBounceSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Bounce")
	float Restitution = 0.7;

	UPROPERTY(Category = "Bounce")
	float MaxVerticalImpulse = 700;

	UPROPERTY(Category = "Bounce")
	float MinimumFallingSpeedToBounce = 300;
};

namespace Dentist::Tags
{
	const FName BlockedWhileInBounce = n"BlockedWhileInBounce";
};