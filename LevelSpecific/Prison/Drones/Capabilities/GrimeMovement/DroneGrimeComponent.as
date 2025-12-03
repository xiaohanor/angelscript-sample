UCLASS(Abstract)
class UDroneGrimeComponent : UActorComponent
{
	UPROPERTY()
	UPhysicalMaterial GrimeMat;

	UPROPERTY()
	UDroneMovementSettings MovementSettings;
};