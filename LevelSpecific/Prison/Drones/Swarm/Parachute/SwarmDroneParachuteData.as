struct FSwarmDroneParachuteInfo
{
	UPROPERTY()
	UMaterialInterface RopeMaterial;

	// Regular parachute movement
	UPROPERTY(Category = "Camera")
	TSubclassOf<UCameraShakeBase> MovementCameraShake;

	// When hovering inside drafts
	UPROPERTY(Category = "Camera")
	TSubclassOf<UCameraShakeBase> DraftCameraShake;
}