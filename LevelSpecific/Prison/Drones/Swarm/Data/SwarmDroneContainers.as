USTRUCT()
struct FSwarmDroneHackEventData
{
	UPROPERTY()
	UPlayerSwarmDroneComponent PlayerSwarmDroneComponent;
}

USTRUCT()
struct FSwarmDronePointLightSettings
{
	UPROPERTY(EditAnywhere)
	float BallIntensity = 1800;

	UPROPERTY(EditAnywhere)
	float BallAttenuationRadius = 300.0;


	UPROPERTY(EditAnywhere)
	float SwarmIntensity = 200;

	UPROPERTY(EditAnywhere)
	float SwarmAttenuationRadius = 200.0;


	UPROPERTY(EditAnywhere)
	FLinearColor Color = FLinearColor(0.92, 0.00, 1.00);
}