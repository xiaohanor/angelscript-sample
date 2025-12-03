USTRUCT()
struct FCentipedeBiteEventParams
{
	UPROPERTY()
	UCentipedeBiteComponent CentipedeBiteComponent = nullptr;

	UPROPERTY()
	AHazePlayerCharacter Player = nullptr;
}

event void FOnCentipedeBiteStarted(FCentipedeBiteEventParams BiteParams);
event void FOnCentipedeBiteStopped(FCentipedeBiteEventParams BiteParams);

class UCentipedeBiteSettings : UHazeComposableSettings
{
	// Even if player releases bite action, this time needs to pass
	// before centipede actually releases mandible
	UPROPERTY()
	float MinimumBiteDuration = 0.2;
}