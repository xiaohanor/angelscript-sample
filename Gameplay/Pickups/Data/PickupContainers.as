USTRUCT()
struct FPickUpStartedParams
{
	UPROPERTY()
	UPickupComponent PickupComponent;
}

USTRUCT()
struct FPickedUpParams
{
	UPROPERTY()
	UPickupComponent PickupComponent;
}

USTRUCT()
struct FPutDownStartedParams
{
	
}

USTRUCT()
struct FPutDownParams
{
	UPROPERTY()
	UPickupComponent PickupComponent;
}

enum EPutdownType
{
	FreeFloor,
	PutdownInteraction
}

enum EPickupType
{
	Light,
	Heavy
}

enum EPickupTypeCompatibility
{
	Light,
	Heavy,
	Both
}

USTRUCT()
struct FPutdownSettings
{

}

USTRUCT()
struct FPickupSettings
{
	UPROPERTY()
	EPickupType PickupType = EPickupType::Light;

	// When, during the pickup animation, to attach the object to the player
	UPROPERTY()
	float PickupAttachTimeStamp = 0.2;

	UPROPERTY()
	bool bCanBePutDown = true;
}