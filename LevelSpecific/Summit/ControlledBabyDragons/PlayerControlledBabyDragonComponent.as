
class UPlayerControlledBabyDragonComponent : UActorComponent
{
	UPROPERTY()
	USkeletalMesh BabyDragonMesh;
	UPROPERTY()
	FVector MeshScale = FVector::OneVector;
	UPROPERTY()
	FVector MeshOffset = FVector(-20.0, 0.0, 0.0);
	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettings;
};