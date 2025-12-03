class UMagnetDroneAttachToBoatSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Activation")
	float ConeHeight = 150;

	UPROPERTY(Category = "Activation")
	float ConeTopRadius = 200;

	UPROPERTY(Category = "Activation")
	float ConeBotRadius = 150;

	UPROPERTY(Category = "Movement")
	float Bounciness = 0.4;

	UPROPERTY(Category = "Jumping")
	bool bJumpRelativeToBoat = false;
};

namespace MagnetDroneTags
{
	const FName AttachToBoat = n"AttachToBoat";
	const FName AttachToBoatBlockExclusionTag = n"AttachToBoatBlockExclusion";
};